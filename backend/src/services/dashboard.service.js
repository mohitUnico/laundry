const { Prisma } = require('@prisma/client');
const prisma = require('../config/database');
const logger = require('../utils/logger');
const { AppError } = require('../utils/errors');

/**
 * Dashboard Service
 * Handles all dashboard analytics and metrics calculations
 */
class DashboardService {
    /**
     * Get monthly overview metrics for a mart
     * Uses live aggregation from orders + bills (not daily_metrics table).
     * Revenue only counts completed orders (status = 'delivered').
     *
     * @param {string|null} martId - Mart ID (optional for single mart system)
     * @param {Date} currentTimestamp - Current timestamp
     * @returns {Promise<Object>} Monthly overview data
     */
    async getMonthlyOverview(martId, currentTimestamp) {
        try {
            logger.info('Fetching monthly overview', { martId, currentTimestamp });

            const timestamp = new Date(currentTimestamp);
            if (Number.isNaN(timestamp.getTime())) {
                throw new AppError('Invalid timestamp provided', 400);
            }

            // Determine month boundaries
            const year = timestamp.getUTCFullYear();
            const month = timestamp.getUTCMonth();

            const currentMonthStart = new Date(Date.UTC(year, month, 1, 0, 0, 0));
            const nextMonthStart = new Date(Date.UTC(year, month + 1, 1, 0, 0, 0));
            const previousMonthStart = new Date(Date.UTC(year, month - 1, 1, 0, 0, 0));

            // Live aggregation helper: get revenue, orders, new customers, avg delivery time for a date range
            const getLiveMetrics = async (dateStart, dateEnd) => {
                // Revenue: sum of completed orders (delivered) that were completed in this period
                const revenueRow = await prisma.$queryRaw`
                    SELECT
                        COALESCE(SUM(COALESCE(b.final_amount, o.total_amount)), 0)::numeric AS revenue
                    FROM orders o
                    LEFT JOIN bills b ON b.order_id = o.order_id
                    WHERE o.order_status IN ('delivered')
                      AND o.updated_at >= ${dateStart}
                      AND o.updated_at < ${dateEnd}
                `;

                // Total orders: non-draft orders created in this period
                const totalOrders = await prisma.order.count({
                    where: {
                        order_status: { not: 'draft' },
                        created_at: { gte: dateStart, lt: dateEnd },
                    },
                });

                // New customers: customers created in this period
                const newCustomers = await prisma.customer.count({
                    where: {
                        created_at: { gte: dateStart, lt: dateEnd },
                    },
                });

                // Avg delivery time: weighted average from completed drop deliveries in this period
                const deliveries = await prisma.delivery.findMany({
                    where: {
                        delivery_type: 'drop',
                        completed_at: { gte: dateStart, lt: dateEnd },
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

                const avgDeliveryTime =
                    deliveryDurations.length === 0
                        ? 0
                        : Math.round(deliveryDurations.reduce((sum, v) => sum + v, 0) / deliveryDurations.length);

                const revenue = revenueRow?.[0]?.revenue != null ? Number(new Prisma.Decimal(revenueRow[0].revenue).toFixed(2)) : 0;

                return {
                    revenue,
                    totalOrders,
                    newCustomers,
                    avgDeliveryTime,
                };
            };

            // Fetch current and previous month metrics
            const [currentMonth, previousMonth] = await Promise.all([
                getLiveMetrics(currentMonthStart, nextMonthStart),
                getLiveMetrics(previousMonthStart, currentMonthStart),
            ]);

            const calculatePercentageIncrease = (currentValue, previousValue) => {
                if (previousValue === 0) {
                    return currentValue > 0 ? 100 : 0;
                }

                const change = ((currentValue - previousValue) / previousValue) * 100;
                if (Number.isNaN(change)) {
                    return 0;
                }

                return Math.max(0, Math.min(100, Math.round(change)));
            };

            // Calculate percentage increases
            const percentageIncreaseRevenue = calculatePercentageIncrease(
                currentMonth.revenue,
                previousMonth.revenue
            );
            const percentageIncreaseOrders = calculatePercentageIncrease(
                currentMonth.totalOrders,
                previousMonth.totalOrders
            );
            const percentageIncreaseNewCustomers = calculatePercentageIncrease(
                currentMonth.newCustomers,
                previousMonth.newCustomers
            );
            const percentageIncreaseAvgDelivery = calculatePercentageIncrease(
                currentMonth.avgDeliveryTime,
                previousMonth.avgDeliveryTime
            );

            return {
                total_revenue: currentMonth.revenue.toFixed(2),
                percentage_increase_total_revenue: percentageIncreaseRevenue,
                total_orders: currentMonth.totalOrders,
                percentage_increase_total_orders: percentageIncreaseOrders,
                new_customers: currentMonth.newCustomers,
                percentage_increase_new_customers: percentageIncreaseNewCustomers,
                avg_delivery_time: currentMonth.avgDeliveryTime,
                percentage_increase_avg_delivery_time: percentageIncreaseAvgDelivery,
            };
        } catch (error) {
            logger.error('Error fetching monthly overview', error);
            throw new AppError('Failed to fetch monthly overview', 500);
        }
    }

    /**
     * Get day overview metrics for a mart
     * @param {string|null} martId - Mart ID (optional for single mart system)
     * @param {Date} currentTimestamp - Current timestamp
     * @returns {Promise<Object>} Day overview data
     */
    async getDayOverview(martId, currentTimestamp) {
        try {
            logger.info('Fetching day overview', { martId, currentTimestamp });

            const timestamp = new Date(currentTimestamp);
            if (Number.isNaN(timestamp.getTime())) {
                throw new AppError('Invalid timestamp provided', 400);
            }

            const year = timestamp.getUTCFullYear();
            const month = timestamp.getUTCMonth();
            const day = timestamp.getUTCDate();

            const dayStart = new Date(Date.UTC(year, month, day, 0, 0, 0));
            const nextDayStart = new Date(Date.UTC(year, month, day + 1, 0, 0, 0));

            // IMPORTANT:
            // - Pending / In progress / Out for delivery should reflect CURRENT queue (not only "created today"),
            //   otherwise older pending orders show as 0 on dashboard while modals show them correctly.
            // - Completed today should remain day-scoped (delivered today), using updated_at.
            const buildCurrentCountPromise = (statusOrStatuses) =>
                prisma.order.count({
                    where: {
                        ...(martId ? { mart_id: martId } : {}),
                        order_status: Array.isArray(statusOrStatuses)
                            ? { in: statusOrStatuses }
                            : statusOrStatuses,
                    },
                });

            const buildCompletedTodayPromise = () =>
                prisma.order.count({
                    where: {
                        ...(martId ? { mart_id: martId } : {}),
                        order_status: 'delivered',
                        updated_at: {
                            gte: dayStart,
                            lt: nextDayStart,
                        },
                    },
                });

            const [pendingOrders, inProgressOrders, outForDeliveryOrders, completedTodayOrders] = await Promise.all([
                buildCurrentCountPromise([
                    // "Pending" on dashboard should reflect all not-yet-in-service / not-delivered work
                    'placed',
                    'pickup_assigned',
                    'picked_up',
                    'submitted_to_cm',
                    'received_by_collection',
                    'submitted_to_services',
                ]),
                buildCurrentCountPromise('services_in_progress'), // Orders in progress (current)
                buildCurrentCountPromise('out_for_delivery'), // Orders out for delivery (current)
                buildCompletedTodayPromise(), // Completed today
            ]);

            return {
                pending_orders: pendingOrders,
                in_progress: inProgressOrders,
                out_for_delivery: outForDeliveryOrders,
                completed_today: completedTodayOrders,
            };
        } catch (error) {
            logger.error('Error fetching day overview', error);
            throw new AppError('Failed to fetch day overview', 500);
        }
    }

    /**
     * Get revenue trend for a specified time range
     * @param {string|null} martId - Mart ID (optional for single mart system)
     * @param {string} range - Time range (e.g., '7d', '30d', '90d')
     * @param {Date} currentTimestamp - Current timestamp
     * @returns {Promise<Object>} Revenue trend data
     */
    async getRevenueTrend(martId, range, currentTimestamp) {
        try {
            logger.info('Fetching revenue trend', { martId, range, currentTimestamp });

            const timestamp = new Date(currentTimestamp);
            if (Number.isNaN(timestamp.getTime())) {
                throw new AppError('Invalid timestamp provided', 400);
            }

            const startOfDayUTC = (date) =>
                new Date(Date.UTC(date.getUTCFullYear(), date.getUTCMonth(), date.getUTCDate(), 0, 0, 0));

            const addDays = (date, days) => {
                const result = new Date(date);
                result.setUTCDate(result.getUTCDate() + days);
                return result;
            };

            const startOfWeekUTC = (date) => {
                const start = startOfDayUTC(date);
                const day = start.getUTCDay();
                const diff = day === 0 ? -6 : 1 - day; // ISO week (Monday start)
                return addDays(start, diff);
            };

            const startOfMonthUTC = (date) =>
                new Date(Date.UTC(date.getUTCFullYear(), date.getUTCMonth(), 1, 0, 0, 0));

            const addMonths = (date, months) => {
                const result = new Date(date);
                result.setUTCMonth(result.getUTCMonth() + months, 1);
                return startOfMonthUTC(result);
            };

            const formatDateLabel = (date) => date.toISOString().slice(0, 10);

            const formatMonthLabel = (date) =>
                `${date.getUTCFullYear()}-${String(date.getUTCMonth() + 1).padStart(2, '0')}`;

            const getISOWeekNumber = (date) => {
                const temp = new Date(Date.UTC(date.getUTCFullYear(), date.getUTCMonth(), date.getUTCDate()));
                const dayNumber = temp.getUTCDay() || 7;
                temp.setUTCDate(temp.getUTCDate() + 4 - dayNumber);
                const yearStart = new Date(Date.UTC(temp.getUTCFullYear(), 0, 1));
                return Math.ceil(((temp - yearStart) / 86400000 + 1) / 7);
            };

            const formatWeekLabel = (date) => {
                const week = getISOWeekNumber(date);
                return `${date.getUTCFullYear()}-W${String(week).padStart(2, '0')}`;
            };

            const configs = {
                '7days': {
                    periods: 7,
                    getCurrentStart: (date) => startOfDayUTC(date),
                    buildPeriod: (currentStart, index) => {
                        const start = addDays(currentStart, -index);
                        const end = addDays(start, 1);
                        const label = formatDateLabel(start);
                        return { start, end, label, key: label };
                    },
                    getKeyFromDate: (date) => formatDateLabel(startOfDayUTC(date)),
                },
                '7weeks': {
                    periods: 7,
                    getCurrentStart: (date) => startOfWeekUTC(date),
                    buildPeriod: (currentStart, index) => {
                        const start = addDays(currentStart, -7 * index);
                        const end = addDays(start, 7);
                        const label = formatWeekLabel(start);
                        return { start, end, label, key: label };
                    },
                    getKeyFromDate: (date) => formatWeekLabel(startOfWeekUTC(date)),
                },
                '7months': {
                    periods: 7,
                    getCurrentStart: (date) => startOfMonthUTC(date),
                    buildPeriod: (currentStart, index) => {
                        const start = addMonths(currentStart, -index);
                        const end = addMonths(start, 1);
                        const label = formatMonthLabel(start);
                        return { start, end, label, key: label };
                    },
                    getKeyFromDate: (date) => formatMonthLabel(startOfMonthUTC(date)),
                },
            };

            const normalizedRange = configs[range] ? range : '7days';
            const config = configs[normalizedRange];

            const currentPeriodStart = config.getCurrentStart(timestamp);
            const periods = [];
            for (let i = config.periods - 1; i >= 0; i -= 1) {
                periods.push(config.buildPeriod(currentPeriodStart, i));
            }

            const rangeStart = periods[0].start;
            const rangeEnd = periods[periods.length - 1].end;

            // Live aggregation: fetch all completed orders in range, then group by period
            // Revenue only counts orders with status = 'delivered'
            const completedOrders = await prisma.order.findMany({
                where: {
                    order_status: 'delivered',
                    updated_at: { gte: rangeStart, lt: rangeEnd },
                },
                select: {
                    updated_at: true,
                    total_amount: true,
                    bill: {
                        select: {
                            final_amount: true,
                        },
                    },
                },
            });

            // Initialize period map with zeros
            const periodMap = new Map();
            periods.forEach((period) => {
                periodMap.set(period.key, {
                    label: period.label,
                    start: period.start,
                    end: period.end,
                    totalRevenue: new Prisma.Decimal(0),
                    totalOrders: 0,
                });
            });

            // Group completed orders into periods
            completedOrders.forEach((order) => {
                const updatedAt = new Date(order.updated_at);
                if (Number.isNaN(updatedAt.getTime())) return;

                // Determine which period this order belongs to
                const key = config.getKeyFromDate(updatedAt);
                const periodEntry = periodMap.get(key);
                if (periodEntry) {
                    // Revenue: use bill.final_amount if available, else order.total_amount
                    const revenue = order.bill?.final_amount != null
                        ? new Prisma.Decimal(order.bill.final_amount)
                        : (order.total_amount != null ? new Prisma.Decimal(order.total_amount) : new Prisma.Decimal(0));
                    periodEntry.totalRevenue = periodEntry.totalRevenue.add(revenue);
                    periodEntry.totalOrders += 1;
                }
            });

            const data = Array.from(periodMap.values()).map((period) => {
                const totalRevenue = parseFloat(period.totalRevenue.toFixed(2));
                const totalOrders = period.totalOrders;
                const avgOrderValue = totalOrders > 0 ? parseFloat((totalRevenue / totalOrders).toFixed(2)) : 0;

                return {
                    label: period.label,
                    total_revenue: totalRevenue,
                    total_orders: totalOrders,
                    avg_order_value: avgOrderValue,
                };
            });

            const totals = data.reduce(
                (acc, item) => {
                    acc.totalRevenue = acc.totalRevenue.add(new Prisma.Decimal(item.total_revenue));
                    acc.totalOrders += item.total_orders;
                    return acc;
                },
                { totalRevenue: new Prisma.Decimal(0), totalOrders: 0 }
            );

            const totalRevenueValue = parseFloat(totals.totalRevenue.toFixed(2));
            const totalOrdersValue = totals.totalOrders;
            const avgOrderValue = totalOrdersValue > 0 ? parseFloat((totalRevenueValue / totalOrdersValue).toFixed(2)) : 0;

            return {
                range: normalizedRange,
                start_date: rangeStart.toISOString(),
                end_date: rangeEnd.toISOString(),
                total_revenue: totalRevenueValue,
                total_orders: totalOrdersValue,
                avg_order_value: avgOrderValue,
                data,
            };
        } catch (error) {
            logger.error('Error fetching revenue trend', error);
            throw new AppError('Failed to fetch revenue trend', 500);
        }
    }

    /**
     * Get recent orders for a mart
     * @param {string|null} martId - Mart ID (optional for single mart system)
     * @param {number} limit - Number of orders to fetch
     * @param {Date} currentTimestamp - Current timestamp
     * @returns {Promise<Object>} Recent orders data
     */
    async getRecentOrders(martId, limit, currentTimestamp) {
        try {
            logger.info('Fetching recent orders', { martId, limit, currentTimestamp });

            const orderLimit = Number.isFinite(limit) && limit > 0 ? Math.min(limit, 100) : 5;

            const orders = await prisma.order.findMany({
                where: {
                    ...(martId ? { mart_id: martId } : {}),
                },
                orderBy: {
                    created_at: 'desc',
                },
                take: orderLimit,
                select: {
                    order_id: true,
                    total_amount: true,
                    order_status: true,
                    created_at: true,
                    customer: {
                        select: {
                            full_name: true,
                        },
                    },
                },
            });

            const data = orders.map((order) => ({
                order_id: order.order_id,
                customer_name: order.customer?.full_name || 'Unknown Customer',
                order_price: order.total_amount ? parseFloat(order.total_amount.toFixed(2)) : 0,
                status: order.order_status,
                duration_ago: order.created_at.toISOString(),
            }));

            return {
                ...(martId ? { mart_id: martId } : {}),
                count: data.length,
                data,
            };
        } catch (error) {
            logger.error('Error fetching recent orders', error);
            throw new AppError('Failed to fetch recent orders', 500);
        }
    }

    /**
     * Get customer satisfaction metrics for a mart
     * @param {string|null} martId - Mart ID (optional for single mart system)
     * @param {Date} currentTimestamp - Current timestamp
     * @returns {Promise<Object>} Customer satisfaction data
     */
    async getCustomerSatisfaction(martId, currentTimestamp) {
        try {
            logger.info('Fetching customer satisfaction', { martId, currentTimestamp });

            // Fetch all customer ratings from orders (single mart system - no mart_id filter)
            const orders = await prisma.order.findMany({
                where: {
                    customer_rating: {
                        not: null,
                    },
                },
                select: {
                    customer_rating: true,
                },
            });

            // Convert ratings to numbers for comparison
            const ratings = orders
                .map((order) => (order.customer_rating ? parseFloat(order.customer_rating) : null))
                .filter((rating) => rating !== null && rating > 0);

            const totalRatings = ratings.length;

            if (totalRatings === 0) {
                return {
                    percentage: 0,
                    count_of_5_stars: 0,
                    count_of_4_stars: 0,
                    count_of_less_than_3_stars: 0,
                };
            }

            // Calculate counts for each category
            const countOf5Stars = ratings.filter((rating) => rating >= 4.5 && rating <= 5.0).length;
            const countOf4Stars = ratings.filter((rating) => rating >= 4.0 && rating < 4.5).length;
            const countOfLessThan3Stars = ratings.filter((rating) => rating < 3.0).length;

            // Calculate overall percentage: average rating out of 5, then convert to percentage
            const sumRatings = ratings.reduce((sum, rating) => sum + rating, 0);
            const averageRating = sumRatings / totalRatings;
            const percentage = parseFloat(((averageRating / 5) * 100).toFixed(2));

            return {
                percentage,
                count_of_5_stars: countOf5Stars,
                count_of_4_stars: countOf4Stars,
                count_of_less_than_3_stars: countOfLessThan3Stars,
            };
        } catch (error) {
            logger.error('Error fetching customer satisfaction', error);
            throw new AppError('Failed to fetch customer satisfaction', 500);
        }
    }

    /**
     * Get top performing delivery staff for a mart
     * @param {string|null} martId - Mart ID (optional for single mart system)
     * @param {number} limit - Number of top performers to fetch
     * @param {Date} currentTimestamp - Current timestamp
     * @returns {Promise<Object>} Top performers data
     */
    async getTopPerformers(martId, limit, currentTimestamp) {
        try {
            logger.info('Fetching top performers', { martId, limit, currentTimestamp });

            const performerLimit = Number.isFinite(limit) && limit > 0 ? Math.min(limit, 50) : 5;

            // Fetch delivery staff sorted by total_deliveries (desc), then by average_rating (desc)
            const deliveryStaff = await prisma.deliveryStaff.findMany({
                where: {
                    ...(martId ? { mart_id: martId } : {}),
                    is_active: true,
                },
                orderBy: [
                    {
                        total_deliveries: 'desc',
                    },
                    {
                        average_rating: 'desc',
                    },
                ],
                take: performerLimit,
                select: {
                    full_name: true,
                    total_deliveries: true,
                    average_rating: true,
                },
            });

            // Format response
            const topPerformers = deliveryStaff.map((staff) => ({
                delivery_staff_name: staff.full_name,
                total_deliveries: staff.total_deliveries || 0,
                overall_rating: staff.average_rating
                    ? parseFloat(staff.average_rating.toFixed(2))
                    : 0,
            }));

            return {
                top_performers: topPerformers,
            };
        } catch (error) {
            logger.error('Error fetching top performers', error);
            throw new AppError('Failed to fetch top performers', 500);
        }
    }
}

module.exports = new DashboardService();

