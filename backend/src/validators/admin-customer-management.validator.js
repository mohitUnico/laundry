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
    page: Joi.number().integer().min(1).default(1),
    limit: Joi.number().integer().min(1).max(100).default(20),
});

module.exports = exports;


