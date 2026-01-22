const Joi = require('joi');

const latitude = Joi.number().min(-90).max(90).required();
const longitude = Joi.number().min(-180).max(180).required();

exports.nearbyStaffQuerySchema = Joi.object({
    latitude,
    longitude,
    radiusKm: Joi.number().positive().default(5),
    limit: Joi.number().integer().min(1).max(50).default(10),
});

exports.createAssignmentRequestSchema = Joi.object({
    orderId: Joi.string().uuid().required(),
    deliveryType: Joi.string().valid('pickup', 'drop').required(),
    staffId: Joi.string().uuid().optional(),
    radiusKm: Joi.number().positive().default(5),
    limit: Joi.number().integer().min(1).max(50).default(10),
    expiresInSeconds: Joi.number().integer().min(30).max(3600).default(120),
});

