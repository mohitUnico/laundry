const prisma = require('../config/database');
const logger = require('../utils/logger');
const realtimeService = require('./realtime.service');
const { notifyOrderStatusChange, sendToToken } = require('./fcm.service');
const { NotFoundError, ValidationError, ConflictError } = require('../utils/errors');
const { getDefaultAssignmentConfig, validateAssignmentParams } = require('../config/delivery-assignment.config');

const DEFAULT_ASSIGNMENT_EXPIRES_SECONDS = 120;

const toNumber = (v) => {
    if (v === null || v === undefined) return null;
    const n = typeof v === 'number' ? v : parseFloat(String(v));
    return Number.isFinite(n) ? n : null;
};

const nowUtc = () => new Date();

async function _getActiveLaundryConfig() {
    const cfg = await prisma.laundryConfig.findFirst({
        where: { is_active: true },
        orderBy: { created_at: 'desc' },
        select: {
            config_id: true,
            business_name: true,
            address: true,
            latitude: true,
            longitude: true,
        },
    });

    if (!cfg) throw new NotFoundError('LaundryConfig');
    return cfg;
}

async function _getOrderForAssignment(orderId) {
    const order = await prisma.order.findUnique({
        where: { order_id: orderId },
        select: {
            order_id: true,
            order_status: true,
            pricing_model: true,
            pickup_address: {
                select: {
                    full_address: true,
                    latitude: true,
                    longitude: true,
                },
            },
            delivery_address: {
                select: {
                    full_address: true,
                    latitude: true,
                    longitude: true,
                },
            },
            bill: { select: { delivery_fee: true } },
            order_items: { select: { pricing_type: true, quantity: true } },
        },
    });

    if (!order) throw new NotFoundError('Order');
    return order;
}

async function _getPickupOriginFromPickupForDelivery(db, deliveryId) {
    const row = await db.pickupForDelivery.findUnique({
        where: { delivery_id: deliveryId },
        select: { pickup_lat: true, pickup_lng: true },
    });
    if (!row) throw new NotFoundError('PickupForDelivery');
    return { latitude: row.pickup_lat, longitude: row.pickup_lng };
}

function _buildLeg({ deliveryType, order, laundry }) {
    if (deliveryType === 'pickup') {
        return {
            pickup: {
                address: order.pickup_address.full_address,
                latitude: order.pickup_address.latitude,
                longitude: order.pickup_address.longitude,
            },
            drop: {
                address: laundry.address,
                latitude: laundry.latitude,
                longitude: laundry.longitude,
            },
        };
    }

    return {
        pickup: {
            address: laundry.address,
            latitude: laundry.latitude,
            longitude: laundry.longitude,
        },
        drop: {
            address: order.delivery_address.full_address,
            latitude: order.delivery_address.latitude,
            longitude: order.delivery_address.longitude,
        },
    };
}

async function _notifyDeliveryStaff(staffId, notification) {
    realtimeService.emitToDeliveryStaff(staffId, 'notification', notification);
}

exports.startShift = async ({ staffId }) => {
    const staff = await prisma.deliveryStaff.findUnique({
        where: { staff_id: staffId },
        select: { staff_id: true, is_active: true, is_verified_by_admin: true },
    });
    if (!staff) throw new NotFoundError('DeliveryStaff');
    if (!staff.is_active) throw new ValidationError('Delivery staff is inactive');
    if (!staff.is_verified_by_admin) throw new ValidationError('Delivery staff is not verified by admin');

    // If there's already an active shift, just return it (idempotent).
    const existingActive = await prisma.deliveryStaffShift.findFirst({
        where: { staff_id: staffId, is_active: true, ended_at: null },
        orderBy: { started_at: 'desc' },
    });

    if (existingActive) {
        return existingActive;
    }

    // Otherwise, reuse the most recent shift row for this staff by
    // updating its timings and flags instead of creating a brand new
    // row every time. This keeps one logical shift record per staff
    // that can be started/stopped multiple times.
    const lastShift = await prisma.deliveryStaffShift.findFirst({
        where: { staff_id: staffId },
        orderBy: { started_at: 'desc' },
    });

    const startedAt = nowUtc();

    if (lastShift) {
        return prisma.deliveryStaffShift.update({
            where: { shift_id: lastShift.shift_id },
            data: {
                is_active: true,
                started_at: startedAt,
                ended_at: null,
                // Reset last known location so new session starts clean.
                last_latitude: null,
                last_longitude: null,
                last_location_at: null,
            },
        });
    }

    return prisma.deliveryStaffShift.create({
        data: {
            staff_id: staffId,
            is_active: true,
            started_at: startedAt,
        },
    });
};

exports.stopShift = async ({ staffId }) => {
    const active = await prisma.deliveryStaffShift.findFirst({
        where: { staff_id: staffId, is_active: true, ended_at: null },
        orderBy: { started_at: 'desc' },
        select: { shift_id: true },
    });

    if (!active) {
        return null;
    }

    return prisma.deliveryStaffShift.update({
        where: { shift_id: active.shift_id },
        data: { is_active: false, ended_at: nowUtc() },
    });
};

/**
 * Get current shift status for a delivery staff (active shift if any).
 * Returns null if no active shift.
 */
exports.getShiftStatus = async ({ staffId }) => {
    const shift = await prisma.deliveryStaffShift.findFirst({
        where: { staff_id: staffId, is_active: true, ended_at: null },
        orderBy: { started_at: 'desc' },
    });
    return shift;
};

exports.updateLiveLocation = async ({ staffId, latitude, longitude }) => {
    const lat = toNumber(latitude);
    const lng = toNumber(longitude);
    if (lat === null || lng === null) throw new ValidationError('latitude and longitude are required numbers');

    const activeShift = await prisma.deliveryStaffShift.findFirst({
        where: { staff_id: staffId, is_active: true, ended_at: null },
        orderBy: { started_at: 'desc' },
        select: { shift_id: true },
    });

    if (!activeShift) {
        throw new ConflictError('Shift is not active. Start shift first.');
    }

    const when = nowUtc();

    const [_, shift] = await prisma.$transaction([
        prisma.deliveryStaff.update({
            where: { staff_id: staffId },
            data: {
                current_latitude: lat,
                current_longitude: lng,
            },
            select: { staff_id: true },
        }),
        prisma.deliveryStaffShift.update({
            where: { shift_id: activeShift.shift_id },
            data: {
                last_latitude: lat,
                last_longitude: lng,
                last_location_at: when,
            },
        }),
    ]);

    realtimeService.emitToDeliveryStaff(staffId, 'location', {
        latitude: lat,
        longitude: lng,
        recordedAt: when,
        shiftId: activeShift.shift_id,
    });

    return shift;
};

/**
 * Get all active delivery staff (no distance filtering)
 * Returns all verified, active staff with active shifts
 */
exports.getAllActiveDeliveryStaff = async ({ limit = 100 } = {}) => {
    const take = parseInt(limit, 10);
    if (!Number.isInteger(take) || take < 1 || take > 500) {
        throw new ValidationError('limit must be between 1 and 500');
    }

    const rows = await prisma.$queryRaw`
        SELECT
            ds.staff_id,
            ds.full_name,
            ds.email,
            ds.phone,
            ds.current_latitude,
            ds.current_longitude,
            NULL::float8 AS distance_km
        FROM delivery_staffs ds
        WHERE ds.is_active = TRUE
          AND ds.is_verified_by_admin = TRUE
          AND EXISTS (
              SELECT 1
              FROM delivery_staff_shifts s
              WHERE s.staff_id = ds.staff_id
                AND s.is_active = TRUE
                AND s.ended_at IS NULL
          )
        ORDER BY ds.created_at DESC
        LIMIT ${take}::int;
    `;

    return (rows || []).map((r0) => ({
        staffId: r0.staff_id,
        fullName: r0.full_name,
        email: r0.email,
        phone: r0.phone,
        currentCoordinates: {
            latitude: r0.current_latitude,
            longitude: r0.current_longitude,
        },
        distanceKm: null, // No distance when getting all staff
    }));
};

exports.searchNearbyDeliveryStaff = async ({ latitude, longitude, radiusKm = 5, limit = 10 }) => {
    const lat = toNumber(latitude);
    const lng = toNumber(longitude);
    const r = toNumber(radiusKm);
    const take = parseInt(limit, 10);

    if (lat === null || lng === null) throw new ValidationError('latitude and longitude are required');
    if (!Number.isFinite(r) || r <= 0) throw new ValidationError('radiusKm must be > 0');
    if (!Number.isInteger(take) || take < 1 || take > 50) throw new ValidationError('limit must be between 1 and 50');

    // NOTE:
    // We intentionally avoid filtering on a derived alias via an outer SELECT because it can be brittle
    // with parameter placeholders. Instead we duplicate the distance expression in WHERE.
    const rows = await prisma.$queryRaw`
        SELECT
            ds.staff_id,
            ds.full_name,
            ds.email,
            ds.phone,
            ds.current_latitude,
            ds.current_longitude,
            (
                6371::float8 * 2::float8 * asin(
                    sqrt(
                        power(sin(radians((ds.current_latitude::float8 - ${lat}::float8)) / 2::float8), 2::float8)
                        + cos(radians(${lat}::float8)) * cos(radians(ds.current_latitude::float8))
                          * power(sin(radians((ds.current_longitude::float8 - ${lng}::float8)) / 2::float8), 2::float8)
                    )
                )
            ) AS distance_km
        FROM delivery_staffs ds
        WHERE ds.is_active = TRUE
          AND ds.is_verified_by_admin = TRUE
          AND ds.current_latitude IS NOT NULL
          AND ds.current_longitude IS NOT NULL
          AND EXISTS (
              SELECT 1
              FROM delivery_staff_shifts s
              WHERE s.staff_id = ds.staff_id
                AND s.is_active = TRUE
                AND s.ended_at IS NULL
          )
          AND (
              6371::float8 * 2::float8 * asin(
                  sqrt(
                      power(sin(radians((ds.current_latitude::float8 - ${lat}::float8)) / 2::float8), 2::float8)
                      + cos(radians(${lat}::float8)) * cos(radians(ds.current_latitude::float8))
                        * power(sin(radians((ds.current_longitude::float8 - ${lng}::float8)) / 2::float8), 2::float8)
                  )
              )
          ) <= ${r}::float8
        ORDER BY distance_km ASC
        LIMIT ${take}::int;
    `;

    return (rows || []).map((r0) => ({
        staffId: r0.staff_id,
        fullName: r0.full_name,
        email: r0.email,
        phone: r0.phone,
        currentCoordinates: {
            latitude: r0.current_latitude,
            longitude: r0.current_longitude,
        },
        distanceKm: typeof r0.distance_km === 'number' ? r0.distance_km : parseFloat(r0.distance_km),
    }));
};

exports.createAssignmentRequest = async ({
    orderId,
    deliveryType,
    staffId = null,
    radiusKm = null, // null means send to all active staff (when sendToAll is true)
    limit = null, // Will use default from config if not provided
    expiresInSeconds = null, // Will use default from config if not provided
    sendToAll = null, // Will use default from config if not provided
}) => {
    if (!orderId) throw new ValidationError('orderId is required');
    if (!['pickup', 'drop'].includes(deliveryType)) throw new ValidationError('deliveryType must be pickup or drop');

    // Get default configuration and merge with provided parameters
    const defaultConfig = getDefaultAssignmentConfig();
    const params = {
        radiusKm: radiusKm !== null && radiusKm !== undefined ? radiusKm : defaultConfig.radiusKm,
        limit: limit !== null && limit !== undefined ? limit : defaultConfig.limit,
        expiresInSeconds: expiresInSeconds !== null && expiresInSeconds !== undefined ? expiresInSeconds : defaultConfig.expiresInSeconds,
        sendToAll: sendToAll !== null && sendToAll !== undefined ? sendToAll : defaultConfig.sendToAll,
    };

    // Validate and clamp parameters against configuration limits
    const validatedParams = validateAssignmentParams(params);
    const { radiusKm: validatedRadiusKm, limit: validatedLimit, expiresInSeconds: validatedExpiresInSeconds, sendToAll: validatedSendToAll } = validatedParams;

    const [order, laundry] = await Promise.all([_getOrderForAssignment(orderId), _getActiveLaundryConfig()]);

    if (!order.pickup_address || !order.delivery_address) {
        throw new ValidationError('Order is missing pickup or delivery address');
    }

    const leg = _buildLeg({ deliveryType, order, laundry });
    const expiresAt = new Date(Date.now() + Math.max(30, parseInt(validatedExpiresInSeconds, 10) || 0) * 1000);

    const needsWeightMachine = (order.order_items || []).some((i) => i.pricing_type === 'per_kg');
    const itemCount = Array.isArray(order.order_items)
        ? order.order_items.reduce((sum, i) => sum + (typeof i.quantity === 'number' ? i.quantity : 0), 0)
        : 0;

    // Prefer using an existing Delivery leg created when the order is confirmed.
    // Fallback: if missing (older orders), create the delivery leg + pickup/drop rows here.
    const created = await prisma.$transaction(async (tx) => {
        let delivery = await tx.delivery.findFirst({
            where: { order_id: orderId, delivery_type: deliveryType },
            orderBy: { created_at: 'desc' },
        });

        if (!delivery) {
            delivery = await tx.delivery.create({
                data: {
                    order_id: orderId,
                    staff_id: null,
                    delivery_type: deliveryType,
                    delivery_status: 'unassigned',
                    delivery_fee: (order.bill?.delivery_fee != null) ? order.bill.delivery_fee : 0,
                    needs_weight_machine: needsWeightMachine,
                },
            });
        }

        if (deliveryType === 'pickup') {
            await tx.pickupForDelivery.upsert({
                where: { delivery_id: delivery.delivery_id },
                create: {
                    delivery_id: delivery.delivery_id,
                    pickup_address: leg.pickup.address,
                    pickup_lat: leg.pickup.latitude,
                    pickup_lng: leg.pickup.longitude,
                    pickup_status: 'unassigned',
                },
                update: {},
            });

            // Store drop details separately
            await tx.dropForDelivery.upsert({
                where: { delivery_id: delivery.delivery_id },
                create: {
                    delivery_id: delivery.delivery_id,
                    drop_address: leg.drop.address,
                    drop_lat: leg.drop.latitude,
                    drop_lng: leg.drop.longitude,
                    drop_status: 'unassigned',
                },
                update: {},
            });
        } else {
            // For drop deliveries, pickup is the mart (leg.pickup) and drop is the customer (leg.drop)
            await tx.pickupForDelivery.upsert({
                where: { delivery_id: delivery.delivery_id },
                create: {
                    delivery_id: delivery.delivery_id,
                    pickup_address: leg.pickup.address,
                    pickup_lat: leg.pickup.latitude,
                    pickup_lng: leg.pickup.longitude,
                    pickup_status: 'unassigned',
                },
                update: {},
            });

            await tx.dropForDelivery.upsert({
                where: { delivery_id: delivery.delivery_id },
                create: {
                    delivery_id: delivery.delivery_id,
                    drop_address: leg.drop.address,
                    drop_lat: leg.drop.latitude,
                    drop_lng: leg.drop.longitude,
                    drop_status: 'unassigned',
                },
                update: {},
            });
        }

        let targetStaffIds = [];

        if (staffId) {
            targetStaffIds = [staffId];
        } else if (validatedSendToAll || validatedRadiusKm === null || validatedRadiusKm === undefined) {
            // Send to all active delivery staff (no distance limit)
            const candidates = await exports.getAllActiveDeliveryStaff({ limit: validatedLimit });
            if (candidates.length === 0) {
                throw new NotFoundError('Active DeliveryStaff');
            }
            targetStaffIds = candidates.map((c) => c.staffId);
        } else {
            // Fan-out: send the request to top-N nearby staff.
            // Use pickup_for_delivery as origin (pickup leg coordinate) as requested.
            const origin = await _getPickupOriginFromPickupForDelivery(tx, delivery.delivery_id);

            const candidates = await exports.searchNearbyDeliveryStaff({
                latitude: origin.latitude,
                longitude: origin.longitude,
                radiusKm: validatedRadiusKm,
                limit: validatedLimit,
            });

            if (candidates.length === 0) {
                throw new NotFoundError('Nearby DeliveryStaff');
            }

            targetStaffIds = candidates.map((c) => c.staffId);
        }

        // Prevent duplicate pending recipient rows for same staff on an active (pending) request.
        // If there's an existing pending request for this delivery, cancel it before creating a new one.
        const existingRequest = await tx.deliveryAssignmentRequest.findFirst({
            where: {
                delivery_id: delivery.delivery_id,
                status: 'pending',
                expires_at: { gt: nowUtc() },
            },
            orderBy: { offered_at: 'desc' },
            select: { request_id: true },
        });

        if (existingRequest) {
            await tx.deliveryAssignmentRequest.update({
                where: { request_id: existingRequest.request_id },
                data: { status: 'cancelled', responded_at: nowUtc() },
            });
            await tx.deliveryAssignmentRecipient.updateMany({
                where: { request_id: existingRequest.request_id, status: 'pending' },
                data: { status: 'cancelled', responded_at: nowUtc(), rejection_note: 'Superseded by a new request' },
            });
        }

        // Create ONE master request (staff_id NULL) and many recipients
        const request = await tx.deliveryAssignmentRequest.create({
            data: {
                order_id: orderId,
                delivery_id: delivery.delivery_id,
                staff_id: null,
                delivery_type: deliveryType,
                status: 'pending',
                expires_at: expiresAt,
                pickup_address: leg.pickup.address,
                pickup_lat: leg.pickup.latitude,
                pickup_lng: leg.pickup.longitude,
                drop_address: leg.drop.address,
                drop_lat: leg.drop.latitude,
                drop_lng: leg.drop.longitude,
            },
        });

        const recipients = await Promise.all(
            targetStaffIds.map((sid) =>
                tx.deliveryAssignmentRecipient.create({
                    data: {
                        request_id: request.request_id,
                        staff_id: sid,
                        status: 'pending',
                    },
                })
            )
        );

        const notifications = await Promise.all(
            recipients.map((rec) =>
                tx.deliveryStaffNotification.create({
                    data: {
                        staff_id: rec.staff_id,
                        type: 'assignment_request',
                        title: 'New delivery request',
                        body: `You have a new ${deliveryType} request for order ${orderId}`,
                        payload: {
                            requestId: request.request_id,
                            recipientId: rec.recipient_id,
                            orderId,
                            deliveryId: delivery.delivery_id,
                            deliveryType,
                            itemCount,
                            pickup: leg.pickup,
                            drop: leg.drop,
                            expiresAt: request.expires_at,
                        },
                    },
                })
            )
        );

        return { delivery, request, recipients, notifications, targetStaffIds };
    });

    const { delivery, request, recipients, notifications, targetStaffIds } = created;

    // Fetch FCM tokens for all recipient staff members
    const staffWithTokens = await prisma.deliveryStaff.findMany({
        where: {
            staff_id: { in: targetStaffIds },
            fcm_token: { not: null },
        },
        select: {
            staff_id: true,
            fcm_token: true,
            full_name: true,
        },
    });

    // Emit SSE notifications and send Firebase push notifications after transaction commits
    for (const n of notifications) {
        await _notifyDeliveryStaff(n.staff_id, {
            notificationId: n.notification_id,
            type: n.type,
            title: n.title,
            body: n.body,
            payload: n.payload,
            createdAt: n.created_at,
        });

        // Send Firebase push notification
        const staffToken = staffWithTokens.find((s) => s.staff_id === n.staff_id);
        if (staffToken?.fcm_token) {
            await sendToToken({
                token: staffToken.fcm_token,
                title: n.title,
                body: n.body,
                data: {
                    type: 'assignment_request',
                    requestId: request.request_id,
                    orderId,
                    deliveryId: delivery.delivery_id,
                    deliveryType,
                    recipientId: recipients.find((r) => r.staff_id === n.staff_id)?.recipient_id || '',
                    expiresAt: request.expires_at?.toISOString() || '',
                },
            }).catch((error) => {
                logger.warn('Failed to send FCM notification for assignment request', {
                    staffId: n.staff_id,
                    error: error?.message || String(error),
                });
            });
        }
    }

    logger.info('Delivery assignment request created', {
        orderId,
        deliveryId: delivery.delivery_id,
        requestId: request.request_id,
        staffIds: targetStaffIds,
        deliveryType,
        expiresAt,
        fcmNotificationsSent: staffWithTokens.length,
    });

    return {
        request,
        recipients,
        delivery,
    };
};

exports.directAssignDelivery = async ({
    orderId,
    deliveryType,
    deliveryStaffId,
    orderUpdateData = {},
    assignedBy = null,
}) => {
    if (!orderId) throw new ValidationError('orderId is required');
    if (!deliveryStaffId) throw new ValidationError('deliveryStaffId is required');
    if (!['pickup', 'drop'].includes(deliveryType)) throw new ValidationError('deliveryType must be pickup or drop');

    const [order, laundry, staff] = await Promise.all([
        _getOrderForAssignment(orderId),
        _getActiveLaundryConfig(),
        prisma.deliveryStaff.findUnique({
            where: { staff_id: deliveryStaffId },
            select: { staff_id: true, is_active: true, is_verified_by_admin: true },
        }),
    ]);

    if (!staff) throw new NotFoundError('DeliveryStaff');
    if (!staff.is_active) throw new ValidationError('Delivery staff is inactive');
    if (!staff.is_verified_by_admin) throw new ValidationError('Delivery staff is not verified by admin');

    const activeShift = await prisma.deliveryStaffShift.findFirst({
        where: { staff_id: deliveryStaffId, is_active: true, ended_at: null },
        orderBy: { started_at: 'desc' },
        select: { shift_id: true },
    });
    if (!activeShift) throw new ConflictError('Delivery staff shift is not active');

    if (!order.pickup_address || !order.delivery_address) {
        throw new ValidationError('Order is missing pickup or delivery address');
    }

    const leg = _buildLeg({ deliveryType, order, laundry });
    const needsWeightMachine = (order.order_items || []).some((i) => i.pricing_type === 'per_kg');
    const itemCount = Array.isArray(order.order_items)
        ? order.order_items.reduce((sum, i) => sum + (typeof i.quantity === 'number' ? i.quantity : 0), 0)
        : 0;
    const when = nowUtc();

    const requiredOrderStatus = deliveryType === 'pickup' ? 'pickup_assigned' : 'dispatch_assigned';

    const result = await prisma.$transaction(async (tx) => {
        let delivery = await tx.delivery.findFirst({
            where: { order_id: orderId, delivery_type: deliveryType },
            orderBy: { created_at: 'desc' },
        });

        if (!delivery) {
            delivery = await tx.delivery.create({
                data: {
                    order_id: orderId,
                    staff_id: null,
                    delivery_type: deliveryType,
                    delivery_status: 'unassigned',
                    delivery_fee: (order.bill?.delivery_fee != null) ? order.bill.delivery_fee : 0,
                    needs_weight_machine: needsWeightMachine,
                },
            });
        }

        // Ensure leg tables exist
        await tx.pickupForDelivery.upsert({
            where: { delivery_id: delivery.delivery_id },
            create: {
                delivery_id: delivery.delivery_id,
                pickup_address: leg.pickup.address,
                pickup_lat: leg.pickup.latitude,
                pickup_lng: leg.pickup.longitude,
                pickup_status: 'unassigned',
            },
            update: {},
        });

        await tx.dropForDelivery.upsert({
            where: { delivery_id: delivery.delivery_id },
            create: {
                delivery_id: delivery.delivery_id,
                drop_address: leg.drop.address,
                drop_lat: leg.drop.latitude,
                drop_lng: leg.drop.longitude,
                drop_status: 'unassigned',
            },
            update: {},
        });

        // Cancel any active pending request for this delivery to avoid stale offers on other devices
        const existingRequest = await tx.deliveryAssignmentRequest.findFirst({
            where: {
                delivery_id: delivery.delivery_id,
                status: 'pending',
                expires_at: { gt: when },
            },
            orderBy: { offered_at: 'desc' },
            select: { request_id: true },
        });

        if (existingRequest) {
            await tx.deliveryAssignmentRequest.update({
                where: { request_id: existingRequest.request_id },
                data: { status: 'cancelled', responded_at: when, rejection_note: 'Manually assigned by manager' },
            });
            await tx.deliveryAssignmentRecipient.updateMany({
                where: { request_id: existingRequest.request_id, status: 'pending' },
                data: { status: 'cancelled', responded_at: when, rejection_note: 'Manually assigned by manager' },
            });
        }

        const current = await tx.delivery.findUnique({
            where: { delivery_id: delivery.delivery_id },
            select: { delivery_id: true, staff_id: true, delivery_status: true, completed_at: true },
        });
        if (!current) throw new NotFoundError('Delivery');
        if (current.delivery_status === 'cancelled') throw new ConflictError('Delivery is cancelled');
        if (current.completed_at) throw new ConflictError('Delivery is already completed');

        if (current.staff_id && current.staff_id !== deliveryStaffId) {
            throw new ConflictError('Delivery is already assigned to another delivery staff');
        }

        const alreadyAssigned = current.staff_id === deliveryStaffId;

        await tx.delivery.update({
            where: { delivery_id: delivery.delivery_id },
            data: {
                staff_id: deliveryStaffId,
                delivery_status: 'assigned',
                assigned_at: when,
            },
        });

        if (deliveryType === 'pickup') {
            await tx.pickupForDelivery.update({
                where: { delivery_id: delivery.delivery_id },
                data: { pickup_status: 'assigned', pickup_time: null },
            });
        } else {
            await tx.dropForDelivery.update({
                where: { delivery_id: delivery.delivery_id },
                data: { drop_status: 'assigned', drop_time: null },
            });
        }

        const normalizedOrderUpdate = { ...(orderUpdateData || {}) };
        // If caller sets dispatched_by_distribution_manager_id but not dispatched_at, auto-fill it.
        if (
            deliveryType === 'drop' &&
            normalizedOrderUpdate.dispatched_by_distribution_manager_id &&
            !normalizedOrderUpdate.dispatched_at
        ) {
            normalizedOrderUpdate.dispatched_at = when;
        }

        await tx.order.update({
            where: { order_id: orderId },
            data: {
                ...normalizedOrderUpdate,
                order_status: requiredOrderStatus,
            },
            select: { order_id: true },
        });

        return {
            deliveryId: delivery.delivery_id,
            requestIdCancelled: (existingRequest?.request_id != null) ? existingRequest.request_id : null,
            alreadyAssigned,
            assignedAt: when,
        };
    });

    const notification = await prisma.deliveryStaffNotification.create({
        data: {
            staff_id: deliveryStaffId,
            type: 'direct_assignment',
            title: deliveryType === 'pickup' ? 'New pickup assigned' : 'New delivery assigned',
            body: `You have a new ${deliveryType} assigned for order ${orderId}`,
            payload: {
                mode: 'direct',
                orderId,
                deliveryId: result.deliveryId,
                deliveryType,
                assignedAt: result.assignedAt,
                itemCount,
                assignedBy: assignedBy || null,
            },
        },
    });

    await _notifyDeliveryStaff(deliveryStaffId, {
        notificationId: notification.notification_id,
        type: notification.type,
        title: notification.title,
        body: notification.body,
        payload: notification.payload,
        createdAt: notification.created_at,
    });

    // Fire a dedicated SSE event so apps can refresh accepted orders immediately
    realtimeService.emitToDeliveryStaff(deliveryStaffId, 'direct_assignment', {
        orderId,
        deliveryId: result.deliveryId,
        deliveryType,
        assignedAt: result.assignedAt,
        itemCount,
        mode: 'direct',
    });

    // Also emit the existing event name used after accept (for compatibility)
    realtimeService.emitToDeliveryStaff(deliveryStaffId, 'assignment_accepted', {
        requestId: null,
        deliveryId: result.deliveryId,
        orderId,
        deliveryType,
        itemCount,
        mode: 'direct',
    });

    logger.info('Direct delivery assignment completed', {
        orderId,
        deliveryId: result.deliveryId,
        deliveryType,
        deliveryStaffId,
        alreadyAssigned: result.alreadyAssigned,
        assignedBy,
    });

    // Push notify after transaction commits (non-blocking)
    notifyOrderStatusChange({ orderId, status: requiredOrderStatus }).catch(() => { });

    return {
        orderId,
        deliveryId: result.deliveryId,
        deliveryType,
        deliveryStaffId,
        assignedAt: result.assignedAt,
        alreadyAssigned: result.alreadyAssigned,
    };
};

exports.cancelAssignmentRequest = async ({ requestId }) => {
    if (!requestId) throw new ValidationError('requestId is required');

    const existing = await prisma.deliveryAssignmentRequest.findUnique({
        where: { request_id: requestId },
        select: { request_id: true, status: true, staff_id: true, delivery_id: true },
    });
    if (!existing) throw new NotFoundError('DeliveryAssignmentRequest');

    if (!['pending'].includes(existing.status)) {
        return existing;
    }

    const updated = await prisma.$transaction(async (tx) => {
        const reqRow = await tx.deliveryAssignmentRequest.update({
            where: { request_id: requestId },
            data: { status: 'cancelled', responded_at: nowUtc() },
        });

        await tx.delivery.update({
            where: { delivery_id: reqRow.delivery_id },
            data: { delivery_status: 'cancelled' },
        });

        return reqRow;
    });

    await prisma.deliveryStaffNotification.create({
        data: {
            staff_id: updated.staff_id,
            type: 'assignment_cancelled',
            title: 'Delivery request cancelled',
            body: 'The delivery request was cancelled by admin.',
            payload: { requestId: updated.request_id, deliveryId: updated.delivery_id },
        },
    });

    realtimeService.emitToDeliveryStaff(updated.staff_id, 'assignment_cancelled', { requestId: updated.request_id });

    return updated;
};

exports.listStaffAssignmentRequests = async ({ staffId, status = 'pending' }) => {
    // New flow: master request + recipients
    const recs = await prisma.deliveryAssignmentRecipient.findMany({
        where: {
            staff_id: staffId,
            ...(status ? { status } : {}),
        },
        orderBy: { created_at: 'desc' },
        take: 50,
        include: {
            request: true,
        },
    });

    // Backward compatibility: if there are legacy rows where staff_id is set directly on request
    const legacy = await prisma.deliveryAssignmentRequest.findMany({
        where: {
            staff_id: staffId,
            ...(status ? { status } : {}),
        },
        orderBy: { offered_at: 'desc' },
        take: 50,
    });

    const mappedFromRecipients = recs.map((r) => ({
        request_id: r.request.request_id,
        order_id: r.request.order_id,
        delivery_id: r.request.delivery_id,
        staff_id: r.staff_id,
        delivery_type: r.request.delivery_type,
        status: r.status,
        offered_at: r.request.offered_at,
        expires_at: r.request.expires_at,
        pickup_address: r.request.pickup_address,
        pickup_lat: r.request.pickup_lat,
        pickup_lng: r.request.pickup_lng,
        drop_address: r.request.drop_address,
        drop_lat: r.request.drop_lat,
        drop_lng: r.request.drop_lng,
        rejection_note: r.rejection_note,
    }));

    return [...mappedFromRecipients, ...legacy].slice(0, 50);
};

exports.respondToAssignmentRequest = async ({ staffId, requestId, action, rejectionNote = null }) => {
    if (!requestId) throw new ValidationError('requestId is required');
    if (!['accept', 'reject'].includes(action)) throw new ValidationError('action must be accept or reject');

    const when = nowUtc();

    if (action === 'reject') {
        // Prefer recipient-based rejection
        const updatedRec = await prisma.deliveryAssignmentRecipient.updateMany({
            where: { request_id: requestId, staff_id: staffId, status: 'pending' },
            data: { status: 'rejected', responded_at: when, rejection_note: rejectionNote || null },
        });

        // Backward compatibility: legacy per-staff requests
        if (updatedRec.count === 0) {
            const updatedLegacy = await prisma.deliveryAssignmentRequest.updateMany({
                where: {
                    request_id: requestId,
                    staff_id: staffId,
                    status: 'pending',
                },
                data: {
                    status: 'rejected',
                    responded_at: when,
                    rejection_note: rejectionNote || null,
                },
            });
            if (updatedLegacy.count === 0) throw new NotFoundError('Pending DeliveryAssignmentRequest');
        }

        await prisma.deliveryStaffNotification.create({
            data: {
                staff_id: staffId,
                type: 'assignment_rejected',
                title: 'Request rejected',
                body: 'You rejected a delivery request.',
                payload: { requestId, rejectionNote: rejectionNote || null },
            },
        });

        realtimeService.emitToDeliveryStaff(staffId, 'assignment_rejected', { requestId });
        return { requestId, status: 'rejected' };
    }

    // accept (one master request + many recipients: first-accept wins; cancel other recipients)
    const txResult = await prisma.$transaction(async (tx) => {
        const reqRow = await tx.deliveryAssignmentRequest.findUnique({
            where: { request_id: requestId },
        });

        if (!reqRow || reqRow.staff_id !== staffId) {
            // For master request, staff_id can be null; validate via recipient row
            if (!reqRow) throw new NotFoundError('DeliveryAssignmentRequest');
            if (reqRow.staff_id) throw new NotFoundError('DeliveryAssignmentRequest');
        }
        if (reqRow.status !== 'pending') {
            throw new ConflictError('Assignment request is not pending');
        }
        if (reqRow.expires_at && new Date(reqRow.expires_at) < when) {
            await tx.deliveryAssignmentRequest.update({
                where: { request_id: requestId },
                data: { status: 'expired', responded_at: when },
            });
            throw new ConflictError('Assignment request expired');
        }

        // Ensure this staff is an invited recipient (pending)
        const recipient = await tx.deliveryAssignmentRecipient.findUnique({
            where: { request_id_staff_id: { request_id: requestId, staff_id: staffId } },
        });
        if (!recipient || recipient.status !== 'pending') {
            // Legacy request (single staff) can still be accepted if it matches staff_id
            if (reqRow.staff_id && reqRow.staff_id === staffId) {
                // continue as legacy
            } else {
                throw new NotFoundError('Pending DeliveryAssignmentRecipient');
            }
        }

        // Atomically lock the delivery for the first accepter.
        const lock = await tx.delivery.updateMany({
            where: {
                delivery_id: reqRow.delivery_id,
                staff_id: null,
                delivery_status: 'unassigned',
            },
            data: { staff_id: staffId, delivery_status: 'assigned' },
        });

        if (lock.count === 0) {
            // Someone else already accepted.
            // Cancel this recipient so it disappears from this staff's device
            if (recipient) {
                await tx.deliveryAssignmentRecipient.update({
                    where: { recipient_id: recipient.recipient_id },
                    data: { status: 'cancelled', responded_at: when, rejection_note: 'Taken by another delivery staff' },
                });
            }
            throw new ConflictError('This delivery has already been accepted by another delivery staff');
        }

        const delivery = await tx.delivery.findUnique({ where: { delivery_id: reqRow.delivery_id } });

        if (reqRow.delivery_type === 'pickup') {
            await tx.pickupForDelivery.update({
                where: { delivery_id: reqRow.delivery_id },
                data: { pickup_status: 'assigned', pickup_time: null },
            });
            await tx.order.update({
                where: { order_id: reqRow.order_id },
                data: { order_status: 'pickup_assigned' },
            });
        } else {
            await tx.dropForDelivery.update({
                where: { delivery_id: reqRow.delivery_id },
                data: { drop_status: 'assigned', drop_time: null },
            });
            await tx.order.update({
                where: { order_id: reqRow.order_id },
                data: { order_status: 'dispatch_assigned' },
            });
        }

        await tx.deliveryAssignmentRequest.update({
            where: { request_id: requestId },
            data: { status: 'accepted', responded_at: when },
        });

        if (recipient) {
            await tx.deliveryAssignmentRecipient.update({
                where: { recipient_id: recipient.recipient_id },
                data: { status: 'accepted', responded_at: when },
            });
        }

        // Cancel all other pending recipients for this request (so it disappears on their devices)
        const pendingOthers = await tx.deliveryAssignmentRecipient.findMany({
            where: {
                request_id: requestId,
                status: 'pending',
                staff_id: { not: staffId },
            },
            select: { recipient_id: true, staff_id: true },
        });

        if (pendingOthers.length > 0) {
            await tx.deliveryAssignmentRecipient.updateMany({
                where: { request_id: requestId, status: 'pending', staff_id: { not: staffId } },
                data: { status: 'cancelled', responded_at: when, rejection_note: 'Taken by another delivery staff' },
            });

            await tx.deliveryStaffNotification.createMany({
                data: pendingOthers.map((p) => ({
                    staff_id: p.staff_id,
                    type: 'assignment_cancelled',
                    title: 'Delivery request closed',
                    body: 'Another delivery staff accepted this request.',
                    payload: {
                        requestId,
                        deliveryId: reqRow.delivery_id,
                        orderId: reqRow.order_id,
                        reason: 'taken',
                    },
                })),
            });
        }

        const notification = await tx.deliveryStaffNotification.create({
            data: {
                staff_id: staffId,
                type: 'assignment_accepted',
                title: 'Request accepted',
                body: `You accepted the ${reqRow.delivery_type} request.`,
                payload: {
                    requestId,
                    deliveryId: delivery.delivery_id,
                    orderId: reqRow.order_id,
                    pickup: {
                        address: reqRow.pickup_address,
                        latitude: reqRow.pickup_lat,
                        longitude: reqRow.pickup_lng,
                    },
                    drop: {
                        address: reqRow.drop_address,
                        latitude: reqRow.drop_lat,
                        longitude: reqRow.drop_lng,
                    },
                },
            },
        });

        realtimeService.emitToDeliveryStaff(staffId, 'assignment_accepted', {
            requestId,
            deliveryId: delivery.delivery_id,
            orderId: reqRow.order_id,
        });

        // Emit cancellation SSE for others
        for (const p of pendingOthers) {
            realtimeService.emitToDeliveryStaff(p.staff_id, 'assignment_cancelled', {
                requestId,
                deliveryId: reqRow.delivery_id,
                orderId: reqRow.order_id,
                reason: 'taken',
            });
        }

        return {
            requestId,
            deliveryId: delivery.delivery_id,
            status: 'accepted',
            notificationId: notification.notification_id,
            _orderId: reqRow.order_id,
            _statusToNotify: reqRow.delivery_type === 'pickup' ? 'pickup_assigned' : 'dispatch_assigned',
        };
    });

    // Push notify after transaction commits (non-blocking)
    notifyOrderStatusChange({ orderId: txResult._orderId, status: txResult._statusToNotify }).catch(() => { });

    // Do not leak internal helper fields
    const publicResult = { ...txResult };
    delete publicResult._orderId;
    delete publicResult._statusToNotify;
    return publicResult;
};

