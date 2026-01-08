const express = require('express');
const adminDashboardController = require('../controllers/admin-dashboard.controller');
const { authenticateJWT, authorize } = require('../middleware/auth.middleware');
const { validateQuery } = require('../middleware/validation.middleware');
const {
    adminDashboardSummaryQuerySchema,
    adminDashboardOrderStatusQuerySchema,
    adminDashboardRevenueTrendQuerySchema,
    adminDashboardRecentOrdersQuerySchema,
    adminDashboardTopPerformersQuerySchema,
} = require('../validators/admin-dashboard.validator');

const router = express.Router();

/**
 * Admin Dashboard Routes
 *
 * Endpoints:
 * - GET /api/v1/admin/dashboard/summary
 * - GET /api/v1/admin/dashboard/order-status
 * - GET /api/v1/admin/dashboard/revenue-trend
 * - GET /api/v1/admin/dashboard/recent-orders
 * - GET /api/v1/admin/dashboard/top-performers
 * - GET /api/v1/admin/dashboard/customer-satisfaction
 */

router.get(
    '/summary',
    authenticateJWT,
    authorize('super_admin', 'owner', 'admin', 'manager'),
    validateQuery(adminDashboardSummaryQuerySchema),
    adminDashboardController.getSummary
);

router.get(
    '/order-status',
    authenticateJWT,
    authorize('super_admin', 'owner', 'admin', 'manager'),
    validateQuery(adminDashboardOrderStatusQuerySchema),
    adminDashboardController.getOrderStatus
);

router.get(
    '/revenue-trend',
    authenticateJWT,
    authorize('super_admin', 'owner', 'admin', 'manager'),
    validateQuery(adminDashboardRevenueTrendQuerySchema),
    adminDashboardController.getRevenueTrend
);

router.get(
    '/recent-orders',
    authenticateJWT,
    authorize('super_admin', 'owner', 'admin', 'manager'),
    validateQuery(adminDashboardRecentOrdersQuerySchema),
    adminDashboardController.getRecentOrders
);

router.get(
    '/top-performers',
    authenticateJWT,
    authorize('super_admin', 'owner', 'admin', 'manager'),
    validateQuery(adminDashboardTopPerformersQuerySchema),
    adminDashboardController.getTopPerformers
);

router.get(
    '/customer-satisfaction',
    authenticateJWT,
    authorize('super_admin', 'owner', 'admin', 'manager'),
    adminDashboardController.getCustomerSatisfaction
);

module.exports = router;


