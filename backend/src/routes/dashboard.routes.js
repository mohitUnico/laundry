const express = require('express');
const router = express.Router();
const dashboardController = require('../controllers/dashboard.controller');
const { authenticateJWT, authorize } = require('../middleware/auth.middleware');
const {
    parseTimestamp,
    validateQueryParams
} = require('../middleware/dashboard.middleware');

/**
 * Dashboard Routes
 * All routes require authentication and owner/manager role
 * mart_id is automatically extracted from JWT token (req.user.mart_id)
 * Optional request body: { current_timestamp?: string }
 */

/**
 * @route   GET /api/v1/dashboard/monthly-overview
 * @desc    Get monthly overview metrics for a mart
 * @access  Private (Owner, Manager)
 * @body    { current_timestamp?: string }
 */
router.get(
    '/monthly-overview',
    authenticateJWT,
    authorize('super_admin', 'admin', 'manager'),
    parseTimestamp,
    dashboardController.getMonthlyOverview
);

/**
 * @route   GET /api/v1/dashboard/day-overview
 * @desc    Get day overview metrics for a mart
 * @access  Private (Owner, Manager)
 * @body    { current_timestamp?: string }
 */
router.get(
    '/day-overview',
    authenticateJWT,
    authorize('super_admin', 'admin', 'manager'),
    parseTimestamp,
    dashboardController.getDayOverview
);

/**
 * @route   GET /api/v1/dashboard/revenue-trend?range=7days
 * @desc    Get revenue trend for a specified time range
 * @access  Private (Owner, Manager)
 * @query   range: 7days | 7weeks | 7months (default: 7days)
 * @body    { current_timestamp?: string }
 */
router.get(
    '/revenue-trend',
    authenticateJWT,
    authorize('super_admin', 'admin', 'manager'),
    parseTimestamp,
    validateQueryParams,
    dashboardController.getRevenueTrend
);

/**
 * @route   GET /api/v1/dashboard/recent-orders?limit=10
 * @desc    Get recent orders for a mart
 * @access  Private (Owner, Manager)
 * @query   limit: number (1-100, default: 10)
 * @body    { current_timestamp?: string }
 */
router.get(
    '/recent-orders',
    authenticateJWT,
    authorize('super_admin', 'admin', 'manager'),
    parseTimestamp,
    validateQueryParams,
    dashboardController.getRecentOrders
);

/**
 * @route   GET /api/v1/dashboard/customer-satisfaction
 * @desc    Get customer satisfaction metrics for a mart
 * @access  Private (Owner, Manager)
 * @body    { current_timestamp?: string }
 */
router.get(
    '/customer-satisfaction',
    authenticateJWT,
    authorize('super_admin', 'admin', 'manager'),
    parseTimestamp,
    dashboardController.getCustomerSatisfaction
);

/**
 * @route   GET /api/v1/dashboard/top-performers?limit=5
 * @desc    Get top performing delivery staff for a mart
 * @access  Private (Owner, Manager)
 * @query   limit: number (1-50, default: 5)
 * @body    { current_timestamp?: string }
 */
router.get(
    '/top-performers',
    authenticateJWT,
    authorize('super_admin', 'admin', 'manager'),
    parseTimestamp,
    validateQueryParams,
    dashboardController.getTopPerformers
);

module.exports = router;

