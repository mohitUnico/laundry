const deliveryOperationsService = require('../services/delivery-operations.service');
const realtimeService = require('../services/realtime.service');
const logger = require('../utils/logger');

/**
 * Delivery Staff Operations Controller
 * - GET   /api/v1/delivery-staff/shift/status
 * - POST  /api/v1/delivery-staff/shift/start
 * - POST  /api/v1/delivery-staff/shift/stop
 * - PATCH /api/v1/delivery-staff/location
 * - GET   /api/v1/delivery-staff/assignment-requests
 * - POST  /api/v1/delivery-staff/assignment-requests/:requestId/accept
 * - POST  /api/v1/delivery-staff/assignment-requests/:requestId/reject
 * - GET   /api/v1/delivery-staff/events (SSE)
 */

exports.getShiftStatus = async (req, res, next) => {
    try {
        const staffId = req.user?.user_id;
        logger.info('Delivery staff getShiftStatus', { staffId });

        const shift = await deliveryOperationsService.getShiftStatus({ staffId });
        res.status(200).json({
            success: true,
            data: shift
                ? {
                    shiftId: shift.shift_id,
                    staffId: shift.staff_id,
                    startedAt: shift.started_at,
                    isActive: shift.is_active,
                    lastLatitude: shift.last_latitude != null ? Number(shift.last_latitude) : null,
                    lastLongitude: shift.last_longitude != null ? Number(shift.last_longitude) : null,
                    lastLocationAt: shift.last_location_at,
                }
                : null,
            message: shift ? 'Shift status retrieved' : 'No active shift',
        });
    } catch (error) {
        next(error);
    }
};

exports.startShift = async (req, res, next) => {
    try {
        const staffId = req.user?.user_id;
        logger.info('Delivery staff startShift', { staffId });

        const shift = await deliveryOperationsService.startShift({ staffId });
        res.status(200).json({
            success: true,
            data: {
                shiftId: shift.shift_id,
                staffId: shift.staff_id,
                startedAt: shift.started_at,
                isActive: shift.is_active,
            },
            message: 'Shift started successfully',
        });
    } catch (error) {
        next(error);
    }
};

exports.stopShift = async (req, res, next) => {
    try {
        const staffId = req.user?.user_id;
        logger.info('Delivery staff stopShift', { staffId });

        const shift = await deliveryOperationsService.stopShift({ staffId });
        res.status(200).json({
            success: true,
            data: shift
                ? {
                    shiftId: shift.shift_id,
                    staffId: shift.staff_id,
                    endedAt: shift.ended_at,
                    isActive: shift.is_active,
                }
                : null,
            message: shift ? 'Shift stopped successfully' : 'No active shift to stop',
        });
    } catch (error) {
        next(error);
    }
};

exports.updateLocation = async (req, res, next) => {
    try {
        const staffId = req.user?.user_id;
        const { latitude, longitude } = req.body;
        logger.info('Delivery staff update location', { staffId });

        const shift = await deliveryOperationsService.updateLiveLocation({ staffId, latitude, longitude });
        res.status(200).json({
            success: true,
            data: {
                shiftId: shift.shift_id,
                lastLatitude: shift.last_latitude,
                lastLongitude: shift.last_longitude,
                lastLocationAt: shift.last_location_at,
            },
            message: 'Location updated successfully',
        });
    } catch (error) {
        next(error);
    }
};

exports.listAssignmentRequests = async (req, res, next) => {
    try {
        const staffId = req.user?.user_id;
        const { status } = req.query;

        const rows = await deliveryOperationsService.listStaffAssignmentRequests({ staffId, status });

        res.status(200).json({
            success: true,
            data: rows.map((r) => ({
                requestId: r.request_id,
                orderId: r.order_id,
            deliveryId: r.delivery_id,
                staffId: r.staff_id,
                deliveryType: r.delivery_type,
                status: r.status,
                offeredAt: r.offered_at,
                expiresAt: r.expires_at,
                pickup: {
                    address: r.pickup_address,
                    latitude: r.pickup_lat,
                    longitude: r.pickup_lng,
                },
                drop: {
                    address: r.drop_address,
                    latitude: r.drop_lat,
                    longitude: r.drop_lng,
                },
                rejectionNote: r.rejection_note || null,
            })),
            message: 'Assignment requests fetched successfully',
        });
    } catch (error) {
        next(error);
    }
};

exports.acceptAssignmentRequest = async (req, res, next) => {
    try {
        const staffId = req.user?.user_id;
        const { requestId } = req.params;

        const result = await deliveryOperationsService.respondToAssignmentRequest({
            staffId,
            requestId,
            action: 'accept',
        });

        res.status(200).json({
            success: true,
            data: result,
            message: 'Assignment accepted successfully',
        });
    } catch (error) {
        next(error);
    }
};

exports.rejectAssignmentRequest = async (req, res, next) => {
    try {
        const staffId = req.user?.user_id;
        const { requestId } = req.params;
        const { rejectionNote } = req.body;

        const result = await deliveryOperationsService.respondToAssignmentRequest({
            staffId,
            requestId,
            action: 'reject',
            rejectionNote,
        });

        res.status(200).json({
            success: true,
            data: result,
            message: 'Assignment rejected successfully',
        });
    } catch (error) {
        next(error);
    }
};

exports.events = async (req, res, next) => {
    try {
        const staffId = req.user?.user_id;
        logger.info('Delivery staff SSE connect', { staffId });

        realtimeService.subscribeDeliveryStaff({ staffId, res });
    } catch (error) {
        next(error);
    }
};

module.exports = exports;

