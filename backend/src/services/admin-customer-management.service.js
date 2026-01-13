const prisma = require('../config/database');
const logger = require('../utils/logger');
const { ValidationError } = require('../utils/errors');

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

const normalizePagination = ({ page = 1, limit = 20 } = {}) => {
    const safePage = Number.isInteger(page) ? page : parseInt(page);
    const safeLimit = Number.isInteger(limit) ? limit : parseInt(limit);

    if (!Number.isInteger(safePage) || safePage < 1) throw new ValidationError('page must be >= 1');
    if (!Number.isInteger(safeLimit) || safeLimit < 1 || safeLimit > 100) {
        throw new ValidationError('limit must be between 1 and 100');
    }

    return { safePage, safeLimit, skip: (safePage - 1) * safeLimit };
};

exports.getAdminCustomerSummary = async ({ from, to, isActive } = {}) => {
    const createdAtWhere = buildCreatedAtWhere(from, to);

    const whereBase = {
        ...(createdAtWhere ? { created_at: createdAtWhere } : {}),
        ...(typeof isActive === 'boolean' ? { is_active: isActive } : {}),
    };

    logger.info('Admin customer summary query', {
        from: from || null,
        to: to || null,
        isActive: typeof isActive === 'boolean' ? isActive : null,
    });

    const [totalAgg, activeCount] = await Promise.all([
        prisma.customer.aggregate({
            where: whereBase,
            _count: { customer_id: true },
            _sum: { total_orders: true },
        }),
        prisma.customer.count({
            where: {
                ...(createdAtWhere ? { created_at: createdAtWhere } : {}),
                is_active: true,
            },
        }),
    ]);

    const totalCustomers = totalAgg?._count?.customer_id || 0;
    const sumOrders = totalAgg?._sum?.total_orders || 0;

    const averageOrdersPerCustomer =
        totalCustomers > 0 ? Number((sumOrders / totalCustomers).toFixed(2)) : 0;

    return {
        totalCustomers,
        activeCustomers: activeCount,
        averageOrdersPerCustomer,
    };
};

exports.getAdminCustomers = async (query = {}) => {
    const { from, to, isActive, search } = query;
    const { safePage, safeLimit, skip } = normalizePagination(query);

    const createdAtWhere = buildCreatedAtWhere(from, to);

    const normalizedSearch = typeof search === 'string' ? search.trim() : null;

    const where = {
        ...(createdAtWhere ? { created_at: createdAtWhere } : {}),
        ...(typeof isActive === 'boolean' ? { is_active: isActive } : {}),
        ...(normalizedSearch
            ? {
                  OR: [
                      { full_name: { contains: normalizedSearch, mode: 'insensitive' } },
                      { email: { contains: normalizedSearch, mode: 'insensitive' } },
                      { phone: { contains: normalizedSearch, mode: 'insensitive' } },
                  ],
              }
            : {}),
    };

    logger.info('Admin customers list query', {
        from: from || null,
        to: to || null,
        isActive: typeof isActive === 'boolean' ? isActive : null,
        search: normalizedSearch || null,
        page: safePage,
        limit: safeLimit,
    });

    const [total, customers] = await Promise.all([
        prisma.customer.count({ where }),
        prisma.customer.findMany({
            where,
            orderBy: { created_at: 'desc' },
            skip,
            take: safeLimit,
            select: {
                customer_id: true,
                full_name: true,
                email: true,
                phone: true,
                is_active: true,
                total_orders: true,
                created_at: true,
            },
        }),
    ]);

    const customerIds = customers.map((c) => c.customer_id);

    // Check if customer_rating column exists (some environments may have schema drift)
    const colCheck = await prisma.$queryRaw`
        SELECT EXISTS (
            SELECT 1
            FROM information_schema.columns
            WHERE table_schema = 'public'
              AND table_name = 'orders'
              AND column_name = 'customer_rating'
        ) AS exists
    `;
    const hasCustomerRating = Boolean(colCheck?.[0]?.exists);

    // Avoid N+1: fetch addresses + ratings for this page in bulk
    const [addresses, ratingAgg] = await Promise.all([
        customerIds.length
            ? prisma.customerAddress.findMany({
                  where: { customer_id: { in: customerIds } },
                  orderBy: [{ is_default: 'desc' }, { updated_at: 'desc' }],
                  select: {
                      customer_id: true,
                      address_id: true,
                      address_label: true,
                      full_address: true,
                      latitude: true,
                      longitude: true,
                      is_default: true,
                      updated_at: true,
                  },
              })
            : [],
        customerIds.length && hasCustomerRating
            ? prisma.order.groupBy({
                  by: ['customer_id'],
                  where: {
                      customer_id: { in: customerIds },
                      customer_rating: { not: null },
                  },
                  _avg: { customer_rating: true },
              })
            : [],
    ]);

    const primaryAddressByCustomerId = new Map();
    for (const addr of addresses) {
        if (!primaryAddressByCustomerId.has(addr.customer_id)) {
            primaryAddressByCustomerId.set(addr.customer_id, addr);
        }
    }

    const ratingByCustomerId = new Map();
    for (const row of ratingAgg) {
        const avg = row?._avg?.customer_rating;
        if (avg === null || avg === undefined) continue;
        // Prisma decimals may arrive as string/Decimal depending on runtime; normalize to number.
        const ratingNumber = typeof avg === 'number' ? avg : Number(avg);
        ratingByCustomerId.set(row.customer_id, Number.isFinite(ratingNumber) ? Number(ratingNumber.toFixed(2)) : null);
    }

    const items = customers.map((c) => {
        const addr = primaryAddressByCustomerId.get(c.customer_id) || null;
        const rating = ratingByCustomerId.has(c.customer_id) ? ratingByCustomerId.get(c.customer_id) : null;

        return {
            customerId: c.customer_id,
            name: c.full_name,
            contact: {
                email: c.email,
                phone: c.phone || null,
            },
            primaryAddress: addr
                ? {
                      addressId: addr.address_id,
                      label: addr.address_label,
                      fullAddress: addr.full_address,
                      latitude: addr.latitude,
                      longitude: addr.longitude,
                      isDefault: addr.is_default,
                  }
                : null,
            totalOrdersCount: c.total_orders ?? 0,
            rating,
            actions: {
                can_view: true,
                can_message: true,
            },
        };
    });

    const totalPages = Math.ceil(total / safeLimit);

    return {
        customers: items,
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

exports.createAdminCustomer = async (customerData) => {
    const { fullName, email, phone, address, addressLabel = 'home' } = customerData;

    if (!fullName || !email) {
        throw new ValidationError('Full name and email are required');
    }

    // Check if customer with email already exists
    const existingCustomer = await prisma.customer.findUnique({
        where: { email },
    });

    if (existingCustomer) {
        throw new ValidationError('Customer with this email already exists');
    }

    logger.info('Admin creating customer', { email, fullName });

    // Create customer and address in a transaction
    const result = await prisma.$transaction(async (tx) => {
        // Create customer
        const customer = await tx.customer.create({
            data: {
                full_name: fullName,
                email,
                phone: phone || null,
                is_active: true,
            },
        });

        // Create address if provided
        let customerAddress = null;
        if (address) {
            // For now, set default coordinates if not provided
            // In production, you'd want to geocode the address
            const latitude = customerData.latitude || 0;
            const longitude = customerData.longitude || 0;

            customerAddress = await tx.customerAddress.create({
                data: {
                    customer_id: customer.customer_id,
                    address_label: addressLabel,
                    full_address: address,
                    latitude,
                    longitude,
                    is_default: true, // First address is default
                },
            });
        }

        return { customer, address: customerAddress };
    });

    return {
        customerId: result.customer.customer_id,
        name: result.customer.full_name,
        email: result.customer.email,
        phone: result.customer.phone,
        address: result.address
            ? {
                  addressId: result.address.address_id,
                  label: result.address.address_label,
                  fullAddress: result.address.full_address,
                  latitude: result.address.latitude,
                  longitude: result.address.longitude,
                  isDefault: result.address.is_default,
              }
            : null,
    };
};

module.exports = exports;


