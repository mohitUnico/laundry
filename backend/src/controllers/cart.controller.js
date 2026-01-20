const cartService = require('../services/cart.service');
const { AuthorizationError } = require('../utils/errors');

exports.addCartItems = async (req, res, next) => {
    try {
        if (req.user.role !== 'customer') {
            throw new AuthorizationError('Only customers can update carts');
        }

        const customerId = req.user.user_id; // JWT payload stores customer id under user_id
        const result = await cartService.addItemsToActiveCart(customerId, req.body);

        // Extract cart_id and added cart item IDs from the result
        const cartId = result.cart_id;
        // Use processed_cart_item_ids if available (includes both new and existing), otherwise fallback to all cart items
        const addedCartItemIds = result.processed_cart_item_ids || (result.cart_items || []).map((item) => item.cart_item_id);

        res.status(201).json({
            success: true,
            data: {
                cart_id: cartId,
                added_cart_item_ids: addedCartItemIds,
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

exports.incrementSelection = async (req, res, next) => {
    try {
        if (req.user.role !== 'customer') {
            throw new AuthorizationError('Only customers can update carts');
        }

        const customerId = req.user.user_id;
        const { cartItemId, selectionId } = req.params;
        const result = await cartService.updateSelectionQuantity(customerId, cartItemId, selectionId, 1);

        res.status(200).json({
            success: true,
            data: result,
            message: 'Selection quantity increased',
        });
    } catch (error) {
        next(error);
    }
};

exports.decrementSelection = async (req, res, next) => {
    try {
        if (req.user.role !== 'customer') {
            throw new AuthorizationError('Only customers can update carts');
        }

        const customerId = req.user.user_id;
        const { cartItemId, selectionId } = req.params;
        const result = await cartService.updateSelectionQuantity(customerId, cartItemId, selectionId, -1);

        res.status(200).json({
            success: true,
            data: result,
            message: result.deleted ? 'Selection removed' : 'Selection quantity decreased',
        });
    } catch (error) {
        next(error);
    }
};

exports.setSelectionQuantity = async (req, res, next) => {
    try {
        if (req.user.role !== 'customer') {
            throw new AuthorizationError('Only customers can update carts');
        }

        const customerId = req.user.user_id;
        const { cartItemId } = req.params;
        const { cloth_id, quantity } = req.body;

        const result = await cartService.setSelectionQuantity(customerId, cartItemId, cloth_id, quantity);

        res.status(200).json({
            success: true,
            data: result,
            message: 'Selection quantity updated',
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

        const customerId = req.user.user_id;
        const { cartItemId } = req.params;
        const result = await cartService.removeCartItem(customerId, cartItemId);

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


