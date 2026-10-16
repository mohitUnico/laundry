const Joi = require('joi');

const cartItemSchema = Joi.object({
    service_id: Joi.string().uuid().required(),
    pricing_type: Joi.string().valid('per_unit', 'per_kg').required(),
});

exports.addCartItemsSchema = Joi.object({
    items: Joi.array().items(cartItemSchema).min(1).required(),
});

exports.updateCartItemSchema = Joi.object({
    pricing_type: Joi.string().valid('per_unit', 'per_kg').required(),
});

module.exports = exports;
