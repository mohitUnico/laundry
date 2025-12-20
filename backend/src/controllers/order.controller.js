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
