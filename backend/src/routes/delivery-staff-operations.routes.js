const express = require('express');
const Joi = require('joi');

const deliveryStaffOperationsController = require('../controllers/delivery-staff-operations.controller');
const { authenticateJWT, authorize } = require('../middleware/auth.middleware');
const { validate, validateQuery } = require('../middleware/validation.middleware');
const { ValidationError } = require('../utils/errors');
const {
    updateLocationSchema,
    listAssignmentRequestsQuerySchema,
    rejectAssignmentSchema,
} = require('../validators/delivery-staff-operations.validator');
const { saveFcmTokenSchema } = require('../validators/notification.validator');

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
 * Delivery Staff Operations Routes
 *
 * Endpoints:
 * - GET   /api/v1/delivery-staff/shift/status
 * - POST  /api/v1/delivery-staff/shift/start
 * - POST  /api/v1/delivery-staff/shift/stop
 * - PATCH /api/v1/delivery-staff/location
 * - GET   /api/v1/delivery-staff/assignment-requests
 * - POST  /api/v1/delivery-staff/assignment-requests/:requestId/accept
 * - POST  /api/v1/delivery-staff/assignment-requests/:requestId/reject
 * - GET   /api/v1/delivery-staff/events (SSE)
 * - POST  /api/v1/delivery-staff/fcm-token (FCM token for push when app closed)
 * - DELETE /api/v1/delivery-staff/fcm-token (clear FCM token on logout, only if matches)
 */

router.post(
    '/fcm-token',
    authenticateJWT,
    authorize('delivery_staff'),
    validate(saveFcmTokenSchema),
    deliveryStaffOperationsController.saveFcmToken
);

router.delete(
    '/fcm-token',
    authenticateJWT,
    authorize('delivery_staff'),
    validate(saveFcmTokenSchema),
    deliveryStaffOperationsController.clearFcmTokenIfMatches
);

router.get('/shift/status', authenticateJWT, authorize('delivery_staff'), deliveryStaffOperationsController.getShiftStatus);
router.post('/shift/start', authenticateJWT, authorize('delivery_staff'), deliveryStaffOperationsController.startShift);
router.post('/shift/stop', authenticateJWT, authorize('delivery_staff'), deliveryStaffOperationsController.stopShift);

router.patch(
    '/location',
    authenticateJWT,
    authorize('delivery_staff'),
    validate(updateLocationSchema),
    deliveryStaffOperationsController.updateLocation
);

router.get(
    '/assignment-requests',
    authenticateJWT,
    authorize('delivery_staff'),
    validateQuery(listAssignmentRequestsQuerySchema),
    deliveryStaffOperationsController.listAssignmentRequests
);

router.post(
    '/assignment-requests/:requestId/accept',
    authenticateJWT,
    authorize('delivery_staff'),
    validateUuidParam('requestId'),
    deliveryStaffOperationsController.acceptAssignmentRequest
);

router.post(
    '/assignment-requests/:requestId/reject',
    authenticateJWT,
    authorize('delivery_staff'),
    validateUuidParam('requestId'),
    validate(rejectAssignmentSchema),
    deliveryStaffOperationsController.rejectAssignmentRequest
);

router.get('/events', authenticateJWT, authorize('delivery_staff'), deliveryStaffOperationsController.events);

module.exports = router;

