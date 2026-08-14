const distributionManagerAppService = require('../services/distribution-manager-app.service');
const { AuthorizationError } = require('../utils/errors');

exports.listReadyToVerify = async (req, res, next) => {
    try {
        if (req.user.role !== 'distribution_manager') {
            throw new AuthorizationError('Only distribution managers can access this endpoint');
        }

        const { page, limit } = req.query;
        const data = await distributionManagerAppService.listReadyToVerify({ page, limit });

        res.status(200).json({
            success: true,
            data: data.orders,
            pagination: data.pagination,
            message: 'Orders ready to verify fetched successfully',
        });
    } catch (error) {
        next(error);
    }
};

exports.verifyOrder = async (req, res, next) => {
    try {
        if (req.user.role !== 'distribution_manager') {
            throw new AuthorizationError('Only distribution managers can access this endpoint');
        }

        const staffId = req.user.user_id;
        const { orderId } = req.params;
        const data = await distributionManagerAppService.verifyOrder({ staffId, orderId });

        res.status(200).json({
            success: true,
            data,
            message: 'Order verified successfully',
        });
    } catch (error) {
        next(error);
    }
};

exports.getOrderItems = async (req, res, next) => {
    try {
        if (req.user.role !== 'distribution_manager') {
            throw new AuthorizationError('Only distribution managers can access this endpoint');
        }

        const { orderId } = req.params;
        const data = await distributionManagerAppService.getOrderItems({ orderId });

        res.status(200).json({
            success: true,
            data,
            message: 'Order items fetched successfully',
        });
    } catch (error) {
        next(error);
    }
};

exports.listVerifiedOrders = async (req, res, next) => {
    try {
        if (req.user.role !== 'distribution_manager') {
            throw new AuthorizationError('Only distribution managers can access this endpoint');
        }

        const { page, limit } = req.query;
        const data = await distributionManagerAppService.listVerifiedOrders({ page, limit });

        res.status(200).json({
            success: true,
            data: data.orders,
            pagination: data.pagination,
            message: 'Verified orders fetched successfully',
        });
    } catch (error) {
        next(error);
    }
};

exports.dispatchOrder = async (req, res, next) => {
    try {
        if (req.user.role !== 'distribution_manager') {
            throw new AuthorizationError('Only distribution managers can access this endpoint');
        }

        const staffId = req.user.user_id;
        const { orderId } = req.params;
        const { radiusKm, limit, expiresInSeconds } = req.body;
        const data = await distributionManagerAppService.dispatchOrder({
            staffId,
            orderId,
            radiusKm,
            limit,
            expiresInSeconds,
        });

        res.status(200).json({
            success: true,
            data,
            message: 'Order dispatched successfully',
        });
    } catch (error) {
        next(error);
    }
};

exports.assignDropDirect = async (req, res, next) => {
    try {
        if (req.user.role !== 'distribution_manager') {
            throw new AuthorizationError('Only distribution managers can access this endpoint');
        }

        const staffId = req.user.user_id;
        const { orderId } = req.params;
        const { deliveryStaffId } = req.body;

        const data = await distributionManagerAppService.assignDropDirect({
            staffId,
            orderId,
            deliveryStaffId,
        });

        res.status(200).json({
            success: true,
            data,
            message: 'Delivery assigned to delivery staff successfully',
        });
    } catch (error) {
        next(error);
    }
};

exports.submitToCustomer = async (req, res, next) => {
    try {
        if (req.user.role !== 'distribution_manager') {
            throw new AuthorizationError('Only distribution managers can access this endpoint');
        }

        const staffId = req.user.user_id;
        const { orderId } = req.params;

        const data = await distributionManagerAppService.submitToCustomer({
            staffId,
            orderId,
        });

        res.status(200).json({
            success: true,
            data,
            message: 'Order submitted to customer successfully',
        });
    } catch (error) {
        next(error);
    }
};

exports.listDispatchHistory = async (req, res, next) => {
    try {
        if (req.user.role !== 'distribution_manager') {
            throw new AuthorizationError('Only distribution managers can access this endpoint');
        }

        const { page, limit } = req.query;
        const data = await distributionManagerAppService.listDispatchHistory({ page, limit });

        res.status(200).json({
            success: true,
            data: data.orders,
            pagination: data.pagination,
            message: 'Dispatch history fetched successfully',
        });
    } catch (error) {
        next(error);
    }
};

module.exports = exports;

