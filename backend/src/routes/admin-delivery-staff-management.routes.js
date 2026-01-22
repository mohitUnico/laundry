const express = require('express');
const adminDeliveryStaffManagementController = require('../controllers/admin-delivery-staff-management.controller');
const { authenticateJWT, authorize } = require('../middleware/auth.middleware');
const { validateQuery } = require('../middleware/validation.middleware');
const { ValidationError } = require('../utils/errors');
const Joi = require('joi');

const {
    adminDeliveryStaffListQuerySchema,
} = require('../validators/admin-delivery-staff-management.validator');

const router = express.Router();

/**
 * Admin Delivery Staff Management Routes
 *
 * Endpoints:
 * - GET   /api/v1/admin/delivery-staff
 * - PATCH /api/v1/admin/delivery-staff/:staffId/verify
 */

// ============================================================================
// VALIDATION HELPERS
// ============================================================================

const uuidParam = Joi.string().uuid().required();
const validateUuidParam = (paramName) => {
    return (req, _res, next) => {
        const { error } = uuidParam.validate(req.params[paramName]);
        if (error) {
            return next(new ValidationError('Validation failed', [{ field: paramName, message: error.message }]));
        }
        next();
    };
};

router.get(
    '/',
    authenticateJWT,
    authorize('super_admin', 'owner', 'admin', 'manager'),
    validateQuery(adminDeliveryStaffListQuerySchema),
    adminDeliveryStaffManagementController.listDeliveryStaffs
);

router.patch(
    '/:staffId/verify',
    authenticateJWT,
    authorize('super_admin', 'owner', 'admin', 'manager'),
    validateUuidParam('staffId'),
    adminDeliveryStaffManagementController.verifyDeliveryStaff
);

module.exports = router;

