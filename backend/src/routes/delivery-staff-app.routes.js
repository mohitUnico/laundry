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
    updatePerKgWeightsSchema,
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
    '/orders/:orderId/items/weights',
    authenticateJWT,
    authorize('delivery_staff'),
    validateUuidParam('orderId'),
    deliveryStaffAppController.getPerKgItems
);

router.patch(
    '/orders/:orderId/items/weights',
    authenticateJWT,
    authorize('delivery_staff'),
    validateUuidParam('orderId'),
    validate(updatePerKgWeightsSchema),
    deliveryStaffAppController.updatePerKgWeights
);

router.patch(
    '/deliveries/:deliveryId/status',
    authenticateJWT,
    authorize('delivery_staff'),
    validateUuidParam('deliveryId'),
    validate(updateDeliveryStatusSchema),
    deliveryStaffAppController.updateDeliveryStatus
);

router.post(
    '/deliveries/:deliveryId/mark-picked-up',
    authenticateJWT,
    authorize('delivery_staff'),
    validateUuidParam('deliveryId'),
    upload.single('file'),
    deliveryStaffAppController.markPickedUpWithProof
);

router.post(
    '/deliveries/:deliveryId/mark-delivered',
    authenticateJWT,
    authorize('delivery_staff'),
    validateUuidParam('deliveryId'),
    upload.single('file'),
    deliveryStaffAppController.markDeliveredWithProof
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

