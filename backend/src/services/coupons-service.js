const { Prisma } = require('@prisma/client');
const prisma = require('../config/database');
const { NotFoundError, ValidationError } = require('../utils/errors');

function toDateOrNull(value, fieldName) {
    if (value === null || value === undefined) return value;
    if (value instanceof Date) return value;
    const d = new Date(value);
    if (Number.isNaN(d.getTime())) {
        throw new ValidationError(`Invalid date for ${fieldName}`);
    }
    return d;
}

function normalizeCouponPayload(payload = {}) {
    const normalized = { ...payload };
    if ('valid_from' in normalized) normalized.valid_from = toDateOrNull(normalized.valid_from, 'valid_from');
    if ('valid_till' in normalized) normalized.valid_till = toDateOrNull(normalized.valid_till, 'valid_till');
    return normalized;
}

exports.listCoupons = async (query = {}) => {
    const {
        page = 1,
        limit = 20,
        is_active,
        code,
        discount_type,
        valid_now,
    } = query;

    const pageNum = Number(page) || 1;
    const limitNum = Math.min(Math.max(Number(limit) || 20, 1), 100);
    const skip = (pageNum - 1) * limitNum;
    const take = limitNum;

    const where = {};

    if (typeof is_active === 'boolean') where.is_active = is_active;
    if (code) where.code = { contains: code, mode: 'insensitive' };
    if (discount_type) where.discount_type = discount_type;

    if (valid_now === true) {
        const now = new Date();
        where.is_active = true;
        where.AND = [
            {
                OR: [{ valid_from: null }, { valid_from: { lte: now } }],
            },
            {
                OR: [{ valid_till: null }, { valid_till: { gte: now } }],
            },
        ];
    }

    let total = 0;
    let coupons = [];

    try {
        const result = await prisma.$transaction([
            prisma.coupon.count({ where }),
            prisma.coupon.findMany({
                where,
                orderBy: { id: 'desc' },
                skip,
                take,
            }),
        ]);
        total = result[0];
        coupons = result[1] || [];
    } catch (e) {
        throw new ValidationError(e?.message || 'Failed to fetch coupons');
    }

    return {
        coupons,
        pagination: {
            page: pageNum,
            limit: limitNum,
            total,
            totalPages: Math.ceil(total / limitNum),
            hasNext: pageNum * limitNum < total,
            hasPrev: pageNum > 1,
        },
    };
};

exports.getCouponById = async (id) => {
    const coupon = await prisma.coupon.findUnique({ where: { id } });
    if (!coupon) throw new NotFoundError('Coupon');
    return coupon;
};

exports.createCoupon = async (payload = {}) => {
    const insertData = normalizeCouponPayload(payload);
    try {
        return await prisma.coupon.create({ data: insertData });
    } catch (e) {
        throw new ValidationError(e?.message || 'Failed to create coupon');
    }
};

exports.updateCoupon = async (id, payload = {}) => {
    const updateData = normalizeCouponPayload(payload);
    try {
        return await prisma.coupon.update({ where: { id }, data: updateData });
    } catch (e) {
        if (e instanceof Prisma.PrismaClientKnownRequestError && e.code === 'P2025') {
            throw new NotFoundError('Coupon');
        }
        throw new ValidationError(e?.message || 'Failed to update coupon');
    }
};

exports.deleteCoupon = async (id) => {
    try {
        return await prisma.coupon.delete({ where: { id } });
    } catch (e) {
        if (e instanceof Prisma.PrismaClientKnownRequestError && e.code === 'P2025') {
            throw new NotFoundError('Coupon');
        }
        throw new ValidationError(e?.message || 'Failed to delete coupon');
    }
};

module.exports = exports;


