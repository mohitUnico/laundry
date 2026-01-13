const express = require('express');
const adminOrderManagementController = require('../controllers/admin-order-management.controller');
const { authenticateJWT, authorize } = require('../middleware/auth.middleware');
const { validateQuery } = require('../middleware/validation.middleware');
const {
    adminOrdersSummaryQuerySchema,
    adminOrdersListQuerySchema,
} = require('../validators/admin-order-management.validator');

const router = express.Router();

/**
 * Admin Order Management Routes
 *
 * Endpoints:
 * - GET /api/v1/admin/orders/summary
 * - GET /api/v1/admin/orders
 */

router.get(
    '/summary',
    authenticateJWT,
    authorize('super_admin', 'owner', 'admin', 'manager'),
    validateQuery(adminOrdersSummaryQuerySchema),
    adminOrderManagementController.getOrderSummary
);

router.get(
    '/',
    authenticateJWT,
    authorize('super_admin', 'owner', 'admin', 'manager'),
    validateQuery(adminOrdersListQuerySchema),
    adminOrderManagementController.listOrders
);

module.exports = router;


