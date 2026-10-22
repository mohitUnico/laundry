const orderService = require('../services/order.service');
const { AuthorizationError } = require('../utils/errors');

exports.createOrder = async (req, res, next) => {
    try {
        if (req.user.role !== 'customer') {
            throw new AuthorizationError('Only customers can create orders');
        }

        const customerId = req.user.user_id; // payload stores customer id under user_id
        const order = await orderService.createOrder(customerId, req.body);

        res.status(201).json({
            success: true,
            data: order,
            message: 'Order created successfully',
        });
    } catch (error) {
        next(error);
    }
};

exports.createOrderContract = async (req, res, next) => {
    try {
        if (req.user.role !== 'customer') {
            throw new AuthorizationError('Only customers can create orders');
        }

        const order = await orderService.createOrder(req.user.user_id, req.body);
        res.status(201).json({
            success: true,
            data: {
                ...order,
                special_instructions: order.special_instructions ?? null,
                total_amount: order.total_amount || '0.00',
                bill: { generated: false },
                can_cancel: true,
                can_reschedule: !order.is_express,
            },
        });
    } catch (error) {
        next(error);
    }
};

exports.confirmOrder = async (req, res, next) => {
    try {
        if (req.user.role !== 'customer') {
            throw new AuthorizationError('Only customers can confirm orders');
        }

        const customerId = req.user.user_id;
        const { orderId } = req.params;

        const order = await orderService.confirmOrder(customerId, orderId);

        res.status(200).json({
            success: true,
            data: order,
            message: 'Order confirmed successfully',
        });
    } catch (error) {
        next(error);
    }
};

exports.getCustomerOrders = async (req, res, next) => {
    try {
        if (req.user.role !== 'customer') {
            throw new AuthorizationError('Only customers can view their orders');
        }

        const orderRead = require('../services/order-read.service');
        const customerId = req.user.user_id;
        const result = await orderRead.listOrders({
            customerId,
            bucket: req.query.bucket,
            status: req.query.status,
            page: req.query.page,
            limit: req.query.limit,
        });

        res.status(200).json({
            success: true,
            data: result,
            message: 'Orders fetched successfully',
        });
    } catch (error) {
        next(error);
    }
};

exports.cancelOrder = async (req, res, next) => {
    try {
        const lifecycle = require('../services/order-lifecycle.service');
        const data = await lifecycle.cancelOrder(req.user.user_id, req.params.orderId, req.body?.reason);
        res.status(200).json({ success: true, data, message: 'Order cancelled' });
    } catch (error) {
        next(error);
    }
};

exports.rescheduleOrder = async (req, res, next) => {
    try {
        const lifecycle = require('../services/order-lifecycle.service');
        const data = await lifecycle.rescheduleOrder(req.user.user_id, req.params.orderId, req.body || {});
        res.status(200).json({ success: true, data, message: 'Order rescheduled' });
    } catch (error) {
        next(error);
    }
};

exports.updateOrder = async (req, res, next) => {
    try {
        const lifecycle = require('../services/order-lifecycle.service');
        const orderRead = require('../services/order-read.service');
        await lifecycle.rescheduleOrder(req.user.user_id, req.params.orderId, req.body || {});
        const data = await orderRead.getOrderDetail({
            customerId: req.user.user_id,
            orderId: req.params.orderId,
        });
        res.status(200).json({ success: true, data });
    } catch (error) {
        next(error);
    }
};

exports.getInvoice = async (req, res, next) => {
    try {
        if (req.user.role !== 'customer') {
            throw new AuthorizationError('Only customers can view their orders');
        }
        const orderRead = require('../services/order-read.service');
        const detail = await orderRead.getOrderDetail({
            customerId: req.user.user_id,
            orderId: req.params.orderId,
        });
        res.status(200).json({
            success: true,
            data: {
                order_id: detail.order_id,
                bill: detail.bill,
                items: detail.items,
            },
        });
    } catch (error) {
        next(error);
    }
};

exports.getOrder = async (req, res, next) => {
    try {
        if (req.user.role !== 'customer') {
            throw new AuthorizationError('Only customers can view their orders');
        }
        const orderRead = require('../services/order-read.service');
        const data = await orderRead.getOrderDetail({
            customerId: req.user.user_id,
            orderId: req.params.orderId,
        });
        res.status(200).json({ success: true, data });
    } catch (error) {
        next(error);
    }
};

exports.getOrderTracking = async (req, res, next) => {
    try {
        if (req.user.role !== 'customer') {
            throw new AuthorizationError('Only customers can view order tracking');
        }

        const customerId = req.user.user_id;
        const { orderId } = req.params;

        const orderRead = require('../services/order-read.service');
        const data = await orderRead.getTracking({ customerId, orderId });

        res.status(200).json({
            success: true,
            data,
            message: 'Order tracking fetched successfully',
        });
    } catch (error) {
        next(error);
    }
};