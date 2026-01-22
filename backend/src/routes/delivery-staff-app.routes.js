const express = require('express');
const multer = require('multer');

const deliveryStaffAppController = require('../controllers/delivery-staff-app.controller');
const { authenticateJWT, authorize } = require('../middleware/auth.middleware');
const { validate, validateQuery } = require('../middleware/validation.middleware');
const { validateUuidParam } = require('../middleware/delivery-staff-app.middleware');
const {
    listAcceptedOrdersQuerySchema,
    listOrderHistoryQuerySchema,
    updateDeliveryStatusSchema,
} = require('../validators/delivery-staff-app.validator');

const router = express.Router();

const upload = multer({
    storage: multer.memoryStorage(),
    limits: { fileSize: 5 * 1024 * 1024 }, // 5 MB
});

/**
 * Delivery Staff App Routes (for staff-app / delivery partner app)
 *
 * Endpoints:
 * - GET   /api/v1/delivery-staff-app/home/stats
 * - GET   /api/v1/delivery-staff-app/orders/accepted
 * - PATCH /api/v1/delivery-staff-app/deliveries/:deliveryId/status
 * - GET   /api/v1/delivery-staff-app/orders/history
 * - GET   /api/v1/delivery-staff-app/profile
 * - POST  /api/v1/delivery-staff-app/profile-image/upload
 */

router.get('/home/stats', authenticateJWT, authorize('delivery_staff'), deliveryStaffAppController.getHomeStats);

router.get(
    '/orders/accepted',
    authenticateJWT,
    authorize('delivery_staff'),
    validateQuery(listAcceptedOrdersQuerySchema),
    deliveryStaffAppController.listAcceptedOrders
);

router.patch(
    '/deliveries/:deliveryId/status',
    authenticateJWT,
    authorize('delivery_staff'),
    validateUuidParam('deliveryId'),
    validate(updateDeliveryStatusSchema),
    deliveryStaffAppController.updateDeliveryStatus
);

router.get(
    '/orders/history',
    authenticateJWT,
    authorize('delivery_staff'),
    validateQuery(listOrderHistoryQuerySchema),
    deliveryStaffAppController.listOrderHistory
);

router.get('/profile', authenticateJWT, authorize('delivery_staff'), deliveryStaffAppController.getProfile);

router.post(
    '/profile-image/upload',
    authenticateJWT,
    authorize('delivery_staff'),
    upload.single('file'),
    deliveryStaffAppController.uploadProfileImage
);

module.exports = router;

