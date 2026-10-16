const prisma = require('../../config/database');
const configService = require('../config.service');
const realtimeService = require('../realtime.service');
const logger = require('../../utils/logger');
const { findRingCandidates } = require('./ring-candidates');
const { distanceKm } = require('./distance.provider');

function radiusForSlice(sliceIndex, sliceCount, maxRangeKm) {
    return (sliceIndex / sliceCount) * maxRangeKm;
}

async function loadContext(orderId, deliveryType) {
    const order = await prisma.order.findUnique({
        where: { order_id: orderId },
        include: {
            pickup_address: true,
            delivery_address: true,
            deliveries: { where: { delivery_type: deliveryType }, orderBy: { created_at: 'desc' }, take: 1 },
        },
    });
    if (!order) return null;
    const delivery = order.deliveries[0] || null;
    const laundry = await prisma.laundryConfig.findFirst({
        where: { is_active: true },
        orderBy: { created_at: 'desc' },
    });
    const originAddress = deliveryType === 'pickup' ? order.pickup_address : order.delivery_address;
    return { order, delivery, laundry, originAddress };
}

async function notifyStaff(staffIds, { request, sliceIndex, distances }) {
    for (const staffId of staffIds) {
        const notification = await prisma.deliveryStaffNotification.create({
            data: {
                staff_id: staffId,
                type: 'assignment_offer',
                title: request.delivery_type === 'pickup' ? 'Pickup offer' : 'Delivery offer',
                body: `New ${request.delivery_type} offer`,
                payload: {
                    requestId: request.request_id,
                    orderId: request.order_id,
                    deliveryType: request.delivery_type,
                    sliceIndex,
                    distanceKm: distances.get(staffId) ?? null,
                    expiresAt: request.expires_at,
                },
            },
        });
        realtimeService.emitToDeliveryStaff(staffId, 'notification', {
            notificationId: notification.notification_id,
            type: notification.type,
            payload: notification.payload,
        });
    }
}

async function startSearch({ orderId, deliveryType = 'pickup', now = new Date() }) {
    const ctx = await loadContext(orderId, deliveryType);
    if (!ctx?.order || !ctx.delivery || !ctx.originAddress) {
        logger.warn('startSearch skipped: missing order, delivery, or origin', { orderId, deliveryType });
        return null;
    }
    if (ctx.delivery.staff_id) return null;
    if (ctx.order.order_status === 'cancelled') return null;

    const existing = await prisma.deliveryAssignmentRequest.findFirst({
        where: { delivery_id: ctx.delivery.delivery_id, status: 'pending' },
    });
    if (existing) return existing;

    const timeoutMinutes = await configService.getNumber('ASSIGNMENT_TIMEOUT_MINUTES');
    const sliceCount = await configService.getInt('ASSIGNMENT_RANGE_SLICES');
    const maxRangeKm = await configService.getNumber('ASSIGNMENT_MAX_RANGE_KM');
    const expiresAt = new Date(now.getTime() + timeoutMinutes * 60 * 1000);

    const laundry = ctx.laundry;
    const customer = deliveryType === 'pickup' ? ctx.order.pickup_address : ctx.order.delivery_address;
    const request = await prisma.deliveryAssignmentRequest.create({
        data: {
            order_id: orderId,
            delivery_id: ctx.delivery.delivery_id,
            delivery_type: deliveryType,
            status: 'pending',
            offered_at: now,
            expires_at: expiresAt,
            pickup_address: ctx.order.pickup_address.full_address,
            pickup_lat: ctx.order.pickup_address.latitude,
            pickup_lng: ctx.order.pickup_address.longitude,
            drop_address: deliveryType === 'pickup' ? laundry.address : customer.full_address,
            drop_lat: deliveryType === 'pickup' ? laundry.latitude : customer.latitude,
            drop_lng: deliveryType === 'pickup' ? laundry.longitude : customer.longitude,
            slice_count: sliceCount,
            current_slice: 0,
            max_range_km: maxRangeKm,
        },
    });

    await advanceSlice(request.request_id, { now, sliceIndex: 1 });

    try {
        const queue = require('./assignment.queue');
        await queue.scheduleSearchJobs({
            requestId: request.request_id,
            orderId,
            deliveryType,
            sliceCount,
            timeoutMs: timeoutMinutes * 60 * 1000,
            startedAt: now,
        });
    } catch (err) {
        logger.warn('Failed to schedule assignment jobs; catch-up will cover them', {
            error: err.message,
            requestId: request.request_id,
        });
    }

    return prisma.deliveryAssignmentRequest.findUnique({ where: { request_id: request.request_id } });
}

async function advanceSlice(requestId, { now = new Date(), sliceIndex } = {}) {
    const request = await prisma.deliveryAssignmentRequest.findUnique({
        where: { request_id: requestId },
        include: { delivery: true },
    });
    if (!request || request.status !== 'pending') return { skipped: true };
    if (request.delivery?.staff_id) return { skipped: true };
    if (request.expires_at && new Date(request.expires_at) <= now) {
        return finishTimeout(requestId, { now });
    }

    const index = sliceIndex || request.current_slice + 1;
    if (index <= request.current_slice) return { skipped: true, reason: 'already_advanced' };
    if (index > request.slice_count) return { skipped: true, reason: 'past_last_slice' };

    const maxRange = Number(request.max_range_km);
    const radiusKm = radiusForSlice(index, request.slice_count, maxRange);
    const origin = {
        latitude: request.pickup_lat,
        longitude: request.pickup_lng,
    };
    if (request.delivery_type === 'drop') {
        origin.latitude = request.drop_lat;
        origin.longitude = request.drop_lng;
    }

    const candidates = await findRingCandidates({
        origin,
        radiusKm,
        requestId,
    });

    if (candidates.length) {
        await prisma.deliveryAssignmentRecipient.createMany({
            data: candidates.map((c) => ({
                request_id: requestId,
                staff_id: c.staffId,
                status: 'pending',
                slice_index: index,
                distance_km: Math.round(c.distanceKm * 100) / 100,
            })),
            skipDuplicates: true,
        });
        const distances = new Map(candidates.map((c) => [c.staffId, c.distanceKm]));
        await notifyStaff(
            candidates.map((c) => c.staffId),
            { request, sliceIndex: index, distances }
        );
    }

    const sliceMs =
        (new Date(request.expires_at).getTime() - new Date(request.offered_at).getTime()) /
        request.slice_count;
    const nextAt = index < request.slice_count ? new Date(now.getTime() + sliceMs) : null;

    await prisma.deliveryAssignmentRequest.update({
        where: { request_id: requestId },
        data: { current_slice: index, next_slice_at: nextAt },
    });

    return { skipped: false, sliceIndex: index, offered: candidates.length, radiusKm };
}

async function finishTimeout(requestId, { now = new Date() } = {}) {
    const request = await prisma.deliveryAssignmentRequest.findUnique({
        where: { request_id: requestId },
        include: { recipients: { where: { status: 'pending' } } },
    });
    if (!request || request.status !== 'pending') return { skipped: true };

    await prisma.$transaction([
        prisma.deliveryAssignmentRequest.update({
            where: { request_id: requestId },
            data: { status: 'expired', responded_at: now, ended_reason: 'timeout', next_slice_at: null },
        }),
        prisma.deliveryAssignmentRecipient.updateMany({
            where: { request_id: requestId, status: 'pending' },
            data: { status: 'expired', responded_at: now },
        }),
    ]);

    for (const rec of request.recipients) {
        realtimeService.emitToDeliveryStaff(rec.staff_id, 'assignment_expired', {
            requestId,
            orderId: request.order_id,
        });
    }
    const { emitOrderEvent } = require('../notification-events');
    emitOrderEvent('assignment_timeout', {
        orderId: request.order_id,
        deliveryType: request.delivery_type,
    }).catch(() => {});
    return { skipped: false, status: 'expired' };
}

async function stopSearch(orderId, deliveryType, reason, { now = new Date() } = {}) {
    const pending = await prisma.deliveryAssignmentRequest.findMany({
        where: { order_id: orderId, delivery_type: deliveryType, status: 'pending' },
        include: { recipients: { where: { status: 'pending' } } },
    });
    for (const request of pending) {
        await prisma.deliveryAssignmentRequest.update({
            where: { request_id: request.request_id },
            data: { status: 'cancelled', responded_at: now, ended_reason: reason, next_slice_at: null },
        });
        await prisma.deliveryAssignmentRecipient.updateMany({
            where: { request_id: request.request_id, status: 'pending' },
            data: { status: 'cancelled', responded_at: now },
        });
        for (const rec of request.recipients) {
            realtimeService.emitToDeliveryStaff(rec.staff_id, 'assignment_cancelled', {
                requestId: request.request_id,
                orderId,
                reason,
            });
        }
        try {
            const queue = require('./assignment.queue');
            await queue.removeSearchJobs(request.request_id);
        } catch {
            // queue optional
        }
    }
    return { stopped: pending.length };
}

async function getAssignState(orderId, deliveryType) {
    const delivery = await prisma.delivery.findFirst({
        where: { order_id: orderId, delivery_type: deliveryType },
        orderBy: { created_at: 'desc' },
    });
    if (!delivery) return { state: 'none' };
    if (delivery.staff_id) return { state: 'assigned', staffId: delivery.staff_id };

    const latest = await prisma.deliveryAssignmentRequest.findFirst({
        where: { delivery_id: delivery.delivery_id },
        orderBy: { offered_at: 'desc' },
    });
    if (!latest) return { state: 'none' };
    if (latest.status === 'pending') {
        return { state: 'searching', endsAt: latest.expires_at, requestId: latest.request_id };
    }
    if (latest.status === 'expired') {
        return { state: 'enabled', requestId: latest.request_id };
    }
    return { state: 'none', requestStatus: latest.status };
}

async function listAssignableStaff(orderId, deliveryType = 'pickup') {
    const ctx = await loadContext(orderId, deliveryType);
    if (!ctx?.originAddress) return [];
    const staff = await prisma.deliveryStaff.findMany({
        where: { is_active: true, is_verified_by_admin: true },
        include: {
            deliveryStaffShifts: {
                where: { is_active: true, ended_at: null },
                orderBy: { started_at: 'desc' },
                take: 1,
            },
        },
    });
    const origin = {
        latitude: ctx.originAddress.latitude,
        longitude: ctx.originAddress.longitude,
    };
    const rows = staff.map((s) => {
        const onShift = s.deliveryStaffShifts.length > 0;
        const km =
            s.current_latitude == null
                ? null
                : distanceKm(origin, {
                      latitude: s.current_latitude,
                      longitude: s.current_longitude,
                  });
        return {
            staffId: s.staff_id,
            fullName: s.full_name,
            phone: s.phone,
            onShift,
            distanceKm: km == null ? null : Math.round(km * 100) / 100,
            lastLocationAt: s.deliveryStaffShifts[0]?.last_location_at || null,
        };
    });
    rows.sort((a, b) => {
        if (a.onShift !== b.onShift) return a.onShift ? -1 : 1;
        if (a.distanceKm == null) return 1;
        if (b.distanceKm == null) return -1;
        return a.distanceKm - b.distanceKm;
    });
    return rows;
}

async function markEnded(requestId, reason, now = new Date()) {
    await prisma.deliveryAssignmentRequest.update({
        where: { request_id: requestId },
        data: { ended_reason: reason, responded_at: now },
    });
    try {
        const queue = require('./assignment.queue');
        await queue.removeSearchJobs(requestId);
    } catch {
        // queue optional
    }
}

module.exports = {
    radiusForSlice,
    startSearch,
    advanceSlice,
    finishTimeout,
    stopSearch,
    getAssignState,
    listAssignableStaff,
    markEnded,
};
