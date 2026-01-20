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

            // Build where clause for date range (single mart system - no mart_id filter)
            const whereClause = (dateStart, dateEnd) => ({
                metric_date: {
                    gte: dateStart,
                    lt: dateEnd,
                },
            });

            // Fetch current and previous month metrics
            const [currentMonthMetrics, previousMonthMetrics] = await Promise.all([
                prisma.dailyMetrics.findMany({
                    where: whereClause(currentMonthStart, nextMonthStart),
                }),
                prisma.dailyMetrics.findMany({
                    where: whereClause(previousMonthStart, currentMonthStart),
                }),
            ]);

            // Helper functions
            const sumDecimal = (records, key) =>
                records.reduce(
                    (acc, record) => acc.add(record[key] ? new Prisma.Decimal(record[key]) : new Prisma.Decimal(0)),
                    new Prisma.Decimal(0)
                );

            const sumInt = (records, key) =>
                records.reduce((acc, record) => acc + (record[key] || 0), 0);

            const calculateWeightedAverage = (records, valueKey, weightKey) => {
                const totalWeight = sumInt(records, weightKey);
                if (totalWeight === 0) {
                    return 0;
                }

                const weightedSum = records.reduce((acc, record) => {
                    const value = record[valueKey] || 0;
                    const weight = record[weightKey] || 0;
                    return acc + value * weight;
                }, 0);

                return Math.round(weightedSum / totalWeight);
            };

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

            // Current month calculations
            const currentTotalRevenue = sumDecimal(currentMonthMetrics, 'total_revenue');
            const currentTotalOrders = sumInt(currentMonthMetrics, 'total_orders');
            const currentNewCustomers = sumInt(currentMonthMetrics, 'new_customers');
            const currentAvgDeliveryTime = calculateWeightedAverage(
                currentMonthMetrics,
                'avg_delivery_duration',
                'total_orders'
            );

            // Previous month calculations
            const previousTotalRevenue = sumDecimal(previousMonthMetrics, 'total_revenue');
            const previousTotalOrders = sumInt(previousMonthMetrics, 'total_orders');
            const previousNewCustomers = sumInt(previousMonthMetrics, 'new_customers');
            const previousAvgDeliveryTime = calculateWeightedAverage(
                previousMonthMetrics,
                'avg_delivery_duration',
                'total_orders'
            );

            // Convert decimals to strings for output
            const totalRevenueValue = currentTotalRevenue.toFixed(2);
            const previousRevenueValue = parseFloat(previousTotalRevenue.toFixed(2));
            const currentRevenueValue = parseFloat(totalRevenueValue);

            // Calculate percentage increases
            const percentageIncreaseRevenue = calculatePercentageIncrease(
                currentRevenueValue,
                previousRevenueValue
            );
            const percentageIncreaseOrders = calculatePercentageIncrease(
                currentTotalOrders,
                previousTotalOrders
            );
            const percentageIncreaseNewCustomers = calculatePercentageIncrease(
                currentNewCustomers,
                previousNewCustomers
            );
            const percentageIncreaseAvgDelivery = calculatePercentageIncrease(
                currentAvgDeliveryTime,
                previousAvgDeliveryTime
            );

            return {
                total_revenue: totalRevenueValue,
                percentage_increase_total_revenue: percentageIncreaseRevenue,
                total_orders: currentTotalOrders,
                percentage_increase_total_orders: percentageIncreaseOrders,
                new_customers: currentNewCustomers,
                percentage_increase_new_customers: percentageIncreaseNewCustomers,
                avg_delivery_time: currentAvgDeliveryTime,
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

            const buildCountPromise = (status) =>
                prisma.order.count({
                    where: {
                        ...(martId ? { mart_id: martId } : {}),
                        order_status: status,
                        created_at: {
                            gte: dayStart,
                            lt: nextDayStart,
                        },
                    },
                });

            const [pendingOrders, inProgressOrders, outForDeliveryOrders, completedTodayOrders] = await Promise.all([
                buildCountPromise('placed'), // Pending orders (placed but not yet picked up)
                buildCountPromise('services_in_progress'), // Orders in progress
                buildCountPromise('out_for_delivery'), // Orders out for delivery
                buildCountPromise('delivered'), // Completed today
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

            const metrics = await prisma.dailyMetrics.findMany({
                where: {
                    metric_date: {
                        gte: rangeStart,
                        lt: rangeEnd,
                    },
                },
            });

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

            metrics.forEach((metric) => {
                const metricDate = new Date(metric.metric_date);
                const key = config.getKeyFromDate(metricDate);
                const periodEntry = periodMap.get(key);
                if (periodEntry) {
                    const revenue = metric.total_revenue
                        ? new Prisma.Decimal(metric.total_revenue)
                        : new Prisma.Decimal(0);
                    periodEntry.totalRevenue = periodEntry.totalRevenue.add(revenue);
                    periodEntry.totalOrders += metric.total_orders || 0;
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

