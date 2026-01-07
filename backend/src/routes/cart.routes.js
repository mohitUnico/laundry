const express = require('express');
const cartController = require('../controllers/cart.controller');
const { authenticateJWT, authorize } = require('../middleware/auth.middleware');

const router = express.Router();

// GET /api/v1/carts
// Get all carts (active + inactive) for the authenticated customer, with nested items/selections
router.get('/', authenticateJWT, authorize('customer'), cartController.getCarts);

// POST /api/v1/carts/items
// Adds items to the customer's active cart (creates a cart if none exists)
router.post('/items', authenticateJWT, authorize('customer'), cartController.addCartItems);

module.exports = router;


