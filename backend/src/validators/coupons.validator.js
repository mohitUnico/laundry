const Joi = require('joi');

const nonNegativeNumber = Joi.number().min(0);

exports.listCouponsQuerySchema = Joi.object({
    page: Joi.number().integer().min(1).default(1),
    limit: Joi.number().integer().min(1).max(100).default(20),
    is_active: Joi.boolean(),
    code: Joi.string().trim().min(1),
    discount_type: Joi.string().trim().min(1),
    valid_now: Joi.boolean(),
});

exports.createCouponSchema = Joi.object({
    code: Joi.string().trim().min(1).required(),
    description: Joi.string().allow('', null),
    discount_type: Joi.string().trim().min(1).required(),
    discount_value: nonNegativeNumber.required(),
    max_discount: nonNegativeNumber.allow(null),
    min_order_value: nonNegativeNumber.allow(null),
    usage_limit: Joi.number().integer().min(0).allow(null),
    usage_per_user: Joi.number().integer().min(0).allow(null),
    valid_from: Joi.date().iso().allow(null),
    valid_till: Joi.date().iso().allow(null),
    is_active: Joi.boolean().default(true),
});

exports.updateCouponSchema = Joi.object({
    code: Joi.string().trim().min(1),
    description: Joi.string().allow('', null),
    discount_type: Joi.string().trim().min(1),
    discount_value: nonNegativeNumber,
    max_discount: nonNegativeNumber.allow(null),
    min_order_value: nonNegativeNumber.allow(null),
    usage_limit: Joi.number().integer().min(0).allow(null),
    usage_per_user: Joi.number().integer().min(0).allow(null),
    valid_from: Joi.date().iso().allow(null),
    valid_till: Joi.date().iso().allow(null),
    is_active: Joi.boolean(),
}).min(1);

module.exports = exports;


