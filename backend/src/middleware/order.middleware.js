const Joi = require('joi');
const { ValidationError } = require('../utils/errors');

/**
 * Validation schema for creating a draft order from a cart.
 * The order is created from an active cart with delivery type, addresses, and time slots.
 * - cart_id: The active cart to convert to order
 * - pickup_address_id: Where to pick up items
 * - delivery_address_id: Where to deliver items
 * - order_type: Type of order (pickup_only, drop_only, both, express_delivery)
 * - preferred_pickup_slot_from: Preferred pickup slot start date and time (ISO 8601 format)
 * - preferred_pickup_slot_to: Preferred pickup slot end date and time (ISO 8601 format)
 * - preferred_delivery_slot_from: Preferred delivery slot start date and time (ISO 8601 format)
 * - preferred_delivery_slot_to: Preferred delivery slot end date and time (ISO 8601 format)
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
    preferred_pickup_slot_from: Joi.date()
        .iso()
        .when('order_type', {
            is: Joi.string().valid('pickup_only', 'both', 'express_delivery'),
            then: Joi.required(),
            otherwise: Joi.optional().allow(null),
        })
        .messages({
            'date.format': 'preferred_pickup_slot_from must be a valid ISO date and time string',
            'any.required': 'preferred_pickup_slot_from is required when order_type includes pickup',
        }),
    preferred_pickup_slot_to: Joi.date()
        .iso()
        .when('order_type', {
            is: Joi.string().valid('pickup_only', 'both', 'express_delivery'),
            then: Joi.required(),
            otherwise: Joi.optional().allow(null),
        })
        .when('preferred_pickup_slot_from', {
            is: Joi.exist(),
            then: Joi.date().greater(Joi.ref('preferred_pickup_slot_from')),
            otherwise: Joi.optional().allow(null),
        })
        .messages({
            'date.format': 'preferred_pickup_slot_to must be a valid ISO date and time string',
            'date.greater': 'preferred_pickup_slot_to must be after preferred_pickup_slot_from',
            'any.required': 'preferred_pickup_slot_to is required when order_type includes pickup',
        }),
    preferred_delivery_slot_from: Joi.date()
        .iso()
        .when('order_type', {
            is: Joi.string().valid('drop_only', 'both', 'express_delivery'),
            then: Joi.required(),
            otherwise: Joi.optional().allow(null),
        })
        .messages({
            'date.format': 'preferred_delivery_slot_from must be a valid ISO date and time string',
            'any.required': 'preferred_delivery_slot_from is required when order_type includes delivery',
        }),
    preferred_delivery_slot_to: Joi.date()
        .iso()
        .when('order_type', {
            is: Joi.string().valid('drop_only', 'both', 'express_delivery'),
            then: Joi.required(),
            otherwise: Joi.optional().allow(null),
        })
        .when('preferred_delivery_slot_from', {
            is: Joi.exist(),
            then: Joi.date().greater(Joi.ref('preferred_delivery_slot_from')),
            otherwise: Joi.optional().allow(null),
        })
        .messages({
            'date.format': 'preferred_delivery_slot_to must be a valid ISO date and time string',
            'date.greater': 'preferred_delivery_slot_to must be after preferred_delivery_slot_from',
            'any.required': 'preferred_delivery_slot_to is required when order_type includes delivery',
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

/**
 * Validation schema for confirming an order.
 * Requires only the order_id in the URL parameter.
 */
const confirmOrderSchema = Joi.object({
    orderId: Joi.string().uuid().required().messages({
        'string.guid': 'orderId must be a valid UUID',
        'any.required': 'orderId is required',
    }),
});

const listOrdersQuerySchema = Joi.object({
    page: Joi.number().integer().min(1).default(1),
    limit: Joi.number().integer().min(1).max(50).default(10),
    status: Joi.string()
        .valid(
            'draft',
            'placed',
            'pickup_assigned',
            'picked_up',
            'received_by_collection',
            'submitted_to_services',
            'services_in_progress',
            'services_completed',
            'dispatch_assigned',
            'out_for_delivery',
            'payment_pending',
            'delivered',
            'closed',
            'cancelled'
        )
        .optional(),
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

exports.validateConfirmOrder = (req, res, next) => {
    const { error, value } = confirmOrderSchema.validate(
        { orderId: req.params.orderId },
        {
            abortEarly: false,
            stripUnknown: true,
        }
    );

    if (error) {
        return next(
            new ValidationError(
                'Invalid order ID',
                error.details.map((d) => d.message)
            )
        );
    }

    req.params.orderId = value.orderId;
    next();
};

exports.validateListOrdersQuery = (req, res, next) => {
    const { error, value } = listOrdersQuerySchema.validate(req.query, {
        abortEarly: false,
        stripUnknown: true,
    });

    if (error) {
        return next(
            new ValidationError(
                'Invalid query parameters',
                error.details.map((d) => d.message)
            )
        );
    }

    req.query = value;
    next();
};

module.exports = exports;


