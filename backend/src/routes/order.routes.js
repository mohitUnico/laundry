const express = require('express');
const orderController = require('../controllers/order.controller');
const { authenticateJWT, authorize } = require('../middleware/auth.middleware');
const { validateCreateOrder } = require('../middleware/order.middleware');

const router = express.Router();

router.post(
    '/create_order',
    authenticateJWT,
    authorize('customer'),
    validateCreateOrder,
    orderController.createOrder
);

module.exports = router;
