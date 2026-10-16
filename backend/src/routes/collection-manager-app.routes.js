const express = require('express');

const collectionManagerAppController = require('../controllers/collection-manager-app.controller');
const { authenticateJWT, authorize } = require('../middleware/auth.middleware');
const { validate, validateQuery } = require('../middleware/validation.middleware');
const { validateUuidParam } = require('../middleware/delivery-staff-app.middleware');
const {
    listPaginationQuerySchema,
    directAssignDeliverySchema,
} = require('../validators/staff-app.validator');

const router = express.Router();

// GET incoming orders (placed / pickup_assigned / picked_up)
router.get(
    '/orders/incoming',
    authenticateJWT,
    authorize('collection_manager'),
    validateQuery(listPaginationQuerySchema),
    collectionManagerAppController.listIncomingOrders
);

// GET order items (for staff app UI)
router.get(
    '/orders/:orderId/items',
    authenticateJWT,
    authorize('collection_manager'),
    validateUuidParam('orderId'),
    collectionManagerAppController.getOrderItems
);

// GET verified staff the manager may force-assign after timeout
router.get(
    '/orders/:orderId/assignable-staff',
    authenticateJWT,
    authorize('collection_manager'),
    validateUuidParam('orderId'),
    collectionManagerAppController.listAssignableStaff
);

// POST manually assign pickup to a specific delivery staff (only after search timeout)
router.post(
    '/orders/:orderId/assign-pickup-direct',
    authenticateJWT,
    authorize('collection_manager'),
    validateUuidParam('orderId'),
    validate(directAssignDeliverySchema),
    collectionManagerAppController.assignPickupDirect
);

router.post(
    '/orders/:orderId/receive',
    authenticateJWT,
    authorize('collection_manager'),
    validateUuidParam('orderId'),
    collectionManagerAppController.markOrderReceived
);

router.post(
    '/orders/:orderId/mark-received',
    authenticateJWT,
    authorize('collection_manager'),
    validateUuidParam('orderId'),
    collectionManagerAppController.markOrderReceived
);

// GET received orders
router.get(
    '/orders/received',
    authenticateJWT,
    authorize('collection_manager'),
    validateQuery(listPaginationQuerySchema),
    collectionManagerAppController.listReceivedOrders
);

// POST submit order to services (creates service queue items)
router.post(
    '/orders/:orderId/submit-to-services',
    authenticateJWT,
    authorize('collection_manager'),
    validateUuidParam('orderId'),
    collectionManagerAppController.submitToServices
);

// GET submission history
router.get(
    '/orders/history',
    authenticateJWT,
    authorize('collection_manager'),
    validateQuery(listPaginationQuerySchema),
    collectionManagerAppController.listSubmissionHistory
);

module.exports = router;

