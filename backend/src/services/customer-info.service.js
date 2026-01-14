const prisma = require('../config/database');
const logger = require('../utils/logger');
const { NotFoundError, ValidationError } = require('../utils/errors');

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

module.exports = exports;


