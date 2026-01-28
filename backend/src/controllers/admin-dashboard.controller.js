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

module.exports = exports;

