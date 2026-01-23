const express = require('express');
const adminOrderManagementController = require('../controllers/admin-order-management.controller');
const { authenticateJWT, authorize } = require('../middleware/auth.middleware');
const { validate, validateQuery } = require('../middleware/validation.middleware');
const {
    adminOrdersSummaryQuerySchema,
    adminOrdersListQuerySchema,
    adminUpdateOrderStatusSchema,
} = require('../validators/admin-order-management.validator');
const { ValidationError } = require('../utils/errors');
const Joi = require('joi');

const router = express.Router();

// ============================================================================
// VALIDATION HELPERS
// ============================================================================

const uuidParam = Joi.string().uuid().required();

const validateUuidParam = (paramName) => {
    return (req, _res, next) => {
        const { error } = uuidParam.validate(req.params[paramName]);
        if (error) {
            return next(new ValidationError('Validation failed', [{ field: paramName, message: error.message }]));
        }
        next();
    };
};

/**
 * Admin Order Management Routes
 *
 * Endpoints:
 * - GET /api/v1/admin/orders/summary
 * - GET /api/v1/admin/orders
 * - PATCH /api/v1/admin/orders/:orderId/status
 */

router.get(
    '/summary',
    authenticateJWT,
    authorize('super_admin', 'owner', 'admin', 'manager'),
    validateQuery(adminOrdersSummaryQuerySchema),
    adminOrderManagementController.getOrderSummary
);

router.get(
    '/',
    authenticateJWT,
    authorize('super_admin', 'owner', 'admin', 'manager'),
    validateQuery(adminOrdersListQuerySchema),
    adminOrderManagementController.listOrders
);

router.patch(
    '/:orderId/status',
    authenticateJWT,
    authorize('super_admin', 'owner', 'admin', 'manager'),
    validateUuidParam('orderId'),
    validate(adminUpdateOrderStatusSchema),
    adminOrderManagementController.updateOrderStatus
);

module.exports = router;


