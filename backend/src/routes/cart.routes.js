const express = require('express');
const cartController = require('../controllers/cart.controller');
const { authenticateJWT, authorize } = require('../middleware/auth.middleware');
const { validate } = require('../middleware/validation.middleware');
const { addCartItemsSchema, updateCartItemSchema } = require('../validators/cart.validator');
const { ValidationError } = require('../utils/errors');
const Joi = require('joi');

const router = express.Router();

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

router.get('/', authenticateJWT, authorize('customer'), cartController.getCarts);

router.post(
    '/items',
    authenticateJWT,
    authorize('customer'),
    validate(addCartItemsSchema),
    cartController.addCartItems
);

router.patch(
    '/items/:cartItemId',
    authenticateJWT,
    authorize('customer'),
    validateUuidParam('cartItemId'),
    validate(updateCartItemSchema),
    cartController.updateCartItem
);

router.delete(
    '/items/:cartItemId',
    authenticateJWT,
    authorize('customer'),
    validateUuidParam('cartItemId'),
    cartController.deleteCartItem
);

module.exports = router;
