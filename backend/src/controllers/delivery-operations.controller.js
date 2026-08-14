const deliveryOperationsService = require('../services/delivery-operations.service');
const { getPickupAssignmentStatus } = require('../jobs/pickup-assignment.job');
const logger = require('../utils/logger');

/**
 * Admin Delivery Operations Controller
 * - GET  /api/v1/admin/delivery-ops/nearby-staff
 * - GET  /api/v1/admin/delivery-ops/pickup-assignment-status (debug)
 * - POST /api/v1/admin/delivery-ops/assignment-requests
 * - POST /api/v1/admin/delivery-ops/assignment-requests/:requestId/cancel
 */

exports.getPickupAssignmentStatus = async (req, res, next) => {
    try {
        const status = await getPickupAssignmentStatus();
        res.status(200).json({
            success: true,
            data: status,
            message: 'Pickup assignment status (for debugging)',
        });
    } catch (error) {
        next(error);
    }
};

exports.searchNearbyStaff = async (req, res, next) => {
    try {
        logger.info('Nearby delivery staff search', { userId: req.user?.user_id, query: req.query });

        const data = await deliveryOperationsService.searchNearbyDeliveryStaff(req.query);
        res.status(200).json({
            success: true,
            data,
            message: 'Nearby delivery staff fetched successfully',
        });
    } catch (error) {
        next(error);
    }
};

exports.createAssignmentRequest = async (req, res, next) => {
    try {
        logger.info('Create delivery assignment request', { userId: req.user?.user_id, body: req.body });

        const created = await deliveryOperationsService.createAssignmentRequest(req.body);
        res.status(201).json({
            success: true,
            data: {
                requestId: created.request?.request_id,
                orderId: created.request?.order_id,
                deliveryId: created.delivery?.delivery_id,
                deliveryType: created.request?.delivery_type,
                status: created.request?.status,
                offeredAt: created.request?.offered_at,
                expiresAt: created.request?.expires_at,
                pickup: created.request
                    ? {
                        address: created.request.pickup_address,
                        latitude: created.request.pickup_lat,
                        longitude: created.request.pickup_lng,
                    }
                    : null,
                drop: created.request
                    ? {
                        address: created.request.drop_address,
                        latitude: created.request.drop_lat,
                        longitude: created.request.drop_lng,
                    }
                    : null,
                recipients: (created.recipients || []).map((r) => ({
                    recipientId: r.recipient_id,
                    staffId: r.staff_id,
                    status: r.status,
                })),
            },
            message: 'Assignment request created successfully',
        });
    } catch (error) {
        next(error);
    }
};

exports.cancelAssignmentRequest = async (req, res, next) => {
    try {
        const { requestId } = req.params;
        logger.info('Cancel delivery assignment request', { userId: req.user?.user_id, requestId });

        const updated = await deliveryOperationsService.cancelAssignmentRequest({ requestId });
        res.status(200).json({
            success: true,
            data: {
                requestId: updated.request_id,
                status: updated.status,
                respondedAt: updated.responded_at || null,
            },
            message: 'Assignment request cancelled successfully',
        });
    } catch (error) {
        next(error);
    }
};

module.exports = exports;

