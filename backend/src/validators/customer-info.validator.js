const Joi = require('joi');

const addressLabel = Joi.string().trim().max(50);
const fullAddress = Joi.string().trim().min(3);
const latitude = Joi.number().min(-90).max(90);
const longitude = Joi.number().min(-180).max(180);

exports.createCustomerAddressSchema = Joi.object({
    address_label: addressLabel.required(),
    full_address: fullAddress.required(),
    latitude: latitude.required(),
    longitude: longitude.required(),
    is_default: Joi.boolean().optional(),
    delivery_note: Joi.string().trim().allow('').max(500).optional(),
});

exports.updateCustomerAddressSchema = Joi.object({
    address_label: addressLabel.optional(),
    full_address: fullAddress.optional(),
    latitude: latitude.optional(),
    longitude: longitude.optional(),
    is_default: Joi.boolean().optional(),
    // Allow explicitly clearing the note by sending null
    delivery_note: Joi.alternatives()
        .try(Joi.string().trim().allow('').max(500), Joi.valid(null))
        .optional(),
}).min(1);

module.exports = exports;


