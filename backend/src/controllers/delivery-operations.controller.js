const deliveryOperationsService = require('../services/delivery-operations.service');
const logger = require('../utils/logger');

/**
 * Admin Delivery Operations Controller
 * - GET  /api/v1/admin/delivery-ops/nearby-staff
 * - POST /api/v1/admin/delivery-ops/assignment-requests
 * - POST /api/v1/admin/delivery-ops/assignment-requests/:requestId/cancel
 */

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
                requestId: created.request_id,
                orderId: created.order_id,
                deliveryId: created.delivery_id,
                staffId: created.staff_id,
                deliveryType: created.delivery_type,
                status: created.status,
                offeredAt: created.offered_at,
                expiresAt: created.expires_at,
                pickup: {
                    address: created.pickup_address,
                    latitude: created.pickup_lat,
                    longitude: created.pickup_lng,
                },
                drop: {
                    address: created.drop_address,
                    latitude: created.drop_lat,
                    longitude: created.drop_lng,
                },
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

