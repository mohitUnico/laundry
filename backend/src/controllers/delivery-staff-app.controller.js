const deliveryStaffAppService = require('../services/delivery-staff-app.service');
const { AuthorizationError } = require('../utils/errors');

exports.getHomeStats = async (req, res, next) => {
    try {
        if (req.user.role !== 'delivery_staff') {
            throw new AuthorizationError('Only delivery staff can access this endpoint');
        }

        const staffId = req.user.user_id;
        const stats = await deliveryStaffAppService.getHomeStats({ staffId });

        res.status(200).json({
            success: true,
            data: stats,
            message: 'Home stats fetched successfully',
        });
    } catch (error) {
        next(error);
    }
};

exports.listAcceptedOrders = async (req, res, next) => {
    try {
        if (req.user.role !== 'delivery_staff') {
            throw new AuthorizationError('Only delivery staff can access this endpoint');
        }

        const staffId = req.user.user_id;
        const { page, limit } = req.query;

        const result = await deliveryStaffAppService.listAcceptedOrders({ staffId, page, limit });

        res.status(200).json({
            success: true,
            data: result.orders,
            pagination: result.pagination,
            message: 'Accepted orders fetched successfully',
        });
    } catch (error) {
        next(error);
    }
};

exports.updateDeliveryStatus = async (req, res, next) => {
    try {
        if (req.user.role !== 'delivery_staff') {
            throw new AuthorizationError('Only delivery staff can access this endpoint');
        }

        const staffId = req.user.user_id;
        const { deliveryId } = req.params;
        const { action } = req.body;

        const updated = await deliveryStaffAppService.updateAcceptedOrderStatus({
            staffId,
            deliveryId,
            action,
        });

        res.status(200).json({
            success: true,
            data: updated,
            message: 'Delivery status updated successfully',
        });
    } catch (error) {
        next(error);
    }
};

exports.listOrderHistory = async (req, res, next) => {
    try {
        if (req.user.role !== 'delivery_staff') {
            throw new AuthorizationError('Only delivery staff can access this endpoint');
        }

        const staffId = req.user.user_id;
        const { page, limit, from, to } = req.query;

        const result = await deliveryStaffAppService.listOrderHistory({ staffId, page, limit, from, to });

        res.status(200).json({
            success: true,
            data: result.orders,
            pagination: result.pagination,
            message: 'Order history fetched successfully',
        });
    } catch (error) {
        next(error);
    }
};

exports.getProfile = async (req, res, next) => {
    try {
        if (req.user.role !== 'delivery_staff') {
            throw new AuthorizationError('Only delivery staff can access this endpoint');
        }

        const staffId = req.user.user_id;
        const profile = await deliveryStaffAppService.getProfile({ staffId });

        res.status(200).json({
            success: true,
            data: profile,
            message: 'Profile fetched successfully',
        });
    } catch (error) {
        next(error);
    }
};

exports.uploadProfileImage = async (req, res, next) => {
    try {
        if (req.user.role !== 'delivery_staff') {
            throw new AuthorizationError('Only delivery staff can access this endpoint');
        }

        const staffId = req.user.user_id;
        const updated = await deliveryStaffAppService.uploadProfileImage({ staffId, file: req.file });

        res.status(200).json({
            success: true,
            data: updated,
            message: 'Profile image uploaded successfully',
        });
    } catch (error) {
        next(error);
    }
};

exports.updatePerKgWeights = async (req, res, next) => {
    try {
        if (req.user.role !== 'delivery_staff') {
            throw new AuthorizationError('Only delivery staff can access this endpoint');
        }

        const staffId = req.user.user_id;
        const { orderId } = req.params;
        const { items } = req.body;

        const updated = await deliveryStaffAppService.updatePerKgWeights({ staffId, orderId, items });

        res.status(200).json({
            success: true,
            data: updated,
            message: 'Per-kg weights updated successfully',
        });
    } catch (error) {
        next(error);
    }
};

exports.getPerKgItems = async (req, res, next) => {
    try {
        if (req.user.role !== 'delivery_staff') {
            throw new AuthorizationError('Only delivery staff can access this endpoint');
        }

        const staffId = req.user.user_id;
        const { orderId } = req.params;

        const data = await deliveryStaffAppService.getPerKgItems({ staffId, orderId });

        res.status(200).json({
            success: true,
            data,
            message: data === null ? 'Order does not have per-kg pricing model' : 'Per-kg order items fetched successfully',
        });
    } catch (error) {
        next(error);
    }
};

module.exports = exports;

