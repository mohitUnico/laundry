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
        .when('pricing_type', {
            is: 'per_unit',
            then: Joi.array().items(cartItemSelectionSchema).min(1).required(), // Required and must have at least 1 item for per_unit
            otherwise: Joi.array().items(cartItemSelectionSchema).optional().allow(null), // Optional for per_kg (can be null or empty array)
        }),
    weight_kg: Joi.number()
        .positive()
        .when('pricing_type', {
            is: 'per_kg',
            then: Joi.optional().allow(null),
            otherwise: Joi.forbidden(),
        }),
});

exports.addCartItemsSchema = Joi.object({
    items: Joi.array().items(cartItemSchema).min(1).required(),
});

// Used for updating per-unit selection quantity in an existing cart item
// quantity can be 0 (meaning delete the selection; cart item may also be removed if empty)
exports.setSelectionQuantitySchema = Joi.object({
    cloth_id: Joi.string().uuid().required(),
    quantity: Joi.number().integer().min(0).required(),
});

module.exports = exports;


