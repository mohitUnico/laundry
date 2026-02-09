const { Prisma } = require('@prisma/client');
const prisma = require('../config/database');
const logger = require('../utils/logger');
const { AppError } = require('../utils/errors');
const { v4: uuidv4 } = require('uuid');

// For dashboard/day-overview, "completed" is treated as 'delivered'.
// Keeping this aligned avoids double-counting when orders later transition to 'closed'.
const COMPLETED_ORDER_STATUSES = ['delivered'];

const startOfUtcDay = (date) =>
    new Date(Date.UTC(date.getUTCFullYear(), date.getUTCMonth(), date.getUTCDate(), 0, 0, 0));

const getUtcDayRange = (dateInput) => {
    const date = dateInput instanceof Date ? dateInput : new Date(dateInput);
    if (Number.isNaN(date.getTime())) {
        throw new AppError('Invalid date provided', 400);
    }

    const start = startOfUtcDay(date);
    const end = new Date(Date.UTC(date.getUTCFullYear(), date.getUTCMonth(), date.getUTCDate() + 1, 0, 0, 0));
    return { start, end, metricDate: start };
};

const safeDiv = (num, den) => {
    if (!den || den === 0) return 0;
    return num / den;
};

class DailyMetricsService {
    /**
     * Recalculate and upsert DailyMetrics for a specific UTC day.
     *
     * Semantics (day-wise):
     * - total_orders: number of non-draft orders created on that day (UTC)
     * - completed_orders: number of orders that became delivered/closed on that day (UTC, based on updated_at)
     * - cancelled_orders: number of orders that became cancelled on that day (UTC, based on updated_at)
     * - total_revenue: sum of completed orders' bill.final_amount (fallback: order.total_amount) for completions that day
     * - total_customers: distinct customers who created orders that day
     * - new_customers: customers created that day
     * - avg_order_value: total_revenue / completed_orders
     * - completion_rate: completed_orders / total_orders * 100
     * - avg_delivery_duration: average minutes for completed drop deliveries that day
     */
    async recalculateForUtcDate(dateInput) {
        try {
            const { start, end, metricDate } = getUtcDayRange(dateInput);

            const [totalOrders, completedOrders, cancelledOrders, newCustomers] = await Promise.all([
                prisma.order.count({
                    where: {
                        order_status: { not: 'draft' },
                        created_at: { gte: start, lt: end },
                    },
                }),
                prisma.order.count({
                    where: {
                        order_status: { in: COMPLETED_ORDER_STATUSES },
                        updated_at: { gte: start, lt: end },
                    },
                }),
                prisma.order.count({
                    where: {
                        order_status: 'cancelled',
                        updated_at: { gte: start, lt: end },
                    },
                }),
                prisma.customer.count({
                    where: {
                        created_at: { gte: start, lt: end },
                    },
                }),
            ]);

            const customersGrouped = await prisma.order.groupBy({
                by: ['customer_id'],
                where: {
                    order_status: { not: 'draft' },
                    created_at: { gte: start, lt: end },
                },
            });
            const totalCustomers = customersGrouped.length;

            const completedOrdersWithBill = await prisma.order.findMany({
                where: {
                    order_status: { in: COMPLETED_ORDER_STATUSES },
                    updated_at: { gte: start, lt: end },
                },
                select: {
                    total_amount: true,
                    bill: {
                        select: {
                            final_amount: true,
                        },
                    },
                },
            });

            const totalRevenueDecimal = completedOrdersWithBill.reduce((acc, order) => {
                const revenue = (order.bill?.final_amount != null) ? order.bill.final_amount : ((order.total_amount != null) ? order.total_amount : new Prisma.Decimal(0));
                return acc.add(new Prisma.Decimal(revenue));
            }, new Prisma.Decimal(0));

            const deliveries = await prisma.delivery.findMany({
                where: {
                    delivery_type: 'drop',
                    completed_at: { gte: start, lt: end },
                    delivery_status: 'completed',
                },
                select: {
                    actual_duration: true,
                    assigned_at: true,
                    completed_at: true,
                },
            });

            const deliveryDurations = deliveries
                .map((d) => {
                    if (Number.isFinite(d.actual_duration) && d.actual_duration > 0) return d.actual_duration;
                    if (!d.assigned_at || !d.completed_at) return null;
                    const minutes = Math.round((d.completed_at.getTime() - d.assigned_at.getTime()) / 60000);
                    return minutes > 0 ? minutes : null;
                })
                .filter((v) => typeof v === 'number' && Number.isFinite(v));

            const avgDeliveryDuration =
                deliveryDurations.length === 0
                    ? 0
                    : Math.round(deliveryDurations.reduce((sum, v) => sum + v, 0) / deliveryDurations.length);

            const totalRevenueNumber = parseFloat(totalRevenueDecimal.toFixed(2));
            const avgOrderValue = parseFloat(safeDiv(totalRevenueNumber, completedOrders).toFixed(2));
            const completionRate = parseFloat(safeDiv(completedOrders * 100, totalOrders).toFixed(2));

            const now = new Date();

            await prisma.dailyMetrics.upsert({
                where: { metric_date: metricDate },
                create: {
                    metric_id: uuidv4(),
                    metric_date: metricDate,
                    total_orders: totalOrders,
                    completed_orders: completedOrders,
                    cancelled_orders: cancelledOrders,
                    total_revenue: new Prisma.Decimal(totalRevenueNumber),
                    total_customers: totalCustomers,
                    new_customers: newCustomers,
                    avg_order_value: new Prisma.Decimal(avgOrderValue),
                    completion_rate: new Prisma.Decimal(completionRate),
                    avg_delivery_duration: avgDeliveryDuration,
                    updated_at: now,
                },
                update: {
                    total_orders: totalOrders,
                    completed_orders: completedOrders,
                    cancelled_orders: cancelledOrders,
                    total_revenue: new Prisma.Decimal(totalRevenueNumber),
                    total_customers: totalCustomers,
                    new_customers: newCustomers,
                    avg_order_value: new Prisma.Decimal(avgOrderValue),
                    completion_rate: new Prisma.Decimal(completionRate),
                    avg_delivery_duration: avgDeliveryDuration,
                    updated_at: now,
                },
                select: { metric_date: true },
            });

            if (process.env.DAILY_METRICS_LOGS_ENABLED !== 'false') {
                logger.info('Daily metrics recalculated', {
                    metricDate: metricDate.toISOString().slice(0, 10),
                    totalOrders,
                    completedOrders,
                    cancelledOrders,
                    totalRevenue: totalRevenueNumber,
                    totalCustomers,
                    newCustomers,
                    avgOrderValue,
                    completionRate,
                    avgDeliveryDuration,
                });
            }

            return {
                metric_date: metricDate.toISOString().slice(0, 10),
                total_orders: totalOrders,
                completed_orders: completedOrders,
                cancelled_orders: cancelledOrders,
                total_revenue: totalRevenueNumber,
                total_customers: totalCustomers,
                new_customers: newCustomers,
                avg_order_value: avgOrderValue,
                completion_rate: completionRate,
                avg_delivery_duration: avgDeliveryDuration,
            };
        } catch (error) {
            if (process.env.DAILY_METRICS_LOGS_ENABLED !== 'false') {
                logger.error('Failed to recalculate daily metrics', { error: error?.message || String(error) });
            }
            throw new AppError('Failed to recalculate daily metrics', 500);
        }
    }
}

module.exports = new DailyMetricsService();

