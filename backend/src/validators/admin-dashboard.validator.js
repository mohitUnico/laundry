const Joi = require('joi');

exports.adminDashboardSummaryQuerySchema = Joi.object({
    from: Joi.date().iso(),
    to: Joi.date().iso(),
});

exports.adminDashboardOrderStatusQuerySchema = Joi.object({
    // optional day (UTC) to compute completedToday
    date: Joi.date().iso(),
});

exports.adminDashboardRevenueTrendQuerySchema = Joi.object({
    range: Joi.string().valid('7d', '30d').default('7d'),
});

exports.adminDashboardRecentOrdersQuerySchema = Joi.object({
    limit: Joi.number().integer().min(1).max(50).default(10),
});

exports.adminDashboardTopPerformersQuerySchema = Joi.object({
    limit: Joi.number().integer().min(1).max(50).default(5),
});

exports.adminDashboardDeliveryAnalyticsQuerySchema = Joi.object({
    limit: Joi.number().integer().min(1).max(50).default(10),
});

exports.adminDashboardLateDeliveriesQuerySchema = Joi.object({
    limit: Joi.number().integer().min(1).max(50).default(1),
});

module.exports = exports;


