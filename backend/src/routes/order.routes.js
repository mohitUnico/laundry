const express = require('express');
const orderController = require('../controllers/order.controller');
const { authenticateJWT, authorize } = require('../middleware/auth.middleware');
const {
    validateCreateOrder,
    validateConfirmOrder,
    validateListOrdersQuery,
} = require('../middleware/order.middleware');

const router = express.Router();

// List customer orders (with optional status filter)
router.get(
    '/',
    authenticateJWT,
    authorize('customer'),
    validateListOrdersQuery,
    orderController.listOrders
);

// Get a single order by ID
router.get(
    '/:orderId',
    authenticateJWT,
    authorize('customer'),
    validateConfirmOrder,
    orderController.getOrderById
);

// Create draft order from cart
router.post(
    '/create_order',
    authenticateJWT,
    authorize('customer'),
    validateCreateOrder,
    orderController.createOrder
);

// Confirm draft order (sets status to 'placed')
router.post(
    '/confirm_order/:orderId',
    authenticateJWT,
    authorize('customer'),
    validateConfirmOrder,
    orderController.confirmOrder
);

module.exports = router;
