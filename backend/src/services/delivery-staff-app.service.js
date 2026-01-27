const prisma = require('../config/database');
const logger = require('../utils/logger');
const { NotFoundError, ValidationError, ConflictError, AppError } = require('../utils/errors');
const { getSupabaseClient } = require('../config/supabase');
const { v4: uuidv4 } = require('uuid');

const UUID_REGEX =
    /^[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i;

const assertUuid = (value, fieldName) => {
    if (!value || typeof value !== 'string' || !UUID_REGEX.test(value)) {
        throw new ValidationError(`${fieldName} must be a valid UUID`);
    }
};

const normalizePagination = ({ page = 1, limit = 20 } = {}) => {
    const safePage = Number.isInteger(page) ? page : parseInt(page);
    const safeLimit = Number.isInteger(limit) ? limit : parseInt(limit);

    if (!Number.isInteger(safePage) || safePage < 1) throw new ValidationError('page must be >= 1');
    if (!Number.isInteger(safeLimit) || safeLimit < 1 || safeLimit > 100) {
        throw new ValidationError('limit must be between 1 and 100');
    }

    return { safePage, safeLimit, skip: (safePage - 1) * safeLimit };
};

const mapDeliveryToOrderCard = (d) => {
    const itemCount = d.order?._count?.order_items ?? 0;
    return {
        deliveryId: d.delivery_id,
        orderId: d.order_id,
        deliveryType: d.delivery_type,
        deliveryStatus: d.delivery_status,
        assignedAt: d.assigned_at,
        completedAt: d.completed_at,
        needsWeightMachine: d.needs_weight_machine,
        itemCount,
        order: d.order
            ? {
                orderStatus: d.order.order_status,
                pricingModel: d.order.pricing_model,
                orderType: d.order.order_type,
                totalAmount: d.order.total_amount?.toString?.() ?? String(d.order.total_amount),
                billingStatus: d.order.billing_status,
                createdAt: d.order.created_at,
                pickupDate: d.order.pickup_date,
                deliveryDate: d.order.delivery_date,
                customer: d.order.customer
                    ? {
                        customerId: d.order.customer.customer_id,
                        fullName: d.order.customer.full_name,
                        phone: d.order.customer.phone || null,
                    }
                    : null,
                bill: d.order.bill
                    ? {
                        finalAmount: d.order.bill.final_amount?.toString?.() ?? String(d.order.bill.final_amount),
                        paymentStatus: d.order.bill.payment_status,
                    }
                    : null,
            }
            : null,
        pickup: d.pickup
            ? {
                address: d.pickup.pickup_address,
                latitude: d.pickup.pickup_lat,
                longitude: d.pickup.pickup_lng,
                status: d.pickup.pickup_status,
                preferredFrom: d.pickup.preferred_pickup_from,
                preferredTo: d.pickup.preferred_pickup_to,
                time: d.pickup.pickup_time,
                proof: d.pickup.pickup_proof || null,
            }
            : null,
        drop: d.drop
            ? {
                address: d.drop.drop_address,
                latitude: d.drop.drop_lat,
                longitude: d.drop.drop_lng,
                status: d.drop.drop_status,
                preferredFrom: d.drop.preferred_drop_from,
                preferredTo: d.drop.preferred_drop_to,
                time: d.drop.drop_time,
                proof: d.drop.drop_proof || null,
            }
            : null,
    };
};

exports.getHomeStats = async ({ staffId }) => {
    assertUuid(staffId, 'staffId');

    const [completed, inProgress] = await Promise.all([
        prisma.delivery.count({
            where: { staff_id: staffId, completed_at: { not: null } },
        }),
        prisma.delivery.count({
            where: { staff_id: staffId, completed_at: null, delivery_status: { not: 'cancelled' } },
        }),
    ]);

    return { completed, inProgress };
};

exports.listAcceptedOrders = async ({ staffId, page, limit }) => {
    assertUuid(staffId, 'staffId');
    const { safePage, safeLimit, skip } = normalizePagination({ page, limit });

    const where = {
        staff_id: staffId,
        completed_at: null,
        delivery_status: { not: 'cancelled' },
    };

    const [total, deliveries] = await Promise.all([
        prisma.delivery.count({ where }),
        prisma.delivery.findMany({
            where,
            orderBy: { assigned_at: 'desc' },
            skip,
            take: safeLimit,
            include: {
                pickup: true,
                drop: true,
                order: {
                    include: {
                        customer: { select: { customer_id: true, full_name: true, phone: true } },
                        bill: { select: { final_amount: true, payment_status: true } },
                        _count: { select: { order_items: true } },
                    },
                },
            },
        }),
    ]);

    return {
        pagination: {
            page: safePage,
            limit: safeLimit,
            total,
            totalPages: Math.ceil(total / safeLimit),
        },
        orders: deliveries.map(mapDeliveryToOrderCard),
    };
};

exports.listOrderHistory = async ({ staffId, page, limit, from, to }) => {
    assertUuid(staffId, 'staffId');
    const { safePage, safeLimit, skip } = normalizePagination({ page, limit });

    const created_at = {};
    if (from) created_at.gte = new Date(from);
    if (to) created_at.lte = new Date(to);

    const where = {
        staff_id: staffId,
        completed_at: { not: null },
        ...(from || to ? { created_at } : {}),
    };

    const [total, deliveries] = await Promise.all([
        prisma.delivery.count({ where }),
        prisma.delivery.findMany({
            where,
            orderBy: { completed_at: 'desc' },
            skip,
            take: safeLimit,
            select: {
                delivery_id: true,
                delivery_type: true,
                completed_at: true,
                order_id: true,
                assignment_requests: {
                    where: { staff_id: staffId },
                    orderBy: { offered_at: 'desc' },
                    take: 1,
                    select: { status: true },
                },
                order: {
                    select: {
                        order_id: true,
                        _count: { select: { order_items: true } },
                        customer: { select: { full_name: true } },
                    },
                },
            },
        }),
    ]);

    return {
        pagination: {
            page: safePage,
            limit: safeLimit,
            total,
            totalPages: Math.ceil(total / safeLimit),
        },
        orders: deliveries.map((d) => ({
            order_id: d.order_id,
            delivery_request_status: d.assignment_requests?.[0]?.status || null, // accepted/rejected (or null)
            customer_name: d.order?.customer?.full_name || null,
            date_of_delivery: d.completed_at,
            number_of_order_items: d.order?._count?.order_items ?? 0,
            delivery_type: d.delivery_type === 'drop' ? 'delivery' : 'pickup',
        })),
    };
};

exports.getProfile = async ({ staffId }) => {
    assertUuid(staffId, 'staffId');

    const staff = await prisma.deliveryStaff.findUnique({
        where: { staff_id: staffId },
        select: {
            staff_id: true,
            full_name: true,
            email: true,
            phone: true,
            address: true,
            current_latitude: true,
            current_longitude: true,
            vehicle_type: true,
            vehicle_number: true,
            profile_image_url: true,
            verification_status: true,
            is_verified_by_admin: true,
            is_active: true,
            average_rating: true,
            total_deliveries: true,
            created_at: true,
            updated_at: true,
        },
    });

    if (!staff) throw new NotFoundError('DeliveryStaff');

    return {
        staffId: staff.staff_id,
        fullName: staff.full_name,
        email: staff.email,
        phone: staff.phone || null,
        address: staff.address || null,
        currentCoordinates:
            staff.current_latitude && staff.current_longitude
                ? { latitude: staff.current_latitude.toString(), longitude: staff.current_longitude.toString() }
                : null,
        vehicleType: staff.vehicle_type,
        vehicleNumber: staff.vehicle_number,
        profileImageUrl: staff.profile_image_url || null,
        verificationStatus: staff.verification_status,
        isVerifiedByAdmin: staff.is_verified_by_admin,
        isActive: staff.is_active,
        averageRating: staff.average_rating ? staff.average_rating.toString() : null,
        totalDeliveries: staff.total_deliveries,
        createdAt: staff.created_at,
        updatedAt: staff.updated_at,
    };
};

exports.uploadProfileImage = async ({ staffId, file }) => {
    assertUuid(staffId, 'staffId');

    if (!file) {
        throw new ValidationError('Image file is required');
    }

    const allowedMimeTypes = new Set(['image/jpeg', 'image/png', 'image/webp']);
    if (!allowedMimeTypes.has(file.mimetype)) {
        throw new ValidationError('Only JPEG, PNG, or WEBP images are allowed');
    }

    const bucket = process.env.SUPABASE_DELIVERY_PROFILE_BUCKET || 'delivery-staff';
    const ext = file.mimetype === 'image/jpeg' ? 'jpg' : file.mimetype === 'image/png' ? 'png' : 'webp';
    const objectPath = `delivery-staff/${staffId}/${uuidv4()}.${ext}`;

    const supabase = getSupabaseClient();

    const { error: uploadError } = await supabase.storage.from(bucket).upload(objectPath, file.buffer, {
        contentType: file.mimetype,
        upsert: true,
        cacheControl: '3600',
    });

    if (uploadError) {
        logger.error('Supabase upload failed (delivery staff profile)', {
            error: uploadError.message,
            bucket,
            objectPath,
        });
        throw new AppError('Failed to upload image', 500);
    }

    const { data: publicUrlData } = supabase.storage.from(bucket).getPublicUrl(objectPath);
    const publicUrl = publicUrlData?.publicUrl;

    if (!publicUrl) {
        logger.error('Supabase getPublicUrl returned empty url (delivery staff profile)', { bucket, objectPath });
        throw new AppError('Failed to resolve image URL', 500);
    }

    const updated = await prisma.deliveryStaff.update({
        where: { staff_id: staffId },
        data: { profile_image_url: publicUrl },
        select: {
            staff_id: true,
            full_name: true,
            email: true,
            phone: true,
            profile_image_url: true,
            updated_at: true,
        },
    });

    return {
        staffId: updated.staff_id,
        fullName: updated.full_name,
        email: updated.email,
        phone: updated.phone || null,
        profileImageUrl: updated.profile_image_url || null,
        updatedAt: updated.updated_at,
    };
};

exports.updateAcceptedOrderStatus = async ({ staffId, deliveryId, action }) => {
    assertUuid(staffId, 'staffId');
    assertUuid(deliveryId, 'deliveryId');

    if (!['start_delivery', 'picked_up', 'dropped'].includes(action)) {
        throw new ValidationError('Invalid action');
    }

    const now = new Date();

    return prisma.$transaction(async (tx) => {
        const delivery = await tx.delivery.findUnique({
            where: { delivery_id: deliveryId },
            include: { pickup: true, drop: true },
        });

        if (!delivery) throw new NotFoundError('Delivery');
        if (delivery.staff_id !== staffId) throw new ConflictError('Delivery does not belong to this staff');
        if (delivery.delivery_status === 'cancelled') throw new ConflictError('Delivery is cancelled');
        if (delivery.completed_at) throw new ConflictError('Delivery is already completed');

        // Basic flow:
        // - start_delivery: marks the active leg in progress; for drop leg also sets order out_for_delivery
        // - picked_up:
        //   - pickup leg: marks pickup + completes delivery + sets order picked_up
        //   - drop leg: marks pickup-from-laundry + sets order out_for_delivery
        // - dropped:
        //   - pickup leg: marks drop-at-laundry + completes delivery
        //   - drop leg: marks customer drop + completes delivery + sets order payment_pending

        if (action === 'start_delivery') {
            await tx.delivery.update({
                where: { delivery_id: deliveryId },
                data: { delivery_status: 'in_progress' },
            });

            if (delivery.delivery_type === 'pickup') {
                await tx.pickupForDelivery.update({
                    where: { delivery_id: deliveryId },
                    data: { pickup_status: 'in_progress' },
                });
            } else {
                await tx.dropForDelivery.update({
                    where: { delivery_id: deliveryId },
                    data: { drop_status: 'in_progress' },
                });
                await tx.order.update({
                    where: { order_id: delivery.order_id },
                    data: { order_status: 'out_for_delivery' },
                });
            }
        }

        if (action === 'picked_up') {
            await tx.pickupForDelivery.update({
                where: { delivery_id: deliveryId },
                data: { pickup_status: 'picked_up', pickup_time: now },
            });

            if (delivery.delivery_type === 'pickup') {
                await tx.delivery.update({
                    where: { delivery_id: deliveryId },
                    data: { delivery_status: 'completed', completed_at: now },
                });
                await tx.order.update({
                    where: { order_id: delivery.order_id },
                    data: { order_status: 'picked_up' },
                });
            } else {
                // drop leg: picked up from laundry -> out for delivery
                await tx.delivery.update({
                    where: { delivery_id: deliveryId },
                    data: { delivery_status: 'in_progress' },
                });
                await tx.order.update({
                    where: { order_id: delivery.order_id },
                    data: { order_status: 'out_for_delivery' },
                });
            }
        }

        if (action === 'dropped') {
            await tx.dropForDelivery.update({
                where: { delivery_id: deliveryId },
                data: { drop_status: 'dropped', drop_time: now },
            });

            await tx.delivery.update({
                where: { delivery_id: deliveryId },
                data: { delivery_status: 'completed', completed_at: now },
            });

            if (delivery.delivery_type === 'drop') {
                await tx.order.update({
                    where: { order_id: delivery.order_id },
                    data: { order_status: 'payment_pending' },
                });
            }
        }

        const refreshed = await tx.delivery.findUnique({
            where: { delivery_id: deliveryId },
            include: {
                pickup: true,
                drop: true,
                order: {
                    include: {
                        customer: { select: { customer_id: true, full_name: true, phone: true } },
                        bill: { select: { final_amount: true, payment_status: true } },
                    },
                },
            },
        });

        logger.info('Delivery staff app updated delivery status', { staffId, deliveryId, action });
        return mapDeliveryToOrderCard(refreshed);
    });
};

module.exports = exports;

