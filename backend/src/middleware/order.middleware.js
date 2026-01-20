const Joi = require('joi');
const { ValidationError } = require('../utils/errors');

/**
 * Validation schema for creating an order from a cart.
 * The order is created from an active cart, so we only need:
 * - cart_id: The active cart to convert to order
 * - pickup_address_id: Where to pick up items
 * - delivery_address_id: Where to deliver items
 * - order_type: Type of order (pickup_only, drop_only, both, express_delivery)
 * - Optional: pickup_date, delivery_date, special_instructions
 */
const createOrderSchema = Joi.object({
    cart_id: Joi.string().uuid().required().messages({
        'string.guid': 'cart_id must be a valid UUID',
        'any.required': 'cart_id is required',
    }),
    pickup_address_id: Joi.string().uuid().required().messages({
        'string.guid': 'pickup_address_id must be a valid UUID',
        'any.required': 'pickup_address_id is required',
    }),
    delivery_address_id: Joi.string().uuid().required().messages({
        'string.guid': 'delivery_address_id must be a valid UUID',
        'any.required': 'delivery_address_id is required',
    }),
    order_type: Joi.string()
        .valid('pickup_only', 'drop_only', 'both', 'express_delivery')
        .required()
        .messages({
            'any.only': 'order_type must be one of: pickup_only, drop_only, both, express_delivery',
            'any.required': 'order_type is required',
        }),
    pickup_date: Joi.date().iso().optional().messages({
        'date.format': 'pickup_date must be a valid ISO date string',
    }),
    delivery_date: Joi.date().iso().optional().messages({
        'date.format': 'delivery_date must be a valid ISO date string',
    }),
    special_instructions: Joi.string().allow('', null).optional().messages({
        'string.base': 'special_instructions must be a string',
    }),
});

exports.validateCreateOrder = (req, res, next) => {
    const { error, value } = createOrderSchema.validate(req.body, {
        abortEarly: false,
        stripUnknown: true,
    });

    if (error) {
        return next(
            new ValidationError(
                'Invalid order payload',
                error.details.map((d) => d.message)
            )
        );
    }

    req.body = value;
    next();
};

const confirmOrderParamsSchema = Joi.object({
    orderId: Joi.string().uuid().required().messages({
        'string.guid': 'orderId must be a valid UUID',
        'any.required': 'orderId is required',
    }),
});

exports.validateConfirmOrder = (req, res, next) => {
    const { error, value } = confirmOrderParamsSchema.validate(req.params, {
        abortEarly: false,
        stripUnknown: true,
    });

    if (error) {
        return next(
            new ValidationError(
                'Invalid confirm order params',
                error.details.map((d) => d.message)
            )
        );
    }

    req.params = value;
    next();
};

module.exports = exports;


