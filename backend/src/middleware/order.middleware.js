const Joi = require('joi');
const { ValidationError } = require('../utils/errors');

const createOrderSchema = Joi.object({
    cart_id: Joi.string().uuid().required(),
    pickup_address_id: Joi.string().uuid().required(),
    delivery_address_id: Joi.string().uuid().required(),
    is_express: Joi.boolean().optional(),
    pickup_mode: Joi.string().valid('instant', 'scheduled').optional(),
    delivery_mode: Joi.string().valid('instant', 'scheduled').optional(),
    pickup_time_from: Joi.date().iso().optional(),
    pickup_time_to: Joi.date().iso().optional(),
    delivery_time_from: Joi.date().iso().optional(),
    delivery_time_to: Joi.date().iso().optional(),
    special_instructions: Joi.string().max(500).allow('', null).optional(),
    order_type: Joi.forbidden(),
    pickup_date: Joi.forbidden(),
    delivery_date: Joi.forbidden(),
    preferred_pickup_slot_from: Joi.forbidden(),
    preferred_pickup_slot_to: Joi.forbidden(),
    preferred_delivery_slot_from: Joi.forbidden(),
    preferred_delivery_slot_to: Joi.forbidden(),
}).unknown(false);

const updateOrderSchema = Joi.object({
    pickup_address_id: Joi.string().uuid(),
    delivery_address_id: Joi.string().uuid(),
    pickup_mode: Joi.string().valid('instant', 'scheduled'),
    delivery_mode: Joi.string().valid('instant', 'scheduled'),
    pickup_time_from: Joi.date().iso().allow(null),
    pickup_time_to: Joi.date().iso().allow(null),
    delivery_time_from: Joi.date().iso().allow(null),
    delivery_time_to: Joi.date().iso().allow(null),
})
    .min(1)
    .unknown(false);

exports.validateUpdateOrder = (req, res, next) => {
    const { error, value } = updateOrderSchema.validate(req.body, {
        abortEarly: false,
        stripUnknown: false,
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

exports.validateCreateOrder = (req, res, next) => {
    const { error, value } = createOrderSchema.validate(req.body, {
        abortEarly: false,
        stripUnknown: false,
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
