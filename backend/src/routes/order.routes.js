// Sample Order Routes
// This is a template - implement full routes as needed

const express = require('express');
const orderController = require('../controllers/order.controller');
const { authenticateJWT } = require('../middleware/auth.middleware');
// const { validate } = require('../middleware/validation.middleware');
// const { orderSchemas } = require('../validators/order.validator');

const router = express.Router();

// All routes require authentication
router.use(authenticateJWT);

// Order routes
router.post('/', orderController.createOrder);
router.get('/', orderController.getOrders);
router.get('/:id', orderController.getOrderById);
router.patch('/:id/status', orderController.updateOrderStatus);
router.delete('/:id', orderController.cancelOrder);

module.exports = router;

