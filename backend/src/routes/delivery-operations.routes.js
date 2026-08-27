const express = require('express');
const Joi = require('joi');

const deliveryOperationsController = require('../controllers/delivery-operations.controller');
const { authenticateJWT, authorize } = require('../middleware/auth.middleware');
const { validate, validateQuery } = require('../middleware/validation.middleware');
const { ValidationError } = require('../utils/errors');
const {
    nearbyStaffQuerySchema,
    createAssignmentRequestSchema,
} = require('../validators/delivery-operations.validator');

const router = express.Router();

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

/**
 * Admin Delivery Operations Routes
 *
 * Endpoints:
 * - GET  /api/v1/admin/delivery-ops/nearby-staff
 * - POST /api/v1/admin/delivery-ops/assignment-requests
 * - POST /api/v1/admin/delivery-ops/assignment-requests/:requestId/cancel
 */

router.get(
    '/nearby-staff',
    authenticateJWT,
    authorize('super_admin', 'owner', 'admin', 'manager'),
    validateQuery(nearbyStaffQuerySchema),
    deliveryOperationsController.searchNearbyStaff
);

router.post(
    '/assignment-requests',
    authenticateJWT,
    authorize('super_admin', 'owner', 'admin', 'manager'),
    validate(createAssignmentRequestSchema),
    deliveryOperationsController.createAssignmentRequest
);

router.post(
    '/assignment-requests/:requestId/cancel',
    authenticateJWT,
    authorize('super_admin', 'owner', 'admin', 'manager'),
    validateUuidParam('requestId'),
    deliveryOperationsController.cancelAssignmentRequest
);

module.exports = router;

