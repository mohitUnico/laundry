const express = require('express');

const distributionManagerAppController = require('../controllers/distribution-manager-app.controller');
const { authenticateJWT, authorize } = require('../middleware/auth.middleware');
const { validate, validateQuery } = require('../middleware/validation.middleware');
const { validateUuidParam } = require('../middleware/delivery-staff-app.middleware');
const { listPaginationQuerySchema, directAssignDeliverySchema } = require('../validators/staff-app.validator');

const router = express.Router();

router.get(
    '/orders/in-plant',
    authenticateJWT,
    authorize('distribution_manager'),
    distributionManagerAppController.listInPlant
);

router.get(
    '/orders/ready-to-dispatch',
    authenticateJWT,
    authorize('distribution_manager'),
    distributionManagerAppController.listReadyToDispatch
);

router.get(
    '/orders/history',
    authenticateJWT,
    authorize('distribution_manager'),
    validateQuery(listPaginationQuerySchema),
    distributionManagerAppController.listHistory
);

router.get(
    '/orders/:orderId/assignable-staff',
    authenticateJWT,
    authorize('distribution_manager'),
    validateUuidParam('orderId'),
    distributionManagerAppController.listAssignableStaff
);

router.post(
    '/orders/:orderId/assign-drop',
    authenticateJWT,
    authorize('distribution_manager'),
    validateUuidParam('orderId'),
    validate(directAssignDeliverySchema),
    distributionManagerAppController.assignDrop
);

module.exports = router;
