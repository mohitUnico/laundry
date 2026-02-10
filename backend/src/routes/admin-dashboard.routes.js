const express = require('express');
const router = express.Router();

const adminDashboardController = require('../controllers/admin-dashboard.controller');
const { authenticateJWT, authorize } = require('../middleware/auth.middleware');

/**
 * Admin Dashboard Routes
 * All routes require authentication and admin/owner role.
 */

/**
 * @route   GET /api/v1/admin/dashboard/revenue-breakdown
 * @desc    Revenue breakdown data for Total Revenue popup
 * @access  Private (Admin, Owner)
 */
router.get(
    '/revenue-breakdown',
    authenticateJWT,
    authorize('admin', 'owner', 'super_admin'),
    adminDashboardController.getRevenueBreakdown
);

/**
 * @route   GET /api/v1/admin/dashboard/delivery-analytics
 * @desc    Delivery analytics for Avg. Delivery Time popup (metrics + recent deliveries)
 * @access  Private (Admin, Owner)
 */
router.get(
    '/delivery-analytics',
    authenticateJWT,
    authorize('admin', 'owner', 'super_admin'),
    adminDashboardController.getDeliveryAnalytics
);

module.exports = router;

