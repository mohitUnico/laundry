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

        const customerId = req.user.user_id;
        const result = await orderService.getCustomerOrders(customerId, req.query);

        res.status(200).json({
            success: true,
            data: result,
            message: 'Orders fetched successfully',
        });
    } catch (error) {
        next(error);
    }
};