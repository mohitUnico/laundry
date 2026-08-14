const Joi = require('joi');

exports.adminDeliveryStaffListQuerySchema = Joi.object({
    verificationStatus: Joi.string().valid('pending', 'verified', 'rejected'),
    isVerifiedByAdmin: Joi.boolean(),
    isActive: Joi.boolean(),
    page: Joi.number().integer().min(1).default(1),
    limit: Joi.number().integer().min(1).max(100).default(20),
});

exports.adminDeliveryStaffPendingVerificationsQuerySchema = Joi.object({
    page: Joi.number().integer().min(1).default(1),
    limit: Joi.number().integer().min(1).max(100).default(20),
});

exports.adminDeliveryStaffOnlineQuerySchema = Joi.object({
    page: Joi.number().integer().min(1).default(1),
    limit: Joi.number().integer().min(1).max(100).default(20),
});

module.exports = exports;

