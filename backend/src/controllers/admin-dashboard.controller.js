const adminDashboardService = require('../services/admin-dashboard.service');
const logger = require('../utils/logger');

/**
 * Admin Dashboard Controller
 * - GET /api/v1/admin/dashboard/summary
 * - GET /api/v1/admin/dashboard/order-status
 * - GET /api/v1/admin/dashboard/revenue-trend
 * - GET /api/v1/admin/dashboard/recent-orders
 * - GET /api/v1/admin/dashboard/top-performers
 * - GET /api/v1/admin/dashboard/customer-satisfaction
 */

exports.getSummary = async (req, res, next) => {
    try {
        const userId = req.user?.user_id;
        logger.info('Admin dashboard summary request', { userId, query: req.query });
        const data = await adminDashboardService.getDashboardSummary(req.query);
        res.status(200).json({ success: true, data, message: 'Dashboard summary fetched successfully' });
    } catch (error) {
        next(error);
    }
};

exports.getOrderStatus = async (req, res, next) => {
    try {
        const userId = req.user?.user_id;
        logger.info('Admin dashboard order status request', { userId, query: req.query });
        const data = await adminDashboardService.getOrderStatusBreakdown(req.query);
        res.status(200).json({ success: true, data, message: 'Order status fetched successfully' });
    } catch (error) {
        next(error);
    }
};

exports.getRevenueTrend = async (req, res, next) => {
    try {
        const userId = req.user?.user_id;
        logger.info('Admin dashboard revenue trend request', { userId, query: req.query });
        const data = await adminDashboardService.getRevenueTrend(req.query);
        res.status(200).json({ success: true, data, message: 'Revenue trend fetched successfully' });
    } catch (error) {
        next(error);
    }
};

exports.getRecentOrders = async (req, res, next) => {
    try {
        const userId = req.user?.user_id;
        logger.info('Admin dashboard recent orders request', { userId, query: req.query });
        const data = await adminDashboardService.getRecentOrders(req.query);
        res.status(200).json({ success: true, data, message: 'Recent orders fetched successfully' });
    } catch (error) {
        next(error);
    }
};

exports.getTopPerformers = async (req, res, next) => {
    try {
        const userId = req.user?.user_id;
        logger.info('Admin dashboard top performers request', { userId, query: req.query });
        const data = await adminDashboardService.getTopPerformers(req.query);
        res.status(200).json({ success: true, data, message: 'Top performers fetched successfully' });
    } catch (error) {
        next(error);
    }
};

exports.getCustomerSatisfaction = async (req, res, next) => {
    try {
        const userId = req.user?.user_id;
        logger.info('Admin dashboard customer satisfaction request', { userId });
        const data = await adminDashboardService.getCustomerSatisfaction();
        res.status(200).json({ success: true, data, message: 'Customer satisfaction fetched successfully' });
    } catch (error) {
        next(error);
    }
};

module.exports = exports;


