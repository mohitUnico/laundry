const { getSupabaseClient } = require('../config/supabase');
const { NotFoundError, ValidationError } = require('../utils/errors');

function toIsoOrNull(value) {
    if (value === null || value === undefined) return value;
    if (value instanceof Date) return value.toISOString();
    return value;
}

function normalizeCouponPayload(payload = {}) {
    // Normalize date-ish fields so PostgREST gets consistent values
    const normalized = { ...payload };
    if ('valid_from' in normalized) normalized.valid_from = toIsoOrNull(normalized.valid_from);
    if ('valid_till' in normalized) normalized.valid_till = toIsoOrNull(normalized.valid_till);
    return normalized;
}

exports.listCoupons = async (query = {}) => {
    const supabase = getSupabaseClient();
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
    const from = (pageNum - 1) * limitNum;
    const to = from + limitNum - 1;

    let q = supabase.from('coupons').select('*', { count: 'exact' }).order('id', { ascending: false });

    if (typeof is_active === 'boolean') q = q.eq('is_active', is_active);
    if (code) q = q.ilike('code', `%${code}%`);
    if (discount_type) q = q.eq('discount_type', discount_type);

    if (valid_now === true) {
        const nowIso = new Date().toISOString();
        q = q.lte('valid_from', nowIso).gte('valid_till', nowIso).eq('is_active', true);
    }

    const { data, error, count } = await q.range(from, to);
    if (error) {
        throw new ValidationError(error.message);
    }

    return {
        coupons: data || [],
        pagination: {
            page: pageNum,
            limit: limitNum,
            total: count || 0,
            totalPages: Math.ceil((count || 0) / limitNum),
            hasNext: pageNum * limitNum < (count || 0),
            hasPrev: pageNum > 1,
        },
    };
};

exports.getCouponById = async (id) => {
    const supabase = getSupabaseClient();

    const { data, error } = await supabase.from('coupons').select('*').eq('id', id).single();
    if (error) {
        // PostgREST returns an error when .single() finds no rows
        if (error.code === 'PGRST116') throw new NotFoundError('Coupon');
        throw new ValidationError(error.message);
    }

    return data;
};

exports.createCoupon = async (payload = {}) => {
    const supabase = getSupabaseClient();
    const insertData = normalizeCouponPayload(payload);

    const { data, error } = await supabase.from('coupons').insert([insertData]).select('*').single();
    if (error) {
        throw new ValidationError(error.message);
    }

    return data;
};

exports.updateCoupon = async (id, payload = {}) => {
    const supabase = getSupabaseClient();
    const updateData = normalizeCouponPayload(payload);

    const { data, error } = await supabase.from('coupons').update(updateData).eq('id', id).select('*').single();
    if (error) {
        if (error.code === 'PGRST116') throw new NotFoundError('Coupon');
        throw new ValidationError(error.message);
    }

    return data;
};

exports.deleteCoupon = async (id) => {
    const supabase = getSupabaseClient();

    const { data, error } = await supabase.from('coupons').delete().eq('id', id).select('*').single();
    if (error) {
        if (error.code === 'PGRST116') throw new NotFoundError('Coupon');
        throw new ValidationError(error.message);
    }

    return data;
};

module.exports = exports;


