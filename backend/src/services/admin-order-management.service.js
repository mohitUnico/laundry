const prisma = require('../config/database');
const logger = require('../utils/logger');
const { ValidationError } = require('../utils/errors');
const { Prisma } = require('@prisma/client');

const ORDER_STATUSES = [
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
    'cancelled',
];

const normalizeStatusFilter = (status) => {
    if (!status) return null;

    if (typeof status !== 'string') {
        throw new ValidationError('status must be a string');
    }

    const parts = status
        .split(',')
        .map((s) => s.trim())
        .filter(Boolean);

    if (parts.length === 0) return null;

    const invalid = parts.filter((s) => !ORDER_STATUSES.includes(s));
    if (invalid.length > 0) {
        throw new ValidationError(`Invalid status filter: ${invalid.join(', ')}`);
    }

    return parts;
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

const buildCreatedAtWhere = (from, to) => {
    if (!from && !to) return null;

    const created_at = {};
    if (from) {
        const fromDate = new Date(from);
        if (Number.isNaN(fromDate.getTime())) throw new ValidationError('from must be a valid ISO date');
        created_at.gte = fromDate;
    }
    if (to) {
        const toDate = new Date(to);
        if (Number.isNaN(toDate.getTime())) throw new ValidationError('to must be a valid ISO date');
        created_at.lte = toDate;
    }

    return created_at;
};

const isOrderStatusEnumMismatchError = (error) => {
    const msg = String(error?.message || '');
    return msg.includes("not found in enum 'OrderStatus'") || msg.includes('not found in enum "OrderStatus"');
};

const buildRawWhereClause = ({ statusList, from, to }) => {
    const clauses = [];

    if (Array.isArray(statusList) && statusList.length > 0) {
        clauses.push(Prisma.sql`o.order_status IN (${Prisma.join(statusList)})`);
    }

    if (from) {
        clauses.push(Prisma.sql`o.created_at >= ${new Date(from)}`);
    }

    if (to) {
        clauses.push(Prisma.sql`o.created_at <= ${new Date(to)}`);
    }

    if (clauses.length === 0) {
        return Prisma.sql``;
    }

    return Prisma.sql`WHERE ${Prisma.join(clauses, Prisma.sql` AND `)}`;
};

const getAdminOrdersRaw = async ({ statusList, from, to, skip, take }) => {
    const whereSql = buildRawWhereClause({ statusList, from, to });

    const countRows = await prisma.$queryRaw`
        SELECT COUNT(*)::int AS total
        FROM orders o
        ${whereSql}
    `;

    const total = countRows?.[0]?.total ?? 0;

    const rows = await prisma.$queryRaw`
        SELECT
            o.order_id,
            o.order_status,
            o.total_amount,
            o.created_at,
            o.delivery_date,
            c.customer_id,
            c.full_name AS customer_name,
            a.address_id,
            a.address_label,
            a.full_address,
            a.latitude,
            a.longitude,
            b.final_amount,
            b.payment_status,
            d.delivery_id,
            d.delivery_status,
            d.estimated_duration,
            ds.staff_id AS delivery_staff_id,
            ds.full_name AS delivery_staff_name,
            ds.phone AS delivery_staff_phone,
            COALESCE(
                ARRAY_AGG(DISTINCT s.service_name) FILTER (WHERE s.service_name IS NOT NULL),
                ARRAY[]::text[]
            ) AS services
        FROM orders o
        JOIN customers c ON c.customer_id = o.customer_id
        LEFT JOIN customer_addresses a ON a.address_id = o.delivery_address_id
        LEFT JOIN bills b ON b.order_id = o.order_id
        LEFT JOIN delivery d ON d.order_id = o.order_id
        LEFT JOIN delivery_staffs ds ON ds.staff_id = d.staff_id
        LEFT JOIN order_items oi ON oi.order_id = o.order_id
        LEFT JOIN clothes_items ci ON ci.cloth_id = oi.clothes_id
        LEFT JOIN services s ON s.service_id = ci.service_id
        ${whereSql}
        GROUP BY
            o.order_id,
            o.order_status,
            o.total_amount,
            o.created_at,
            o.delivery_date,
            c.customer_id,
            c.full_name,
            a.address_id,
            a.address_label,
            a.full_address,
            a.latitude,
            a.longitude,
            b.final_amount,
            b.payment_status,
            d.delivery_id,
            d.delivery_status,
            d.estimated_duration,
            ds.staff_id,
            ds.full_name,
            ds.phone
        ORDER BY o.created_at DESC
        LIMIT ${take} OFFSET ${skip}
    `;

    const orders = (rows || []).map((r) => ({
        order_number: r.order_id,
        customer: {
            customer_id: r.customer_id || null,
            name: r.customer_name || null,
            address: r.address_id
                ? {
                    address_id: r.address_id,
                    label: r.address_label,
                    full_address: r.full_address,
                    latitude: r.latitude,
                    longitude: r.longitude,
                }
                : null,
        },
        services: Array.isArray(r.services) ? r.services.filter(Boolean) : [],
        amount: (r.final_amount ?? r.total_amount)?.toString?.() ?? r.total_amount,
        status: r.order_status || null,
        delivery_boy: r.delivery_staff_id
            ? {
                staff_id: r.delivery_staff_id,
                name: r.delivery_staff_name,
                phone: r.delivery_staff_phone || null,
            }
            : null,
        estimated_delivery_time: {
            delivery_date: r.delivery_date ? new Date(r.delivery_date).toISOString() : null,
            estimated_duration_minutes: r.estimated_duration ?? null,
        },
        actions: {
            can_view: true,
            can_edit: true,
        },
    }));

    return { total, orders };
};

const fetchOrdersWithFallback = async ({ where, skip, take }) => {
    // First attempt: include richer relations (may fail if DB schema is behind)
    try {
        return await prisma.order.findMany({
            where,
            orderBy: { created_at: 'desc' },
            skip,
            take,
            select: {
                order_id: true,
                order_status: true,
                total_amount: true,
                created_at: true,
                delivery_date: true,
                customer: {
                    select: {
                        customer_id: true,
                        full_name: true,
                    },
                },
                delivery_address: {
                    select: {
                        address_id: true,
                        address_label: true,
                        full_address: true,
                        latitude: true,
                        longitude: true,
                    },
                },
                // For both per_unit and per_kg orders, services can be derived via service relation
                order_items: {
                    select: {
                        service: {
                            select: {
                                service_id: true,
                                service_name: true,
                            },
                        },
                        pricing_type: true, // To identify per_unit vs per_kg
                    },
                },
                service_queue_items: {
                    select: {
                        service: {
                            select: {
                                service_id: true,
                                service_name: true,
                            },
                        },
                    },
                },
                bill: {
                    select: {
                        final_amount: true,
                        payment_status: true,
                    },
                },
                delivery: {
                    select: {
                        delivery_id: true,
                        delivery_status: true,
                        estimated_duration: true,
                        staff: {
                            select: {
                                staff_id: true,
                                full_name: true,
                                phone: true,
                            },
                        },
                    },
                },
            },
        });
    } catch (error) {
        let err = error;

        // Tier 2: If the DB is missing optional tables, retry without them.
        if (err?.code === 'P2021') {
            logger.warn('Admin orders query fallback due to missing table', { message: err.message });

            try {
                return await prisma.order.findMany({
                    where,
                    orderBy: { created_at: 'desc' },
                    skip,
                    take,
                    select: {
                        order_id: true,
                        order_status: true,
                        total_amount: true,
                        created_at: true,
                        delivery_date: true,
                        customer: {
                            select: {
                                customer_id: true,
                                full_name: true,
                            },
                        },
                        delivery_address: {
                            select: {
                                address_id: true,
                                address_label: true,
                                full_address: true,
                                latitude: true,
                                longitude: true,
                            },
                        },
                        // Get services from order_items (works for both per_unit and per_kg)
                        order_items: {
                            select: {
                                service: {
                                    select: {
                                        service_id: true,
                                        service_name: true,
                                    },
                                },
                                pricing_type: true,
                            },
                        },
                        bill: {
                            select: {
                                final_amount: true,
                                payment_status: true,
                            },
                        },
                        delivery: {
                            select: {
                                delivery_id: true,
                                delivery_status: true,
                                estimated_duration: true,
                                staff: {
                                    select: {
                                        staff_id: true,
                                        full_name: true,
                                        phone: true,
                                    },
                                },
                            },
                        },
                    },
                });
            } catch (innerError) {
                err = innerError;
            }
        }

        // Tier 3: P2032 indicates DB contains NULL in a non-nullable Prisma field.
        // Retry without selecting relations that can trigger that conversion (e.g., order_items).
        if (err?.code === 'P2032') {
            logger.warn('Admin orders query fallback due to type conversion error', {
                message: err.message,
            });

            return await prisma.order.findMany({
                where,
                orderBy: { created_at: 'desc' },
                skip,
                take,
                select: {
                    order_id: true,
                    order_status: true,
                    total_amount: true,
                    created_at: true,
                    delivery_date: true,
                    customer: {
                        select: {
                            customer_id: true,
                            full_name: true,
                        },
                    },
                    delivery_address: {
                        select: {
                            address_id: true,
                            address_label: true,
                            full_address: true,
                            latitude: true,
                            longitude: true,
                        },
                    },
                    bill: {
                        select: {
                            final_amount: true,
                            payment_status: true,
                        },
                    },
                    delivery: {
                        select: {
                            delivery_id: true,
                            delivery_status: true,
                            estimated_duration: true,
                            staff: {
                                select: {
                                    staff_id: true,
                                    full_name: true,
                                    phone: true,
                                },
                            },
                        },
                    },
                },
            });
        }

        throw err;
    }
};

exports.getAdminOrderSummary = async ({ from, to, completedDate } = {}) => {
    const pendingStatuses = ['placed', 'pickup_assigned', 'picked_up', 'received_by_collection', 'submitted_to_services'];

    const createdAtWhere = buildCreatedAtWhere(from, to);
    const { start: completedStart, end: completedEnd } = getUtcDayRange(completedDate);

    const whereBase = {
        ...(createdAtWhere ? { created_at: createdAtWhere } : {}),
    };

    const [pending, outForDelivery, inProgress, completedToday] = await Promise.all([
        prisma.order.count({
            where: { ...whereBase, order_status: { in: pendingStatuses } },
        }),
        prisma.order.count({
            where: { ...whereBase, order_status: 'out_for_delivery' },
        }),
        prisma.order.count({
            where: { ...whereBase, order_status: 'services_in_progress' },
        }),
        prisma.order.count({
            where: {
                ...whereBase,
                order_status: { in: ['delivered', 'closed'] },
                updated_at: { gte: completedStart, lt: completedEnd },
            },
        }),
    ]);

    return { pending, outForDelivery, inProgress, completedToday };
};

exports.getAdminOrders = async (query = {}) => {
    const {
        status,
        from,
        to,
        page = 1,
        limit = 20,
    } = query;

    const statusList = normalizeStatusFilter(status);
    const createdAtWhere = buildCreatedAtWhere(from, to);

    const safePage = Number.isInteger(page) ? page : parseInt(page);
    const safeLimit = Number.isInteger(limit) ? limit : parseInt(limit);

    if (!Number.isInteger(safePage) || safePage < 1) throw new ValidationError('page must be >= 1');
    if (!Number.isInteger(safeLimit) || safeLimit < 1 || safeLimit > 100) {
        throw new ValidationError('limit must be between 1 and 100');
    }

    const skip = (safePage - 1) * safeLimit;

    const where = {
        ...(statusList ? { order_status: { in: statusList } } : {}),
        ...(createdAtWhere ? { created_at: createdAtWhere } : {}),
    };

    logger.info('Admin orders list query', {
        status: statusList ? statusList.join(',') : null,
        from: from || null,
        to: to || null,
        page: safePage,
        limit: safeLimit,
    });

    let total;
    let orders;

    try {
        [total, orders] = await Promise.all([
            prisma.order.count({ where }),
            fetchOrdersWithFallback({ where, skip, take: safeLimit }),
        ]);
    } catch (error) {
        // Ultimate fallback: if Prisma can't deserialize enum values (e.g. DB has 'draft'),
        // use raw SQL to read order_status as plain text without schema changes.
        if (isOrderStatusEnumMismatchError(error)) {
            logger.warn('Admin orders raw fallback due to enum mismatch', { message: error.message });
            const rawResult = await getAdminOrdersRaw({
                statusList,
                from,
                to,
                skip,
                take: safeLimit,
            });
            total = rawResult.total;
            orders = rawResult.orders;

            const totalPages = Math.ceil(total / safeLimit);
            return {
                orders,
                pagination: {
                    page: safePage,
                    limit: safeLimit,
                    total,
                    total_pages: totalPages,
                    has_next: safePage < totalPages,
                    has_prev: safePage > 1,
                },
            };
        }

        throw error;
    }

    const mappedOrders = orders.map((o) => {
        const serviceNames = [
            ...(o.order_items || []).map((i) => i?.service?.service_name).filter(Boolean),
            ...((o.service_queue_items || []).map((i) => i?.service?.service_name).filter(Boolean) || []),
        ];
        const services = Array.from(new Set(serviceNames));

        return {
            order_number: o.order_id,
            customer: {
                customer_id: o.customer?.customer_id || null,
                name: o.customer?.full_name || null,
                address: o.delivery_address
                    ? {
                        address_id: o.delivery_address.address_id,
                        label: o.delivery_address.address_label,
                        full_address: o.delivery_address.full_address,
                        latitude: o.delivery_address.latitude,
                        longitude: o.delivery_address.longitude,
                    }
                    : null,
            },
            services,
            amount: (o.bill?.final_amount ?? o.total_amount)?.toString?.() ?? o.total_amount,
            status: o.order_status,
            delivery_boy: o.delivery?.staff
                ? {
                    staff_id: o.delivery.staff.staff_id,
                    name: o.delivery.staff.full_name,
                    phone: o.delivery.staff.phone || null,
                }
                : null,
            estimated_delivery_time: {
                delivery_date: o.delivery_date ? o.delivery_date.toISOString() : null,
                estimated_duration_minutes: o.delivery?.estimated_duration ?? null,
            },
            actions: {
                can_view: true,
                can_edit: true,
            },
        };
    });

    const totalPages = Math.ceil(total / safeLimit);

    return {
        orders: mappedOrders,
        pagination: {
            page: safePage,
            limit: safeLimit,
            total,
            total_pages: totalPages,
            has_next: safePage < totalPages,
            has_prev: safePage > 1,
        },
    };
};

module.exports = exports;


