const express = require('express');
const orderController = require('../controllers/order.controller');
const { authenticateJWT, authorize } = require('../middleware/auth.middleware');
const { validateCreateOrder, validateConfirmOrder } = require('../middleware/order.middleware');

const router = express.Router();

router.post(
    '/create_order',
    authenticateJWT,
    authorize('customer'),
    validateCreateOrder,
    orderController.createOrder
);

router.post(
    '/confirm_order/:orderId',
    authenticateJWT,
    authorize('customer'),
    validateConfirmOrder,
    orderController.confirmOrder
);

// GET /api/v1/orders - Get customer orders with pagination
router.get(
    '/',
    authenticateJWT,
    authorize('customer'),
    orderController.getCustomerOrders
);

module.exports = router;
