const express = require('express');

const serviceManAppController = require('../controllers/service-man-app.controller');
const { authenticateJWT, authorize } = require('../middleware/auth.middleware');
const { validate, validateQuery } = require('../middleware/validation.middleware');
const { validateUuidParam } = require('../middleware/delivery-staff-app.middleware');
const {
    listPaginationQuerySchema,
    serviceManQueueQuerySchema,
    updateServiceQueueItemSchema,
} = require('../validators/staff-app.validator');

const router = express.Router();

// GET current queue (pending/in_progress)
router.get(
    '/queue',
    authenticateJWT,
    authorize('service_man'),
    validateQuery(serviceManQueueQuerySchema.concat(listPaginationQuerySchema)),
    serviceManAppController.listQueue
);

// PATCH queue item status
router.patch(
    '/queue/:queueId',
    authenticateJWT,
    authorize('service_man'),
    validateUuidParam('queueId'),
    validate(updateServiceQueueItemSchema),
    serviceManAppController.updateQueueItem
);

// GET completed items
router.get(
    '/completed',
    authenticateJWT,
    authorize('service_man'),
    validateQuery(listPaginationQuerySchema),
    serviceManAppController.listCompleted
);

module.exports = router;

