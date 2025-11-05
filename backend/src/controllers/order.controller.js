// Sample Order Controller
// This is a template - implement full logic as needed

const orderService = require('../services/order.service');
const { NotFoundError } = require('../utils/errors');

exports.createOrder = async (req, res, next) => {
    try {
        const customerId = req.user.customer_id; // From JWT token
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

exports.getOrders = async (req, res, next) => {
    try {
        const { page = 1, limit = 10, status } = req.query;
        const customerId = req.user.customer_id;

        const result = await orderService.getOrders(customerId, {
            page: parseInt(page),
            limit: parseInt(limit),
            status,
        });

        res.json({
            success: true,
            data: result.orders,
            pagination: {
                page: result.page,
                limit: result.limit,
                total: result.total,
                totalPages: result.totalPages,
            },
        });
    } catch (error) {
        next(error);
    }
};

exports.getOrderById = async (req, res, next) => {
    try {
        const { id } = req.params;
        const order = await orderService.getOrderById(id);

        if (!order) {
            throw new NotFoundError('Order');
        }

        res.json({
            success: true,
            data: order,
        });
    } catch (error) {
        next(error);
    }
};

exports.updateOrderStatus = async (req, res, next) => {
    try {
        const { id } = req.params;
        const { status } = req.body;

        const order = await orderService.updateOrderStatus(id, status);

        res.json({
            success: true,
            data: order,
            message: 'Order status updated successfully',
        });
    } catch (error) {
        next(error);
    }
};

exports.cancelOrder = async (req, res, next) => {
    try {
        const { id } = req.params;
        await orderService.cancelOrder(id);

        res.status(204).send();
    } catch (error) {
        next(error);
    }
};

module.exports = exports;

