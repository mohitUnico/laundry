const adminCustomerManagementService = require('../services/admin-customer-management.service');
const logger = require('../utils/logger');

/**
 * Admin Customer Management Controller
 * - GET /api/v1/admin/customers/summary
 * - GET /api/v1/admin/customers
 */

exports.getCustomerSummary = async (req, res, next) => {
    try {
        const userId = req.user?.user_id;
        logger.info('Admin customer summary request', { userId, query: req.query });

        const data = await adminCustomerManagementService.getAdminCustomerSummary(req.query);

        res.status(200).json({
            success: true,
            data,
            message: 'Customer summary fetched successfully',
        });
    } catch (error) {
        next(error);
    }
};

exports.listCustomers = async (req, res, next) => {
    try {
        const userId = req.user?.user_id;
        logger.info('Admin customers list request', { userId, query: req.query });

        const data = await adminCustomerManagementService.getAdminCustomers(req.query);

        res.status(200).json({
            success: true,
            data,
            message: 'Customers fetched successfully',
        });
    } catch (error) {
        next(error);
    }
};

module.exports = exports;


