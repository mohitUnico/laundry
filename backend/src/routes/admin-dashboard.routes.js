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

module.exports = router;

