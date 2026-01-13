const adminOrderManagementService = require('../services/admin-order-management.service');
const logger = require('../utils/logger');

/**
 * Admin Order Management Controller
 * - GET /api/v1/admin/orders/summary
 * - GET /api/v1/admin/orders
 */

exports.getOrderSummary = async (req, res, next) => {
    try {
        const userId = req.user?.user_id;
        logger.info('Admin order summary request', { userId, query: req.query });

        const data = await adminOrderManagementService.getAdminOrderSummary(req.query);

        res.status(200).json({
            success: true,
            data,
            message: 'Order summary fetched successfully',
        });
    } catch (error) {
        next(error);
    }
};

exports.listOrders = async (req, res, next) => {
    try {
        const userId = req.user?.user_id;
        logger.info('Admin orders list request', { userId, query: req.query });

        const data = await adminOrderManagementService.getAdminOrders(req.query);

        res.status(200).json({
            success: true,
            data,
            message: 'Orders fetched successfully',
        });
    } catch (error) {
        next(error);
    }
};

module.exports = exports;


