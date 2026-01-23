const express = require('express');
const adminDeliveryStaffManagementController = require('../controllers/admin-delivery-staff-management.controller');
const { authenticateJWT, authorize } = require('../middleware/auth.middleware');
const { validateQuery } = require('../middleware/validation.middleware');
const { ValidationError } = require('../utils/errors');
const Joi = require('joi');

const {
    adminDeliveryStaffListQuerySchema,
    adminDeliveryStaffPendingVerificationsQuerySchema,
    adminDeliveryStaffOnlineQuerySchema,
} = require('../validators/admin-delivery-staff-management.validator');

const router = express.Router();

/**
 * Admin Delivery Staff Management Routes
 *
 * Endpoints:
 * - GET   /api/v1/admin/delivery-staff
 * - GET   /api/v1/admin/delivery-staff/staff-summary
 * - GET   /api/v1/admin/delivery-staff/pending-verifications
 * - GET   /api/v1/admin/delivery-staff/online
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
    '/staff-summary',
    authenticateJWT,
    authorize('super_admin', 'owner', 'admin', 'manager'),
    adminDeliveryStaffManagementController.getDeliveryStaffSummary
);

router.get(
    '/pending-verifications',
    authenticateJWT,
    authorize('super_admin', 'owner', 'admin', 'manager'),
    validateQuery(adminDeliveryStaffPendingVerificationsQuerySchema),
    adminDeliveryStaffManagementController.listPendingVerifications
);

router.get(
    '/online',
    authenticateJWT,
    authorize('super_admin', 'owner', 'admin', 'manager'),
    validateQuery(adminDeliveryStaffOnlineQuerySchema),
    adminDeliveryStaffManagementController.listOnlineDeliveryStaffs
);

router.get(
    '/',
    authenticateJWT,
    // Collection manager needs to view verified delivery partners for pickup assignment UI.
    // Distribution manager needs to view verified delivery partners for dispatch assignment UI.
    authorize('super_admin', 'owner', 'admin', 'manager', 'collection_manager', 'distribution_manager'),
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

