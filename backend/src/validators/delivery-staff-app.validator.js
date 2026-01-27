const Joi = require('joi');

const uuid = Joi.string().uuid();

exports.listAcceptedOrdersQuerySchema = Joi.object({
    page: Joi.number().integer().min(1).default(1),
    limit: Joi.number().integer().min(1).max(100).default(20),
});

exports.listOrderHistoryQuerySchema = Joi.object({
    page: Joi.number().integer().min(1).default(1),
    limit: Joi.number().integer().min(1).max(100).default(20),
    from: Joi.date().iso().optional(),
    to: Joi.date().iso().optional(),
});

exports.updateDeliveryStatusSchema = Joi.object({
    action: Joi.string().valid('start_delivery', 'picked_up', 'dropped').required(),
});

exports.uuidParamSchema = uuid.required();

exports.updatePerKgWeightsSchema = Joi.object({
    items: Joi.array()
        .items(
            Joi.object({
                orderItemId: uuid.required(),
                weightKg: Joi.number().min(0.01).max(500).precision(2).required(),
            })
        )
        .min(1)
        .unique('orderItemId')
        .required(),
});

