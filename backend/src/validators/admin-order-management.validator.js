const Joi = require('joi');

const statusListSchema = Joi.string()
    .trim()
    .custom((value, helpers) => {
        if (!value) return value;
        const parts = value
            .split(',')
            .map((s) => s.trim())
            .filter(Boolean);
        if (parts.length === 0) return value;

        // Keep strict; service will validate allowed values again.
        const invalid = parts.filter((p) => !/^[a-z_]+$/.test(p));
        if (invalid.length > 0) {
            return helpers.error('any.invalid');
        }
        return value;
    }, 'status list validation');

exports.adminOrdersSummaryQuerySchema = Joi.object({
    from: Joi.date().iso(),
    to: Joi.date().iso(),
    // optional: compute completedToday for a specific UTC day (defaults to today)
    completedDate: Joi.date().iso(),
});

exports.adminOrdersListQuerySchema = Joi.object({
    status: statusListSchema,
    from: Joi.date().iso(),
    to: Joi.date().iso(),
    page: Joi.number().integer().min(1).default(1),
    limit: Joi.number().integer().min(1).max(100).default(20),
});

// Admin updates an order status
// Body: { status: "placed" | ... }
const adminOrderStatusSchema = Joi.string()
    .valid(
        'draft',
        'placed',
        'pickup_assigned',
        'picked_up',
        'received_by_collection',
        'submitted_to_services',
        'services_in_progress',
        'services_completed',
        'dispatch_assigned',
        'out_for_delivery',
        'payment_pending',
        'delivered',
        'closed',
        'cancelled'
    )
    .required()
    .messages({
        'any.only':
            'status must be one of: draft, placed, pickup_assigned, picked_up, received_by_collection, submitted_to_services, services_in_progress, services_completed, dispatch_assigned, out_for_delivery, payment_pending, delivered, closed, cancelled',
        'any.required': 'status is required',
        'string.base': 'status must be a string',
    });

exports.adminUpdateOrderStatusSchema = Joi.object({
    status: adminOrderStatusSchema,
});

module.exports = exports;


