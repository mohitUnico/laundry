const Joi = require('joi');
const { ValidationError } = require('../utils/errors');

const createOrderSchema = Joi.object({
    items: Joi.array()
        .items(
            Joi.object({
                cloth_id: Joi.string().uuid().required(),
                quantity: Joi.number().integer().min(1).required()
                    .messages({
                        'number.base': 'quantity must be a number',
                        'number.min': 'quantity must be at least 1',
                        'number.integer': 'quantity must be an integer',
                    }),
            })
        )
        .min(1)
        .required()
        .messages({
            'array.min': 'At least one cloth item is required',
        }),
    pickup_address_id: Joi.string().uuid().required(),
    delivery_address_id: Joi.string().uuid().required(),
    pricing_model: Joi.string().valid('per_unit', 'per_kg').required(),
    order_type: Joi.string().valid('pickup_only', 'drop_only', 'both').required(),
    pickup_date: Joi.date().iso().optional(),
    delivery_date: Joi.date().iso().optional(),
    special_instructions: Joi.string().allow('', null),
});

exports.validateCreateOrder = (req, res, next) => {
    const { error, value } = createOrderSchema.validate(req.body, {
        abortEarly: false,
        stripUnknown: true,
    });

    if (error) {
        return next(new ValidationError('Invalid order payload', error.details.map((d) => d.message)));
    }

    req.body = value;
    next();
};

module.exports = exports;


