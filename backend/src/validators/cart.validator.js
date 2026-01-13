const Joi = require('joi');

const cartItemSelectionSchema = Joi.object({
    cloth_id: Joi.string().uuid().required(),
    quantity: Joi.number().integer().min(1).required(),
});

const cartItemSchema = Joi.object({
    service_id: Joi.string().uuid().required(),
    pricing_type: Joi.string().valid('per_unit', 'per_kg').required(),
    selections: Joi.array()
        .items(cartItemSelectionSchema)
        .min(1)
        .when('pricing_type', {
            is: 'per_unit',
            then: Joi.required(),
            otherwise: Joi.forbidden(),
        }),
    weight_kg: Joi.number()
        .positive()
        .when('pricing_type', {
            is: 'per_kg',
            then: Joi.required(),
            otherwise: Joi.forbidden(),
        }),
});

exports.addCartItemsSchema = Joi.object({
    items: Joi.array().items(cartItemSchema).min(1).required(),
});

module.exports = exports;


