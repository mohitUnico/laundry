const dashboardService = require('../services/dashboard.service');
const { AppError } = require('../utils/errors');
const logger = require('../utils/logger');

/**
 * Dashboard Controller
 * Handles HTTP requests for dashboard analytics endpoints
 */

/**
 * Get monthly overview metrics
 * GET /api/v1/dashboard/monthly-overview
 */
exports.getMonthlyOverview = async (req, res, next) => {
    try {
        const martId = req.user.mart_id; // From JWT token (authenticateJWT middleware)
        const timestamp = req.currentTimestamp; // From parseTimestamp middleware
        const userId = req.user.user_id;

        logger.info('Monthly overview request', { userId, martId, timestamp });

        const data = await dashboardService.getMonthlyOverview(martId, timestamp);

        res.status(200).json({
            success: true,
            data,
            message: 'Monthly overview fetched successfully'
        });
    } catch (error) {
        next(error);
    }
};

/**
 * Get day overview metrics
 * GET /api/v1/dashboard/day-overview
 */
exports.getDayOverview = async (req, res, next) => {
    try {
        const martId = req.user.mart_id;
        const timestamp = req.currentTimestamp;
        const userId = req.user.user_id;

        logger.info('Day overview request', { userId, martId, timestamp });

        const data = await dashboardService.getDayOverview(martId, timestamp);

        res.status(200).json({
            success: true,
            data,
            message: 'Day overview fetched successfully'
        });
    } catch (error) {
        next(error);
    }
};

/**
 * Get revenue trend
 * GET /api/v1/dashboard/revenue-trend?range=7d
 */
exports.getRevenueTrend = async (req, res, next) => {
    try {
        const martId = req.user.mart_id;
        const timestamp = req.currentTimestamp;
        const { range = '7d' } = req.query;
        const userId = req.user.user_id;

        logger.info('Revenue trend request', { userId, martId, range, timestamp });

        const data = await dashboardService.getRevenueTrend(martId, range, timestamp);

        res.status(200).json({
            success: true,
            data,
            message: 'Revenue trend fetched successfully'
        });
    } catch (error) {
        next(error);
    }
};

/**
 * Get recent orders
 * GET /api/v1/dashboard/recent-orders
 */
exports.getRecentOrders = async (req, res, next) => {
    try {
        const martId = req.user.mart_id;
        const timestamp = req.currentTimestamp;
        const { limit = 10 } = req.query;
        const userId = req.user.user_id;

        logger.info('Recent orders request', { userId, martId, limit, timestamp });

        const orderLimit = parseInt(limit);
        const data = await dashboardService.getRecentOrders(martId, orderLimit, timestamp);

        res.status(200).json({
            success: true,
            data,
            message: 'Recent orders fetched successfully'
        });
    } catch (error) {
        next(error);
    }
};

/**
 * Get customer satisfaction metrics
 * GET /api/v1/dashboard/customer-satisfaction
 */
exports.getCustomerSatisfaction = async (req, res, next) => {
    try {
        const martId = req.user.mart_id;
        const timestamp = req.currentTimestamp;
        const userId = req.user.user_id;

        logger.info('Customer satisfaction request', { userId, martId, timestamp });

        const data = await dashboardService.getCustomerSatisfaction(martId, timestamp);

        res.status(200).json({
            success: true,
            data,
            message: 'Customer satisfaction metrics fetched successfully'
        });
    } catch (error) {
        next(error);
    }
};

/**
 * Get top performers (delivery staff)
 * GET /api/v1/dashboard/top-performers
 */
exports.getTopPerformers = async (req, res, next) => {
    try {
        const martId = req.user.mart_id;
        const timestamp = req.currentTimestamp;
        const { limit = 5 } = req.query;
        const userId = req.user.user_id;

        logger.info('Top performers request', { userId, martId, limit, timestamp });

        const performerLimit = parseInt(limit);
        const data = await dashboardService.getTopPerformers(martId, performerLimit, timestamp);

        res.status(200).json({
            success: true,
            data,
            message: 'Top performers fetched successfully'
        });
    } catch (error) {
        next(error);
    }
};

