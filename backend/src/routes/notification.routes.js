const express = require('express');

const notificationController = require('../controllers/notification.controller');
const { authenticateJWT, authorize } = require('../middleware/auth.middleware');
const { validate } = require('../middleware/validation.middleware');
const { saveFcmTokenSchema } = require('../validators/notification.validator');

const router = express.Router();

// POST /api/v1/notifications/fcm-token
router.post(
    '/fcm-token',
    authenticateJWT,
    authorize('customer'),
    validate(saveFcmTokenSchema),
    notificationController.saveCustomerFcmToken
);

module.exports = router;


