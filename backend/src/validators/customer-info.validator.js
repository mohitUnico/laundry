const Joi = require('joi');

const addressLabel = Joi.string().trim().max(50);
const fullAddress = Joi.string().trim().min(3);
const latitude = Joi.number().min(-90).max(90);
const longitude = Joi.number().min(-180).max(180);
const imageUrl = Joi.string().uri({ scheme: ['http', 'https'] }).max(500);

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

// PATCH /api/v1/customer-info/profile-image
// Update/clear the customer's profile image URL
exports.updateCustomerProfileImageSchema = Joi.object({
    // Prefer snake_case for this module, but allow camelCase too
    profile_image_url: Joi.alternatives().try(imageUrl, Joi.valid(null)).optional(),
    profileImageUrl: Joi.alternatives().try(imageUrl, Joi.valid(null)).optional(),
})
    .or('profile_image_url', 'profileImageUrl')
    .messages({
        'object.missing': 'profile_image_url or profileImageUrl is required',
    });

// PATCH /api/v1/customer-info/profile
// Update customer's basic profile fields.
exports.updateCustomerProfileSchema = Joi.object({
    // Prefer snake_case for this module, but allow camelCase too
    full_name: Joi.string().trim().min(2).max(255).optional(),
    fullName: Joi.string().trim().min(2).max(255).optional(),
    phone: Joi.string().trim().max(20).allow('', null).optional(),
    // Optional: allow setting/clearing profile image url directly.
    // (Upload flow uses /profile-image/upload to generate URL in "customer-info" bucket.)
    profile_image_url: Joi.alternatives().try(imageUrl, Joi.valid(null)).optional(),
    profileImageUrl: Joi.alternatives().try(imageUrl, Joi.valid(null)).optional(),
})
    .min(1)
    .messages({
        'object.min': 'At least one field is required',
    });

module.exports = exports;


