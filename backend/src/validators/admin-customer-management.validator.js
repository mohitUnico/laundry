const Joi = require('joi');

exports.adminCustomersSummaryQuerySchema = Joi.object({
    from: Joi.date().iso(),
    to: Joi.date().iso(),
    isActive: Joi.boolean(),
});

exports.adminCustomersListQuerySchema = Joi.object({
    from: Joi.date().iso(),
    to: Joi.date().iso(),
    isActive: Joi.boolean(),
    search: Joi.string().trim().min(1).max(200),
    page: Joi.number().integer().min(1).default(1),
    limit: Joi.number().integer().min(1).max(100).default(20),
});

exports.adminCreateCustomerBodySchema = Joi.object({
    fullName: Joi.string().trim().min(1).max(255).required(),
    email: Joi.string().email().trim().lowercase().required(),
    phone: Joi.string().trim().max(20).allow(null, ''),
    address: Joi.string().trim().max(500).allow(null, ''),
    addressLabel: Joi.string().trim().max(50).default('home'),
    latitude: Joi.number().allow(null),
    longitude: Joi.number().allow(null),
});

module.exports = exports;


