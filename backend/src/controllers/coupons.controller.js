const couponsService = require('../services/coupons-service');
const { NotFoundError } = require('../utils/errors');

function isCurrentlyValidCoupon(coupon) {
    if (!coupon) return false;
    if (coupon.is_active !== true) return false;

    const now = new Date();
    const validFrom = coupon.valid_from ? new Date(coupon.valid_from) : null;
    const validTill = coupon.valid_till ? new Date(coupon.valid_till) : null;

    if (validFrom && now < validFrom) return false;
    if (validTill && now > validTill) return false;
    return true;
}

/**
 * GET /api/v1/coupons
 */
exports.listCoupons = async (req, res, next) => {
    try {
        const role = req.user?.role;
        const query = role === 'customer' ? { ...req.query, valid_now: true, is_active: true } : req.query;

        const result = await couponsService.listCoupons(query);
        res.status(200).json({
            success: true,
            data: result.coupons,
            pagination: result.pagination,
            message: 'Coupons fetched successfully',
        });
    } catch (error) {
        next(error);
    }
};

/**
 * GET /api/v1/coupons/:id
 */
exports.getCouponById = async (req, res, next) => {
    try {
        const coupon = await couponsService.getCouponById(Number(req.params.id));
        if (req.user?.role === 'customer' && !isCurrentlyValidCoupon(coupon)) {
            throw new NotFoundError('Coupon');
        }
        res.status(200).json({
            success: true,
            data: coupon,
            message: 'Coupon fetched successfully',
        });
    } catch (error) {
        next(error);
    }
};

/**
 * POST /api/v1/coupons
 */
exports.createCoupon = async (req, res, next) => {
    try {
        const coupon = await couponsService.createCoupon(req.body);
        res.status(201).json({
            success: true,
            data: coupon,
            message: 'Coupon created successfully',
        });
    } catch (error) {
        next(error);
    }
};

/**
 * PATCH /api/v1/coupons/:id
 */
exports.updateCoupon = async (req, res, next) => {
    try {
        const coupon = await couponsService.updateCoupon(Number(req.params.id), req.body);
        res.status(200).json({
            success: true,
            data: coupon,
            message: 'Coupon updated successfully',
        });
    } catch (error) {
        next(error);
    }
};

/**
 * DELETE /api/v1/coupons/:id
 */
exports.deleteCoupon = async (req, res, next) => {
    try {
        const deleted = await couponsService.deleteCoupon(Number(req.params.id));
        res.status(200).json({
            success: true,
            data: deleted,
            message: 'Coupon deleted successfully',
        });
    } catch (error) {
        next(error);
    }
};

module.exports = exports;


