const { Prisma } = require('@prisma/client');
const prisma = require('../config/database');
const logger = require('../utils/logger');
const { AppError } = require('../utils/errors');

const startOfUtcDay = (date) =>
    new Date(Date.UTC(date.getUTCFullYear(), date.getUTCMonth(), date.getUTCDate(), 0, 0, 0));

const addUtcDays = (date, days) => {
    const d = new Date(date);
    d.setUTCDate(d.getUTCDate() + days);
    return d;
};

const startOfUtcMonth = (date) => new Date(Date.UTC(date.getUTCFullYear(), date.getUTCMonth(), 1, 0, 0, 0));

const addUtcMonths = (date, months) => {
    const d = new Date(date);
    d.setUTCMonth(d.getUTCMonth() + months, 1);
    return startOfUtcMonth(d);
};

const toIsoDate = (date) => date.toISOString().slice(0, 10);

const dayLabel = (date) => {
    const labels = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
    return labels[date.getUTCDay()] || '';
};

const pctChange = (current, previous) => {
    const curr = Number.isFinite(current) ? current : 0;
    const prev = Number.isFinite(previous) ? previous : 0;
    if (prev === 0) return curr > 0 ? 100 : 0;
    const change = ((curr - prev) / prev) * 100;
    if (Number.isNaN(change) || !Number.isFinite(change)) return 0;
    return Math.round(change * 10) / 10;
};

class AdminDashboardService {
    /**
     * Revenue breakdown for the Total Revenue popup.
     * Uses delivered orders with bill fallback (aligned with DailyMetrics).
     *
     * Output:
     * - periods: daily/weekly/monthly totals + delta pct vs previous period
     * - trend_last_7_days: 7 points with revenue + orders grouped by delivery completion day (UTC)
     */
    async getRevenueBreakdown(currentTimestamp) {
        try {
            const now = currentTimestamp instanceof Date ? currentTimestamp : new Date(currentTimestamp);
            if (Number.isNaN(now.getTime())) {
                throw new AppError('Invalid timestamp provided', 400);
            }

            const todayStart = startOfUtcDay(now);
            const tomorrowStart = addUtcDays(todayStart, 1);
            const yesterdayStart = addUtcDays(todayStart, -1);

            // Week = last 7 days (including today): [today-6, tomorrow)
            const weekStart = addUtcDays(todayStart, -6);
            const prevWeekStart = addUtcDays(weekStart, -7);
            const prevWeekEnd = addUtcDays(weekStart, 0);

            // Month = current UTC month: [monthStart, nextMonthStart)
            const monthStart = startOfUtcMonth(now);
            const nextMonthStart = addUtcMonths(monthStart, 1);
            const prevMonthStart = addUtcMonths(monthStart, -1);
            const prevMonthEnd = monthStart;

            // NOTE: We treat "revenue" as delivered orders (same as DailyMetrics) and
            // sum COALESCE(bill.final_amount, order.total_amount).
            const getRevenueAndOrders = async (start, end) => {
                const rows = await prisma.$queryRaw`
                    SELECT
                        COALESCE(SUM(COALESCE(b.final_amount, o.total_amount)), 0)::numeric AS revenue,
                        COUNT(*)::int AS orders
                    FROM orders o
                    LEFT JOIN bills b ON b.order_id = o.order_id
                    WHERE o.order_status IN ('delivered')
                      AND o.updated_at >= ${start}
                      AND o.updated_at < ${end}
                `;

                const r0 = rows?.[0] || {};
                const revenue = r0.revenue != null ? Number(new Prisma.Decimal(r0.revenue).toFixed(2)) : 0;
                const orders = r0.orders != null ? Number(r0.orders) : 0;
                return { revenue, orders };
            };

            const [
                daily,
                yesterday,
                weekly,
                prevWeekly,
                monthly,
                prevMonthly,
            ] = await Promise.all([
                getRevenueAndOrders(todayStart, tomorrowStart),
                getRevenueAndOrders(yesterdayStart, todayStart),
                getRevenueAndOrders(weekStart, tomorrowStart),
                getRevenueAndOrders(prevWeekStart, prevWeekEnd),
                getRevenueAndOrders(monthStart, nextMonthStart),
                getRevenueAndOrders(prevMonthStart, prevMonthEnd),
            ]);

            // Trend last 7 days (UTC), grouped by delivered day (updated_at)
            const trendRows = await prisma.$queryRaw`
                SELECT
                    date_trunc('day', o.updated_at) AS day,
                    COALESCE(SUM(COALESCE(b.final_amount, o.total_amount)), 0)::numeric AS revenue,
                    COUNT(*)::int AS orders
                FROM orders o
                LEFT JOIN bills b ON b.order_id = o.order_id
                WHERE o.order_status IN ('delivered')
                  AND o.updated_at >= ${weekStart}
                  AND o.updated_at < ${tomorrowStart}
                GROUP BY day
                ORDER BY day ASC
            `;

            const byDay = new Map();
            (trendRows || []).forEach((r) => {
                const d = r?.day ? new Date(r.day) : null;
                if (!d || Number.isNaN(d.getTime())) return;
                const key = toIsoDate(startOfUtcDay(d));
                byDay.set(key, {
                    revenue: r?.revenue != null ? Number(new Prisma.Decimal(r.revenue).toFixed(2)) : 0,
                    orders: r?.orders != null ? Number(r.orders) : 0,
                });
            });

            const trend_last_7_days = [];
            for (let i = 0; i < 7; i += 1) {
                const d = addUtcDays(weekStart, i);
                const key = toIsoDate(d);
                const entry = byDay.get(key) || { revenue: 0, orders: 0 };
                trend_last_7_days.push({
                    date: key,
                    label: dayLabel(d),
                    revenue: entry.revenue,
                    orders: entry.orders,
                });
            }

            return {
                periods: {
                    daily: {
                        revenue: daily.revenue,
                        delta_pct: pctChange(daily.revenue, yesterday.revenue),
                        compare_to: 'yesterday',
                    },
                    weekly: {
                        revenue: weekly.revenue,
                        delta_pct: pctChange(weekly.revenue, prevWeekly.revenue),
                        compare_to: 'last_week',
                    },
                    monthly: {
                        revenue: monthly.revenue,
                        delta_pct: pctChange(monthly.revenue, prevMonthly.revenue),
                        compare_to: 'last_month',
                    },
                },
                trend_last_7_days,
            };
        } catch (error) {
            logger.error('Error fetching admin revenue breakdown', { error: error?.message || String(error) });
            if (error instanceof AppError) throw error;
            throw new AppError('Failed to fetch revenue breakdown', 500);
        }
    }
}

module.exports = new AdminDashboardService();

