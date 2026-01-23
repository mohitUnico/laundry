const express = require('express');
const Joi = require('joi');

const couponsController = require('../controllers/coupons.controller');
const { authenticateJWT, authorize } = require('../middleware/auth.middleware');
const { validate, validateQuery } = require('../middleware/validation.middleware');
const { ValidationError } = require('../utils/errors');

const {
    listCouponsQuerySchema,
    createCouponSchema,
    updateCouponSchema,
} = require('../validators/coupons.validator');

const router = express.Router();

/**
 * Coupons Routes
 *
 * Endpoints:
 * - GET    /api/v1/coupons
 * - GET    /api/v1/coupons/:id
 * - POST   /api/v1/coupons
 * - PATCH  /api/v1/coupons/:id
 * - DELETE /api/v1/coupons/:id
 */

// ============================================================================
// VALIDATION HELPERS
// ============================================================================

const intIdParam = Joi.number().integer().positive().required();
const validateIntParam = (paramName) => {
    return (req, _res, next) => {
        const { error } = intIdParam.validate(Number(req.params[paramName]));
        if (error) {
            return next(new ValidationError('Validation failed', [{ field: paramName, message: error.message }]));
        }
        next();
    };
};

// LIST
router.get(
    '/',
    authenticateJWT,
    authorize('super_admin', 'owner', 'admin', 'manager', 'customer'),
    validateQuery(listCouponsQuerySchema),
    couponsController.listCoupons
);

// GET BY ID
router.get(
    '/:id',
    authenticateJWT,
    authorize('super_admin', 'owner', 'admin', 'manager', 'customer'),
    validateIntParam('id'),
    couponsController.getCouponById
);

// CREATE
router.post(
    '/',
    authenticateJWT,
    authorize('super_admin', 'owner', 'admin', 'manager'),
    validate(createCouponSchema),
    couponsController.createCoupon
);

// UPDATE
router.patch(
    '/:id',
    authenticateJWT,
    authorize('super_admin', 'owner', 'admin', 'manager'),
    validateIntParam('id'),
    validate(updateCouponSchema),
    couponsController.updateCoupon
);

// DELETE
router.delete(
    '/:id',
    authenticateJWT,
    authorize('super_admin', 'owner', 'admin', 'manager'),
    validateIntParam('id'),
    couponsController.deleteCoupon
);

module.exports = router;


