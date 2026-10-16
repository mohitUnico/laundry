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
 * - GET   /api/v1/delivery-staff-app/orders/:orderId/items/weights
 * - PATCH /api/v1/delivery-staff-app/orders/:orderId/items/weights
 * - PATCH /api/v1/delivery-staff-app/deliveries/:deliveryId/status
 * - POST  /api/v1/delivery-staff-app/deliveries/:deliveryId/mark-picked-up
 * - POST  /api/v1/delivery-staff-app/deliveries/:deliveryId/mark-delivered
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

router.get(
    '/orders/:orderId/door',
    authenticateJWT,
    authorize('delivery_staff'),
    validateUuidParam('orderId'),
    deliveryStaffAppController.getDoor
);

router.patch(
    '/orders/:orderId/door/services/:orderItemId',
    authenticateJWT,
    authorize('delivery_staff'),
    validateUuidParam('orderId'),
    validateUuidParam('orderItemId'),
    deliveryStaffAppController.saveDoorDraft
);

router.post(
    '/orders/:orderId/door/services/:orderItemId/photo',
    authenticateJWT,
    authorize('delivery_staff'),
    validateUuidParam('orderId'),
    validateUuidParam('orderItemId'),
    upload.single('file'),
    deliveryStaffAppController.saveDoorPhoto
);

router.post(
    '/orders/:orderId/door/confirm',
    authenticateJWT,
    authorize('delivery_staff'),
    validateUuidParam('orderId'),
    deliveryStaffAppController.confirmDoor
);

router.post(
    '/orders/:orderId/submit-to-cm',
    authenticateJWT,
    authorize('delivery_staff'),
    validateUuidParam('orderId'),
    deliveryStaffAppController.submitToCm
);

router.post(
    '/orders/:orderId/record-cash',
    authenticateJWT,
    authorize('delivery_staff'),
    validateUuidParam('orderId'),
    deliveryStaffAppController.recordCash
);

router.post(
    '/orders/:orderId/mark-delivered',
    authenticateJWT,
    authorize('delivery_staff'),
    validateUuidParam('orderId'),
    upload.single('file'),
    deliveryStaffAppController.markDelivered
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

