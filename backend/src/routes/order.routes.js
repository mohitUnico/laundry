const express = require('express');
const orderController = require('../controllers/order.controller');
const { authenticateJWT, authorize } = require('../middleware/auth.middleware');
const { validateCreateOrder, validateUpdateOrder } = require('../middleware/order.middleware');
const { validateUuidParam } = require('../middleware/delivery-staff-app.middleware');

const router = express.Router();

router.post(
    '/',
    authenticateJWT,
    authorize('customer'),
    validateCreateOrder,
    orderController.createOrderContract
);

router.post(
    '/create_order',
    authenticateJWT,
    authorize('customer'),
    validateCreateOrder,
    orderController.createOrder
);

// GET /api/v1/orders - Get customer orders with pagination
router.get(
    '/',
    authenticateJWT,
    authorize('customer'),
    orderController.getCustomerOrders
);

router.post(
    '/:orderId/cancel',
    authenticateJWT,
    authorize('customer'),
    validateUuidParam('orderId'),
    orderController.cancelOrder
);

router.patch(
    '/:orderId/schedule',
    authenticateJWT,
    authorize('customer'),
    validateUuidParam('orderId'),
    orderController.rescheduleOrder
);

router.patch(
    '/:orderId',
    authenticateJWT,
    authorize('customer'),
    validateUuidParam('orderId'),
    validateUpdateOrder,
    orderController.updateOrder
);

// GET /api/v1/orders/:orderId/tracking - Get order tracking data (map markers + assigned driver)
router.get(
    '/:orderId/invoice',
    authenticateJWT,
    authorize('customer'),
    validateUuidParam('orderId'),
    orderController.getInvoice
);

router.get(
    '/:orderId',
    authenticateJWT,
    authorize('customer'),
    validateUuidParam('orderId'),
    orderController.getOrder
);

router.get(
    '/:orderId/tracking',
    authenticateJWT,
    authorize('customer'),
    validateUuidParam('orderId'),
    orderController.getOrderTracking
);

module.exports = router;
