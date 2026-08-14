const express = require('express');
const cartController = require('../controllers/cart.controller');
const { authenticateJWT, authorize } = require('../middleware/auth.middleware');
const { validate } = require('../middleware/validation.middleware');
const { setSelectionQuantitySchema, addCartItemsSchema } = require('../validators/cart.validator');
const { ValidationError } = require('../utils/errors');
const Joi = require('joi');

const router = express.Router();

// ============================================================================
// VALIDATION HELPERS
// ============================================================================

const uuidParam = Joi.string().uuid().required();

const validateUuidParam = (paramName) => {
    return (req, _res, next) => {
        const { error } = uuidParam.validate(req.params[paramName]);
        if (error) {
            return next(new ValidationError('Validation failed', [{ field: paramName, message: error.message }]));
        }
        next();
    };
};

// GET /api/v1/carts
// Get all carts (active + inactive) for the authenticated customer, with nested items/selections
router.get('/', authenticateJWT, authorize('customer'), cartController.getCarts);

// POST /api/v1/carts/items
// Adds items to the customer's active cart (creates a cart if none exists)
router.post('/items', authenticateJWT, authorize('customer'), validate(addCartItemsSchema), cartController.addCartItems);

// PATCH /api/v1/carts/items/:cartItemId/selections/quantity
// Single endpoint to handle both increment and decrement by setting the desired quantity.
router.patch(
    '/items/:cartItemId/selections/quantity',
    authenticateJWT,
    authorize('customer'),
    validateUuidParam('cartItemId'),
    validate(setSelectionQuantitySchema),
    cartController.setSelectionQuantity
);

// PATCH /api/v1/carts/items/:cartItemId/selections/:selectionId/increment
router.patch(
    '/items/:cartItemId/selections/:selectionId/increment',
    authenticateJWT,
    authorize('customer'),
    cartController.incrementSelection
);

// PATCH /api/v1/carts/items/:cartItemId/selections/:selectionId/decrement
// If quantity becomes 0, selection is deleted.
router.patch(
    '/items/:cartItemId/selections/:selectionId/decrement',
    authenticateJWT,
    authorize('customer'),
    cartController.decrementSelection
);

// DELETE /api/v1/carts/items/:cartItemId
router.delete('/items/:cartItemId', authenticateJWT, authorize('customer'), validateUuidParam('cartItemId'), cartController.deleteCartItem);

module.exports = router;


