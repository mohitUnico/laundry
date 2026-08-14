const adminDashboardService = require('../services/admin-dashboard.service');
const logger = require('../utils/logger');

/**
 * Admin Dashboard Controller
 * Secured endpoints for admin panel analytics.
 */

/**
 * GET /api/v1/admin/dashboard/revenue-breakdown
 * Returns daily/weekly/monthly revenue totals + last 7 days trend.
 */
exports.getRevenueBreakdown = async (req, res, next) => {
    try {
        const userId = req.user?.user_id;
        const role = req.user?.role;
        const timestamp = new Date();

        logger.info('Admin revenue breakdown request', { userId, role });

        const data = await adminDashboardService.getRevenueBreakdown(timestamp);

        res.status(200).json({
            success: true,
            data,
            message: 'Revenue breakdown fetched successfully',
        });
    } catch (error) {
        next(error);
    }
};

/**
 * GET /api/v1/admin/dashboard/delivery-analytics
 * Returns delivery metrics (today/week/month avg + deltas) and recent deliveries for the modal.
 */
exports.getDeliveryAnalytics = async (req, res, next) => {
    try {
        const limit = req.query.limit != null ? parseInt(req.query.limit, 10) : 10;
        const timestamp = new Date();

        logger.info('Admin delivery analytics request', { userId: req.user?.user_id, role: req.user?.role });

        const data = await adminDashboardService.getDeliveryAnalytics(timestamp, limit);

        res.status(200).json({
            success: true,
            data,
            message: 'Delivery analytics fetched successfully',
        });
    } catch (error) {
        next(error);
    }
};

module.exports = exports;

