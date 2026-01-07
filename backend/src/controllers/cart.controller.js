const cartService = require('../services/cart.service');
const { AuthorizationError } = require('../utils/errors');

exports.addCartItems = async (req, res, next) => {
    try {
        if (req.user.role !== 'customer') {
            throw new AuthorizationError('Only customers can update carts');
        }

        const customerId = req.user.user_id; // JWT payload stores customer id under user_id
        const result = await cartService.addItemsToActiveCart(customerId, req.body);

        res.status(201).json({
            success: true,
            data: result,
            message: 'Cart items added successfully',
        });
    } catch (error) {
        next(error);
    }
};

exports.getCarts = async (req, res, next) => {
    try {
        if (req.user.role !== 'customer') {
            throw new AuthorizationError('Only customers can view carts');
        }

        const customerId = req.user.user_id;
        const carts = await cartService.getCustomerCarts(customerId);

        res.status(200).json({
            success: true,
            data: carts,
            message: 'Carts fetched successfully',
        });
    } catch (error) {
        next(error);
    }
};

module.exports = exports;


