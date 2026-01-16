const express = require('express');
const customerInfoController = require('../controllers/customer-info.controller');
const { authenticateJWT, authorize } = require('../middleware/auth.middleware');
const { validate } = require('../middleware/validation.middleware');
const multer = require('multer');
const {
    createCustomerAddressSchema,
    updateCustomerAddressSchema,
    updateCustomerProfileImageSchema,
    updateCustomerProfileSchema,
} = require('../validators/customer-info.validator');

const router = express.Router();

const upload = multer({
    storage: multer.memoryStorage(),
    limits: { fileSize: 5 * 1024 * 1024 }, // 5 MB
});

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

// PATCH /api/v1/customer-info/profile-image
// Set or clear profile image URL (store the link in DB)
router.patch(
    '/profile-image',
    authenticateJWT,
    authorize('customer'),
    validate(updateCustomerProfileImageSchema),
    customerInfoController.updateProfileImageUrl
);

// POST /api/v1/customer-info/profile-image/upload
// Upload profile image to Supabase Storage and save the public URL in DB
// multipart/form-data with field name: file
router.post(
    '/profile-image/upload',
    authenticateJWT,
    authorize('customer'),
    upload.single('file'),
    customerInfoController.uploadProfileImage
);

// PATCH /api/v1/customer-info/profile
// Update authenticated customer's profile fields (name/phone/profile_image_url)
router.patch(
    '/profile',
    authenticateJWT,
    authorize('customer'),
    validate(updateCustomerProfileSchema),
    customerInfoController.updateProfile
);

module.exports = router;


