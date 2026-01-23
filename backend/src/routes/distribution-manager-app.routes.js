const express = require('express');

const distributionManagerAppController = require('../controllers/distribution-manager-app.controller');
const { authenticateJWT, authorize } = require('../middleware/auth.middleware');
const { validate, validateQuery } = require('../middleware/validation.middleware');
const { validateUuidParam } = require('../middleware/delivery-staff-app.middleware');
const { listPaginationQuerySchema, assignDeliverySchema } = require('../validators/staff-app.validator');

const router = express.Router();

// GET orders ready to verify (services_completed & not verified)
router.get(
    '/orders/ready-to-verify',
    authenticateJWT,
    authorize('distribution_manager'),
    validateQuery(listPaginationQuerySchema),
    distributionManagerAppController.listReadyToVerify
);

// POST verify order
router.post(
    '/orders/:orderId/verify',
    authenticateJWT,
    authorize('distribution_manager'),
    validateUuidParam('orderId'),
    distributionManagerAppController.verifyOrder
);

// GET verified orders (services_completed & verified & not dispatched)
router.get(
    '/orders/verified',
    authenticateJWT,
    authorize('distribution_manager'),
    validateQuery(listPaginationQuerySchema),
    distributionManagerAppController.listVerifiedOrders
);

// POST dispatch (creates drop assignment request)
router.post(
    '/orders/:orderId/dispatch',
    authenticateJWT,
    authorize('distribution_manager'),
    validateUuidParam('orderId'),
    validate(assignDeliverySchema),
    distributionManagerAppController.dispatchOrder
);

// GET dispatch history
router.get(
    '/orders/history',
    authenticateJWT,
    authorize('distribution_manager'),
    validateQuery(listPaginationQuerySchema),
    distributionManagerAppController.listDispatchHistory
);

module.exports = router;

