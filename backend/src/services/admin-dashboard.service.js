const prisma = require('../config/database');
const logger = require('../utils/logger');
const { ValidationError } = require('../utils/errors');
const { Prisma } = require('@prisma/client');

const parseIsoDate = (value, fieldName) => {
    if (!value) return null;
    const d = new Date(value);
    if (Number.isNaN(d.getTime())) {
        throw new ValidationError(`${fieldName} must be a valid ISO date`);
    }
    return d;
};

const getUtcDayRange = (dateInput) => {
    const date = dateInput ? new Date(dateInput) : new Date();
    if (Number.isNaN(date.getTime())) {
        throw new ValidationError('Invalid date');
    }
    const start = new Date(Date.UTC(date.getUTCFullYear(), date.getUTCMonth(), date.getUTCDate(), 0, 0, 0));
    const end = new Date(Date.UTC(date.getUTCFullYear(), date.getUTCMonth(), date.getUTCDate() + 1, 0, 0, 0));
    return { start, end };
};

const clampLimit = (value, { min = 1, max = 100, fallback = 10 } = {}) => {
    const parsed = Number.isInteger(value) ? value : parseInt(value);
    if (!Number.isFinite(parsed)) return fallback;
    return Math.max(min, Math.min(max, parsed));
};

const buildWhereSql = ({ from, to }) => {
    const clauses = [];
    if (from) clauses.push(Prisma.sql`o.created_at >= ${from}`);
    if (to) clauses.push(Prisma.sql`o.created_at <= ${to}`);
    if (clauses.length === 0) return Prisma.sql``;
    return Prisma.sql`WHERE ${Prisma.join(clauses, Prisma.sql` AND `)}`;
};

const minutesBetween = (a, b) => Math.round((a.getTime() - b.getTime()) / (60 * 1000));

const getUtcDayStart = (date) =>
    new Date(Date.UTC(date.getUTCFullYear(), date.getUTCMonth(), date.getUTCDate(), 0, 0, 0));

exports.getDashboardSummary = async (query = {}) => {
    const from = parseIsoDate(query.from, 'from');
    const to = parseIsoDate(query.to, 'to');

    logger.info('Admin dashboard summary query', { from: from?.toISOString?.() || null, to: to?.toISOString?.() || null });

    // Use a fully parameterized predicate to avoid dynamic SQL fragment injection.
    // This prevents any chance of `[object Object]` appearing in the SQL.
    const rows = await prisma.$queryRaw`
        SELECT
            COALESCE(SUM(COALESCE(b.final_amount, o.total_amount)), 0) AS total_revenue,
            COUNT(o.order_id)::int AS total_orders,
            COALESCE(AVG(COALESCE(d.actual_duration, d.estimated_duration)), 0) AS avg_delivery_time
        FROM orders o
        LEFT JOIN bills b ON b.order_id = o.order_id
        LEFT JOIN delivery d ON d.order_id = o.order_id
        WHERE
            (${from}::timestamptz IS NULL OR o.created_at >= ${from})
            AND (${to}::timestamptz IS NULL OR o.created_at <= ${to})
    `;

    const newCustomersWhere = {
        ...(from || to
            ? {
                  created_at: {
                      ...(from ? { gte: from } : {}),
                      ...(to ? { lte: to } : {}),
                  },
              }
            : {}),
    };

    const newCustomers = await prisma.customer.count({ where: newCustomersWhere });

    const totalRevenue = rows?.[0]?.total_revenue ?? 0;
    const totalOrders = rows?.[0]?.total_orders ?? 0;
    const averageDeliveryTime = rows?.[0]?.avg_delivery_time ?? 0;

    return {
        totalRevenue: Number(totalRevenue) || 0,
        totalOrders: Number(totalOrders) || 0,
        newCustomers,
        averageDeliveryTime: Math.round(Number(averageDeliveryTime) || 0),
    };
};

exports.getOrderStatusBreakdown = async (query = {}) => {
    const { start, end } = getUtcDayRange(query.date);

    // NOTE: Use raw SQL to avoid Prisma enum deserialization issues (e.g., DB has 'draft').
    const rows = await prisma.$queryRaw`
        SELECT
            COUNT(*) FILTER (
                WHERE o.order_status IN (
                    'draft',
                    'placed',
                    'pickup_assigned',
                    'picked_up',
                    'received_by_collection',
                    'submitted_to_services'
                )
            )::int AS pending,
            COUNT(*) FILTER (WHERE o.order_status = 'services_in_progress')::int AS in_progress,
            COUNT(*) FILTER (WHERE o.order_status = 'out_for_delivery')::int AS out_for_delivery,
            COUNT(*) FILTER (
                WHERE o.order_status IN ('delivered', 'closed')
                  AND o.updated_at >= ${start}
                  AND o.updated_at < ${end}
            )::int AS completed_today
        FROM orders o
    `;

    return {
        pending: rows?.[0]?.pending ?? 0,
        inProgress: rows?.[0]?.in_progress ?? 0,
        outForDelivery: rows?.[0]?.out_for_delivery ?? 0,
        completedToday: rows?.[0]?.completed_today ?? 0,
    };
};

exports.getRevenueTrend = async (query = {}) => {
    const range = typeof query.range === 'string' ? query.range.trim() : '7d';
    const days = range === '30d' ? 30 : 7;

    const now = new Date();
    const start = new Date(now.getTime() - days * 24 * 60 * 60 * 1000);

    const rows = await prisma.$queryRaw`
        SELECT
            (date_trunc('day', o.created_at))::date AS date,
            COALESCE(SUM(COALESCE(b.final_amount, o.total_amount)), 0) AS total_revenue,
            COUNT(o.order_id)::int AS total_orders,
            COALESCE(AVG(COALESCE(b.final_amount, o.total_amount)), 0) AS avg_order_value
        FROM orders o
        LEFT JOIN bills b ON b.order_id = o.order_id
        WHERE o.created_at >= ${start} AND o.created_at <= ${now}
        GROUP BY 1
        ORDER BY 1 ASC
    `;

    return (rows || []).map((r) => ({
        date: r.date ? new Date(r.date).toISOString().slice(0, 10) : null,
        totalRevenue: Number(r.total_revenue) || 0,
        totalOrders: Number(r.total_orders) || 0,
        averageOrderValue: Number(r.avg_order_value) || 0,
    }));
};

exports.getRecentOrders = async (query = {}) => {
    const limit = clampLimit(query.limit, { min: 1, max: 50, fallback: 10 });
    const now = new Date();

    // Raw SQL: returns order_status as text (safe even if DB has unexpected enum values).
    const rows = await prisma.$queryRaw`
        SELECT
            o.order_id,
            o.order_status,
            o.created_at,
            c.full_name AS customer_name,
            COALESCE(b.final_amount, o.total_amount) AS amount,
            ds.full_name AS delivery_staff_name
        FROM orders o
        JOIN customers c ON c.customer_id = o.customer_id
        LEFT JOIN bills b ON b.order_id = o.order_id
        LEFT JOIN delivery d ON d.order_id = o.order_id
        LEFT JOIN delivery_staffs ds ON ds.staff_id = d.staff_id
        ORDER BY o.created_at DESC
        LIMIT ${limit}
    `;

    return (rows || []).map((r) => {
        const createdAt = r.created_at ? new Date(r.created_at) : null;
        const elapsedSeconds = createdAt ? Math.max(0, Math.floor((now.getTime() - createdAt.getTime()) / 1000)) : null;

        return {
            orderNumber: r.order_id,
            customerName: r.customer_name || null,
            amount: r.amount?.toString?.() ?? r.amount,
            status: r.order_status || null,
            deliveryStaffName: r.delivery_staff_name || null,
            timeElapsedSeconds: elapsedSeconds,
            createdAt: createdAt ? createdAt.toISOString() : null,
        };
    });
};

exports.getTopPerformers = async (query = {}) => {
    const limit = clampLimit(query.limit, { min: 1, max: 50, fallback: 5 });

    const staff = await prisma.deliveryStaff.findMany({
        where: { is_active: true },
        orderBy: [{ total_deliveries: 'desc' }, { average_rating: 'desc' }],
        take: limit,
        select: {
            full_name: true,
            total_deliveries: true,
            average_rating: true,
        },
    });

    return staff.map((s) => ({
        deliveryStaffName: s.full_name,
        totalDeliveries: s.total_deliveries || 0,
        rating: s.average_rating ? Number(s.average_rating.toFixed(2)) : 0,
    }));
};

exports.getCustomerSatisfaction = async () => {
    // NOTE: Some environments have schema drift where orders.customer_rating doesn't exist yet.
    // To avoid crashing the dashboard, detect column existence first and fallback to zeros.
    const col = await prisma.$queryRaw`
        SELECT EXISTS (
            SELECT 1
            FROM information_schema.columns
            WHERE table_schema = 'public'
              AND table_name = 'orders'
              AND column_name = 'customer_rating'
        ) AS exists
    `;

    const hasCustomerRating = Boolean(col?.[0]?.exists);
    if (!hasCustomerRating) {
        return {
            overallPercentage: 0,
            distribution: { fiveStar: 0, fourStar: 0, lessThanThree: 0 },
        };
    }

    // Raw SQL: avoids Prisma enum deserialization issues and only reads the rating column.
    const rows = await prisma.$queryRaw`
        SELECT customer_rating
        FROM orders
        WHERE customer_rating IS NOT NULL
    `;

    const values = (rows || [])
        .map((r) => (r.customer_rating !== null && r.customer_rating !== undefined ? Number(r.customer_rating) : null))
        .filter((v) => typeof v === 'number' && Number.isFinite(v));

    const total = values.length;
    if (total === 0) {
        return {
            overallPercentage: 0,
            distribution: { fiveStar: 0, fourStar: 0, lessThanThree: 0 },
        };
    }

    const five = values.filter((v) => v >= 5).length;
    const four = values.filter((v) => v >= 4 && v < 5).length;
    const overall = values.filter((v) => v >= 4).length;
    const lt3 = values.filter((v) => v <= 3).length;

    const pct = (count) => Number(((count / total) * 100).toFixed(2));

    return {
        overallPercentage: pct(overall),
        distribution: {
            fiveStar: pct(five),
            fourStar: pct(four),
            lessThanThree: pct(lt3),
        },
    };
};

exports.getDeliveryAnalytics = async (query = {}) => {
    const limit = clampLimit(query.limit, { min: 1, max: 50, fallback: 10 });
    const now = new Date();

    const todayStart = getUtcDayStart(now);
    const yesterdayStart = new Date(todayStart.getTime() - 24 * 60 * 60 * 1000);

    const weekStart = new Date(now.getTime() - 7 * 24 * 60 * 60 * 1000);
    const prevWeekStart = new Date(now.getTime() - 14 * 24 * 60 * 60 * 1000);

    const monthStart = new Date(now.getTime() - 30 * 24 * 60 * 60 * 1000);
    const prevMonthStart = new Date(now.getTime() - 60 * 24 * 60 * 60 * 1000);

    const avgDuration = async (from, to) => {
        const rows = await prisma.$queryRaw`
            SELECT
                COALESCE(AVG(COALESCE(d.actual_duration, d.estimated_duration)), 0) AS avg_minutes
            FROM delivery d
            WHERE d.delivery_type = 'drop'
              AND d.completed_at IS NOT NULL
              AND d.completed_at >= ${from}
              AND d.completed_at < ${to}
        `;
        return Math.round(Number(rows?.[0]?.avg_minutes) || 0);
    };

    const [todayAvg, yesterdayAvg, weekAvg, prevWeekAvg, monthAvg, prevMonthAvg] = await Promise.all([
        avgDuration(todayStart, now),
        avgDuration(yesterdayStart, todayStart),
        avgDuration(weekStart, now),
        avgDuration(prevWeekStart, weekStart),
        avgDuration(monthStart, now),
        avgDuration(prevMonthStart, monthStart),
    ]);

    const recentRows = await prisma.$queryRaw`
        SELECT
            o.order_id,
            c.full_name AS customer_name,
            d.actual_duration,
            d.estimated_duration,
            d.completed_at
        FROM delivery d
        JOIN orders o ON o.order_id = d.order_id
        JOIN customers c ON c.customer_id = o.customer_id
        WHERE d.delivery_type = 'drop'
          AND d.completed_at IS NOT NULL
        ORDER BY d.completed_at DESC
        LIMIT ${limit}
    `;

    const recentDeliveries = (recentRows || []).map((r) => {
        const actual = r.actual_duration !== null && r.actual_duration !== undefined ? Number(r.actual_duration) : null;
        const estimated = r.estimated_duration !== null && r.estimated_duration !== undefined ? Number(r.estimated_duration) : null;

        let status = 'On Time';
        if (actual !== null && estimated !== null) {
            if (actual > estimated) status = 'Delayed';
            else if (actual < estimated) status = 'Early';
        }

        return {
            orderId: r.order_id,
            customerName: r.customer_name || null,
            durationMinutes: actual ?? estimated ?? null,
            status,
            completedAt: r.completed_at ? new Date(r.completed_at).toISOString() : null,
        };
    });

    return {
        metrics: {
            todayAvgMinutes: todayAvg,
            todayDeltaMinutes: todayAvg - yesterdayAvg,
            weekAvgMinutes: weekAvg,
            weekDeltaMinutes: weekAvg - prevWeekAvg,
            monthAvgMinutes: monthAvg,
            monthDeltaMinutes: monthAvg - prevMonthAvg,
        },
        recentDeliveries,
    };
};

exports.getLateDeliveries = async (query = {}) => {
    const limit = clampLimit(query.limit, { min: 1, max: 50, fallback: 1 });
    const now = new Date();

    const where = {
        order_status: 'out_for_delivery',
        delivery_date: { lt: now },
    };

    const [totalLate, orders] = await Promise.all([
        prisma.order.count({ where }),
        prisma.order.findMany({
            where,
            orderBy: { delivery_date: 'asc' }, // oldest scheduled first (most likely late)
            take: limit,
            select: {
                order_id: true,
                order_status: true,
                total_amount: true,
                delivery_date: true,
                created_at: true,
                customer: {
                    select: {
                        full_name: true,
                        email: true,
                        phone: true,
                    },
                },
                pickup_address: {
                    select: {
                        full_address: true,
                        address_label: true,
                    },
                },
                delivery_address: {
                    select: {
                        full_address: true,
                        address_label: true,
                    },
                },
                delivery: {
                    select: {
                        delivery_id: true,
                        delivery_status: true,
                        staff: {
                            select: {
                                full_name: true,
                                phone: true,
                                vehicle_number: true,
                            },
                        },
                    },
                },
            },
        }),
    ]);

    const items = orders.map((o) => {
        const scheduled = o.delivery_date ? new Date(o.delivery_date) : null;
        const delayMinutes = scheduled ? Math.max(0, minutesBetween(now, scheduled)) : null;

        return {
            orderId: o.order_id,
            customerName: o.customer?.full_name || null,
            customerEmail: o.customer?.email || null,
            customerPhone: o.customer?.phone || null,
            orderValue: o.total_amount?.toString?.() ?? o.total_amount,
            scheduledTime: scheduled ? scheduled.toISOString() : null,
            currentStatus: o.order_status || null,
            delayMinutes,
            pickupAddress: o.pickup_address
                ? {
                      label: o.pickup_address.address_label,
                      fullAddress: o.pickup_address.full_address,
                  }
                : null,
            deliveryAddress: o.delivery_address
                ? {
                      label: o.delivery_address.address_label,
                      fullAddress: o.delivery_address.full_address,
                  }
                : null,
            deliveryPartner: o.delivery?.staff
                ? {
                      name: o.delivery.staff.full_name,
                      phone: o.delivery.staff.phone || null,
                      vehicleNumber: o.delivery.staff.vehicle_number || null,
                      deliveryStatus: o.delivery.delivery_status || null,
                  }
                : null,
        };
    });

    return {
        count: totalLate,
        lateDeliveries: items,
    };
};

module.exports = exports;


