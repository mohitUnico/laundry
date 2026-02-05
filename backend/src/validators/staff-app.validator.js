const Joi = require('joi');

exports.listPaginationQuerySchema = Joi.object({
    page: Joi.number().integer().min(1).default(1),
    limit: Joi.number().integer().min(1).max(100).default(20),
});

exports.assignDeliverySchema = Joi.object({
    radiusKm: Joi.number().min(0.1).max(50).default(5),
    limit: Joi.number().integer().min(1).max(50).default(10),
    expiresInSeconds: Joi.number().integer().min(30).max(600).default(120),
});

exports.directAssignDeliverySchema = Joi.object({
    deliveryStaffId: Joi.string().uuid().required(),
});

exports.updatePerKgWeightsSchema = Joi.object({
    items: Joi.array()
        .items(
            Joi.object({
                orderItemId: Joi.string().uuid().required(),
                weightKg: Joi.number().min(0.01).max(500).precision(2).required(),
            })
        )
        .min(1)
        .unique('orderItemId')
        .required(),
});

exports.serviceManQueueQuerySchema = Joi.object({
    // comma separated statuses
    status: Joi.string()
        .allow('', null)
        .default('pending,in_progress')
        .messages({ 'string.base': 'status must be a string' }),
});

exports.updateServiceQueueItemSchema = Joi.object({
    action: Joi.string().valid('in_progress', 'completed', 'mark_for_later').required(),
    comments: Joi.string().allow('', null).optional(),
});

