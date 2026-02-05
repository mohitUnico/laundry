const express = require('express');

const collectionManagerAppController = require('../controllers/collection-manager-app.controller');
const { authenticateJWT, authorize } = require('../middleware/auth.middleware');
const { validate, validateQuery } = require('../middleware/validation.middleware');
const { validateUuidParam } = require('../middleware/delivery-staff-app.middleware');
const {
    listPaginationQuerySchema,
    assignDeliverySchema,
    directAssignDeliverySchema,
    updatePerKgWeightsSchema,
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

// GET per-kg items for weight entry (delivery_only / drop-only orders)
router.get(
    '/orders/:orderId/items/weights',
    authenticateJWT,
    authorize('collection_manager'),
    validateUuidParam('orderId'),
    collectionManagerAppController.getPerKgItems
);

// PATCH update per-kg weights (for delivery_only orders - no pickup, CM enters weights)
router.patch(
    '/orders/:orderId/items/weights',
    authenticateJWT,
    authorize('collection_manager'),
    validateUuidParam('orderId'),
    validate(updatePerKgWeightsSchema),
    collectionManagerAppController.updatePerKgWeights
);

// POST create pickup assignment request (only pickup_only/both)
router.post(
    '/orders/:orderId/assign-pickup',
    authenticateJWT,
    authorize('collection_manager'),
    validateUuidParam('orderId'),
    validate(assignDeliverySchema),
    collectionManagerAppController.assignPickupDelivery
);

// POST manually assign pickup to a specific delivery staff (no accept/reject)
router.post(
    '/orders/:orderId/assign-pickup-direct',
    authenticateJWT,
    authorize('collection_manager'),
    validateUuidParam('orderId'),
    validate(directAssignDeliverySchema),
    collectionManagerAppController.assignPickupDirect
);

// POST mark received_by_collection
router.post(
    '/orders/:orderId/receive',
    authenticateJWT,
    authorize('collection_manager'),
    validateUuidParam('orderId'),
    collectionManagerAppController.markOrderReceived
);

// POST generate invoice (bill) for an order after received
router.post(
    '/orders/:orderId/generate-invoice',
    authenticateJWT,
    authorize('collection_manager'),
    validateUuidParam('orderId'),
    collectionManagerAppController.generateInvoice
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

