const collectionManagerAppService = require('../services/collection-manager-app.service');
const { AuthorizationError } = require('../utils/errors');

exports.listIncomingOrders = async (req, res, next) => {
    try {
        if (req.user.role !== 'collection_manager') {
            throw new AuthorizationError('Only collection managers can access this endpoint');
        }

        const { page, limit } = req.query;
        const data = await collectionManagerAppService.listIncomingOrders({ page, limit });

        res.status(200).json({
            success: true,
            data: data.orders,
            pagination: data.pagination,
            message: 'Incoming orders fetched successfully',
        });
    } catch (error) {
        next(error);
    }
};

exports.getOrderItems = async (req, res, next) => {
    try {
        if (req.user.role !== 'collection_manager') {
            throw new AuthorizationError('Only collection managers can access this endpoint');
        }

        const { orderId } = req.params;
        const data = await collectionManagerAppService.getOrderItems({ orderId });

        res.status(200).json({
            success: true,
            data,
            message: 'Order items fetched successfully',
        });
    } catch (error) {
        next(error);
    }
};

exports.markOrderReceived = async (req, res, next) => {
    try {
        if (req.user.role !== 'collection_manager') {
            throw new AuthorizationError('Only collection managers can access this endpoint');
        }

        const staffId = req.user.user_id;
        const { orderId } = req.params;
        const data = await collectionManagerAppService.markOrderReceived({ staffId, orderId });

        res.status(200).json({
            success: true,
            data,
            message: 'Order marked as received',
        });
    } catch (error) {
        next(error);
    }
};

exports.assignPickupDelivery = async (req, res, next) => {
    try {
        if (req.user.role !== 'collection_manager') {
            throw new AuthorizationError('Only collection managers can access this endpoint');
        }

        const { orderId } = req.params;
        const { radiusKm, limit, expiresInSeconds } = req.body;
        const data = await collectionManagerAppService.createPickupAssignment({
            orderId,
            radiusKm,
            limit,
            expiresInSeconds,
        });

        res.status(200).json({
            success: true,
            data,
            message: 'Pickup delivery assignment request created',
        });
    } catch (error) {
        next(error);
    }
};

exports.assignPickupDirect = async (req, res, next) => {
    try {
        if (req.user.role !== 'collection_manager') {
            throw new AuthorizationError('Only collection managers can access this endpoint');
        }

        const staffId = req.user.user_id;
        const { orderId } = req.params;
        const { deliveryStaffId } = req.body;

        const data = await collectionManagerAppService.assignPickupDirect({
            staffId,
            orderId,
            deliveryStaffId,
        });

        res.status(200).json({
            success: true,
            data,
            message: 'Pickup assigned to delivery staff successfully',
        });
    } catch (error) {
        next(error);
    }
};

exports.listReceivedOrders = async (req, res, next) => {
    try {
        if (req.user.role !== 'collection_manager') {
            throw new AuthorizationError('Only collection managers can access this endpoint');
        }

        const { page, limit } = req.query;
        const data = await collectionManagerAppService.listReceivedOrders({ page, limit });

        res.status(200).json({
            success: true,
            data: data.orders,
            pagination: data.pagination,
            message: 'Received orders fetched successfully',
        });
    } catch (error) {
        next(error);
    }
};

exports.submitToServices = async (req, res, next) => {
    try {
        if (req.user.role !== 'collection_manager') {
            throw new AuthorizationError('Only collection managers can access this endpoint');
        }

        const staffId = req.user.user_id;
        const { orderId } = req.params;
        const data = await collectionManagerAppService.submitOrderToServices({ staffId, orderId });

        res.status(200).json({
            success: true,
            data,
            message: 'Order submitted to services',
        });
    } catch (error) {
        next(error);
    }
};

exports.generateInvoice = async (req, res, next) => {
    try {
        if (req.user.role !== 'collection_manager') {
            throw new AuthorizationError('Only collection managers can access this endpoint');
        }

        const staffId = req.user.user_id;
        const { orderId } = req.params;
        const data = await collectionManagerAppService.generateInvoice({ staffId, orderId });

        res.status(200).json({
            success: true,
            data,
            message: 'Invoice generated successfully',
        });
    } catch (error) {
        next(error);
    }
};

exports.listSubmissionHistory = async (req, res, next) => {
    try {
        if (req.user.role !== 'collection_manager') {
            throw new AuthorizationError('Only collection managers can access this endpoint');
        }

        const { page, limit } = req.query;
        const data = await collectionManagerAppService.listSubmissionHistory({ page, limit });

        res.status(200).json({
            success: true,
            data: data.orders,
            pagination: data.pagination,
            message: 'Submission history fetched successfully',
        });
    } catch (error) {
        next(error);
    }
};

module.exports = exports;

