const cartService = require('../services/cart.service');
const { AuthorizationError } = require('../utils/errors');

exports.addCartItems = async (req, res, next) => {
    try {
        if (req.user.role !== 'customer') {
            throw new AuthorizationError('Only customers can update carts');
        }
        const result = await cartService.addItemsToActiveCart(req.user.user_id, req.body);
        res.status(201).json({
            success: true,
            data: {
                cart_id: result.cart_id,
                added_cart_item_ids: result.processed_cart_item_ids,
            },
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
        const carts = await cartService.getCustomerCarts(req.user.user_id);
        res.status(200).json({
            success: true,
            data: carts,
            message: 'Carts fetched successfully',
        });
    } catch (error) {
        next(error);
    }
};

exports.updateCartItem = async (req, res, next) => {
    try {
        if (req.user.role !== 'customer') {
            throw new AuthorizationError('Only customers can update carts');
        }
        const item = await cartService.updateCartItemPricingType(
            req.user.user_id,
            req.params.cartItemId,
            req.body.pricing_type
        );
        res.status(200).json({
            success: true,
            data: item,
            message: 'Cart item updated',
        });
    } catch (error) {
        next(error);
    }
};

exports.deleteCartItem = async (req, res, next) => {
    try {
        if (req.user.role !== 'customer') {
            throw new AuthorizationError('Only customers can update carts');
        }
        const result = await cartService.removeCartItem(req.user.user_id, req.params.cartItemId);
        res.status(200).json({
            success: true,
            data: result,
            message: 'Cart item removed',
        });
    } catch (error) {
        next(error);
    }
};

module.exports = exports;
