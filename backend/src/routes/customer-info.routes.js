const express = require('express');
const customerInfoController = require('../controllers/customer-info.controller');
const { authenticateJWT, authorize } = require('../middleware/auth.middleware');
const { validate } = require('../middleware/validation.middleware');
const {
    createCustomerAddressSchema,
    updateCustomerAddressSchema,
} = require('../validators/customer-info.validator');

const router = express.Router();

// POST /api/v1/customer-info/addresses
// Create a new address for the authenticated customer
router.post(
    '/addresses',
    authenticateJWT,
    authorize('customer'),
    validate(createCustomerAddressSchema),
    customerInfoController.createAddress
);

// GET /api/v1/customer-info/addresses
// List addresses for the authenticated customer
router.get('/addresses', authenticateJWT, authorize('customer'), customerInfoController.getAddresses);

// GET /api/v1/customer-info/addresses/:addressId
// Get a single address (must belong to authenticated customer)
router.get(
    '/addresses/:addressId',
    authenticateJWT,
    authorize('customer'),
    customerInfoController.getAddressById
);

// PATCH /api/v1/customer-info/addresses/:addressId
// Update an address (must belong to authenticated customer)
router.patch(
    '/addresses/:addressId',
    authenticateJWT,
    authorize('customer'),
    validate(updateCustomerAddressSchema),
    customerInfoController.updateAddress
);

// DELETE /api/v1/customer-info/addresses/:addressId
// Delete an address (must belong to authenticated customer)
router.delete(
    '/addresses/:addressId',
    authenticateJWT,
    authorize('customer'),
    customerInfoController.deleteAddress
);

module.exports = router;


