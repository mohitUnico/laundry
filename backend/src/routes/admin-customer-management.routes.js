const express = require('express');
const adminCustomerManagementController = require('../controllers/admin-customer-management.controller');
const { authenticateJWT, authorize } = require('../middleware/auth.middleware');
const { validateQuery } = require('../middleware/validation.middleware');
const {
    adminCustomersSummaryQuerySchema,
    adminCustomersListQuerySchema,
} = require('../validators/admin-customer-management.validator');

const router = express.Router();

/**
 * Admin Customer Management Routes
 *
 * Endpoints:
 * - GET /api/v1/admin/customers/summary
 * - GET /api/v1/admin/customers
 */

router.get(
    '/summary',
    authenticateJWT,
    authorize('super_admin', 'owner', 'admin', 'manager'),
    validateQuery(adminCustomersSummaryQuerySchema),
    adminCustomerManagementController.getCustomerSummary
);

router.get(
    '/',
    authenticateJWT,
    authorize('super_admin', 'owner', 'admin', 'manager'),
    validateQuery(adminCustomersListQuerySchema),
    adminCustomerManagementController.listCustomers
);

module.exports = router;


