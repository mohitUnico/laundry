const prisma = require('../config/database');
const logger = require('../utils/logger');
const { NotFoundError, ValidationError, AppError } = require('../utils/errors');
const { getSupabaseClient } = require('../config/supabase');
const { v4: uuidv4 } = require('uuid');

const UUID_REGEX =
    /^[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i;

const assertUuid = (value, fieldName) => {
    if (!value || typeof value !== 'string' || !UUID_REGEX.test(value)) {
        throw new ValidationError(`${fieldName} must be a valid UUID`);
    }
};

const ensureCustomerExists = async (tx, customerId) => {
    assertUuid(customerId, 'customerId');

    const customer = await tx.customer.findUnique({
        where: { customer_id: customerId },
        select: { customer_id: true },
    });

    if (!customer) {
        throw new NotFoundError('Customer');
    }
};

exports.createCustomerAddress = async (customerId, payload) => {
    const { address_label, full_address, latitude, longitude, is_default, delivery_note } = payload;

    return prisma.$transaction(async (tx) => {
        await ensureCustomerExists(tx, customerId);

        if (typeof is_default === 'boolean' && is_default) {
            await tx.customerAddress.updateMany({
                where: { customer_id: customerId },
                data: { is_default: false },
            });
        }

        const created = await tx.customerAddress.create({
            data: {
                customer_id: customerId,
                address_label,
                full_address,
                latitude,
                longitude,
                is_default: typeof is_default === 'boolean' ? is_default : false,
                delivery_note: delivery_note ?? null,
            },
        });

        logger.info('Customer address created', {
            customerId,
            addressId: created.address_id,
            isDefault: created.is_default,
        });

        return created;
    });
};

exports.getCustomerAddresses = async (customerId) => {
    assertUuid(customerId, 'customerId');

    // If customer is deleted but token still exists, be explicit.
    const customer = await prisma.customer.findUnique({
        where: { customer_id: customerId },
        select: { customer_id: true },
    });
    if (!customer) {
        throw new NotFoundError('Customer');
    }

    return prisma.customerAddress.findMany({
        where: { customer_id: customerId },
        orderBy: [{ is_default: 'desc' }, { updated_at: 'desc' }],
    });
};

exports.getCustomerAddressById = async (customerId, addressId) => {
    assertUuid(customerId, 'customerId');
    assertUuid(addressId, 'addressId');

    const address = await prisma.customerAddress.findFirst({
        where: { address_id: addressId, customer_id: customerId },
    });

    if (!address) {
        throw new NotFoundError('Address');
    }

    return address;
};

exports.updateCustomerAddress = async (customerId, addressId, payload) => {
    assertUuid(customerId, 'customerId');
    assertUuid(addressId, 'addressId');

    const { address_label, full_address, latitude, longitude, is_default, delivery_note } = payload;

    return prisma.$transaction(async (tx) => {
        await ensureCustomerExists(tx, customerId);

        const existing = await tx.customerAddress.findFirst({
            where: { address_id: addressId, customer_id: customerId },
        });

        if (!existing) {
            throw new NotFoundError('Address');
        }

        if (typeof is_default === 'boolean' && is_default) {
            await tx.customerAddress.updateMany({
                where: { customer_id: customerId },
                data: { is_default: false },
            });
        }

        const updated = await tx.customerAddress.update({
            where: { address_id: addressId },
            data: {
                ...(typeof address_label === 'string' ? { address_label } : {}),
                ...(typeof full_address === 'string' ? { full_address } : {}),
                ...(typeof latitude === 'number' ? { latitude } : {}),
                ...(typeof longitude === 'number' ? { longitude } : {}),
                ...(typeof is_default === 'boolean' ? { is_default } : {}),
                ...(typeof delivery_note === 'string' ? { delivery_note } : delivery_note === null ? { delivery_note: null } : {}),
            },
        });

        logger.info('Customer address updated', {
            customerId,
            addressId,
            isDefault: updated.is_default,
        });

        return updated;
    });
};

exports.deleteCustomerAddress = async (customerId, addressId) => {
    assertUuid(customerId, 'customerId');
    assertUuid(addressId, 'addressId');

    return prisma.$transaction(async (tx) => {
        await ensureCustomerExists(tx, customerId);

        const result = await tx.customerAddress.deleteMany({
            where: { address_id: addressId, customer_id: customerId },
        });

        if (result.count === 0) {
            throw new NotFoundError('Address');
        }

        logger.info('Customer address deleted', { customerId, addressId });

        return { deleted: true };
    });
};

exports.updateCustomerProfileImageUrl = async (customerId, payload) => {
    assertUuid(customerId, 'customerId');

    const profileImageUrl =
        payload?.profile_image_url !== undefined ? payload.profile_image_url : payload?.profileImageUrl;

    if (profileImageUrl !== null && typeof profileImageUrl !== 'string') {
        throw new ValidationError('profileImageUrl must be a valid URL or null');
    }

    return prisma.$transaction(async (tx) => {
        await ensureCustomerExists(tx, customerId);

        const updated = await tx.customer.update({
            where: { customer_id: customerId },
            data: {
                profile_image_url: profileImageUrl,
            },
            select: {
                customer_id: true,
                full_name: true,
                email: true,
                phone: true,
                profile_image_url: true,
                updated_at: true,
            },
        });

        logger.info('Customer profile image url updated', {
            customerId,
            hasUrl: Boolean(updated.profile_image_url),
        });

        return updated;
    });
};

exports.uploadCustomerProfileImage = async (customerId, file) => {
    assertUuid(customerId, 'customerId');

    if (!file) {
        throw new ValidationError('Image file is required');
    }

    const allowedMimeTypes = new Set(['image/jpeg', 'image/png', 'image/webp']);
    if (!allowedMimeTypes.has(file.mimetype)) {
        throw new ValidationError('Only JPEG, PNG, or WEBP images are allowed');
    }

    // Default bucket for customer profile images.
    // Can be overridden via SUPABASE_CUSTOMER_PROFILE_BUCKET env var.
    const bucket = process.env.SUPABASE_CUSTOMER_PROFILE_BUCKET || 'customer-info';
    const ext = file.mimetype === 'image/jpeg' ? 'jpg' : file.mimetype === 'image/png' ? 'png' : 'webp';
    const objectPath = `customers/${customerId}/${uuidv4()}.${ext}`;

    const supabase = getSupabaseClient();

    // Upload to Supabase Storage
    const { error: uploadError } = await supabase.storage.from(bucket).upload(objectPath, file.buffer, {
        contentType: file.mimetype,
        upsert: true,
        cacheControl: '3600',
    });

    if (uploadError) {
        logger.error('Supabase upload failed', { error: uploadError.message, bucket, objectPath });
        throw new AppError('Failed to upload image', 500);
    }

    const { data: publicUrlData } = supabase.storage.from(bucket).getPublicUrl(objectPath);
    const publicUrl = publicUrlData?.publicUrl;

    if (!publicUrl) {
        logger.error('Supabase getPublicUrl returned empty url', { bucket, objectPath });
        throw new AppError('Failed to resolve image URL', 500);
    }

    return prisma.$transaction(async (tx) => {
        await ensureCustomerExists(tx, customerId);

        const updated = await tx.customer.update({
            where: { customer_id: customerId },
            data: {
                profile_image_url: publicUrl,
            },
            select: {
                customer_id: true,
                full_name: true,
                email: true,
                phone: true,
                profile_image_url: true,
                updated_at: true,
            },
        });

        logger.info('Customer profile image uploaded', {
            customerId,
            bucket,
            objectPath,
        });

        return updated;
    });
};

exports.updateCustomerProfile = async (customerId, payload) => {
    assertUuid(customerId, 'customerId');

    const fullName =
        payload?.full_name !== undefined ? payload.full_name : payload?.fullName;
    const phone = payload?.phone;
    const profileImageUrl =
        payload?.profile_image_url !== undefined ? payload.profile_image_url : payload?.profileImageUrl;

    if (fullName !== undefined && fullName !== null && typeof fullName !== 'string') {
        throw new ValidationError('fullName must be a string');
    }
    if (phone !== undefined && phone !== null && typeof phone !== 'string') {
        throw new ValidationError('phone must be a string or null');
    }
    if (profileImageUrl !== undefined && profileImageUrl !== null && typeof profileImageUrl !== 'string') {
        throw new ValidationError('profileImageUrl must be a valid URL or null');
    }

    return prisma.$transaction(async (tx) => {
        await ensureCustomerExists(tx, customerId);

        const updated = await tx.customer.update({
            where: { customer_id: customerId },
            data: {
                ...(typeof fullName === 'string' ? { full_name: fullName.trim() } : {}),
                ...(typeof phone === 'string' ? { phone: phone.trim() } : phone === null ? { phone: null } : {}),
                ...(typeof profileImageUrl === 'string'
                    ? { profile_image_url: profileImageUrl }
                    : profileImageUrl === null
                      ? { profile_image_url: null }
                      : {}),
            },
            select: {
                customer_id: true,
                full_name: true,
                email: true,
                phone: true,
                profile_image_url: true,
                updated_at: true,
            },
        });

        logger.info('Customer profile updated', {
            customerId,
            changedName: typeof fullName === 'string',
            changedPhone: phone !== undefined,
            changedProfileImage: profileImageUrl !== undefined,
        });

        return updated;
    });
};

module.exports = exports;


