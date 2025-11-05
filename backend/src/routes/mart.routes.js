/**
 * Mart Routes
 * Endpoints for mart management
 */

const express = require('express');
const router = express.Router();
const martController = require('../controllers/mart.controller');
const { validate } = require('../middleware/validation.middleware');
const { authenticateJWT, authorize } = require('../middleware/auth.middleware');
const Joi = require('joi');

// ============================================================================
// VALIDATION SCHEMAS
// ============================================================================

const registerMartSchema = Joi.object({
    martName: Joi.string().min(3).max(255).required(),
    contactEmail: Joi.string().email().required(),
    contactPhone: Joi.string().pattern(/^[6-9]\d{9}$/).required(),
    address: Joi.string().min(10).required(),
    latitude: Joi.number().min(-90).max(90).required(),
    longitude: Joi.number().min(-180).max(180).required(),
    serviceRadiusKm: Joi.object({
        maxRadius: Joi.number().positive().required(),
        tiers: Joi.array().items(
            Joi.object({
                minKm: Joi.number().min(0).required(),
                maxKm: Joi.number().positive().required(),
                pricePerKm: Joi.number().positive().required()
            })
        ).min(1).required()
    }).required(),
    isActive: Joi.boolean().default(true),
    owner: Joi.object({
        fullName: Joi.string().min(3).max(255).required(),
        email: Joi.string().email().required(),
        phone: Joi.string().pattern(/^[6-9]\d{9}$/).required()
    }).required()
});

const updateMartSchema = Joi.object({
    martName: Joi.string().min(3).max(255),
    contactEmail: Joi.string().email(),
    address: Joi.string().min(10),
    latitude: Joi.number().min(-90).max(90),
    longitude: Joi.number().min(-180).max(180),
    serviceRadiusKm: Joi.object({
        maxRadius: Joi.number().positive(),
        tiers: Joi.array().items(
            Joi.object({
                minKm: Joi.number().min(0).required(),
                maxKm: Joi.number().positive().required(),
                pricePerKm: Joi.number().positive().required()
            })
        ).min(1)
    }),
    isActive: Joi.boolean()
}).min(1); // At least one field must be present

// ============================================================================
// ROUTES
// ============================================================================

/**
 * Complete mart registration (after OTP verifications)
 * POST /api/v1/marts/register
 * NOTE: Both mart phone and owner phone must be verified via OTP before calling this
 */
router.post(
    '/register',
    validate(registerMartSchema),
    martController.registerMart
);

/**
 * Get mart by ID
 * GET /api/v1/marts/:martId
 */
router.get(
    '/:martId',
    authenticateJWT,
    martController.getMartById
);

/**
 * Get all users of a mart
 * GET /api/v1/marts/:martId/users
 */
router.get(
    '/:martId/users',
    authenticateJWT,
    authorize('admin', 'manager'),
    martController.getMartUsers
);

/**
 * Update mart details
 * PATCH /api/v1/marts/:martId
 */
router.patch(
    '/:martId',
    authenticateJWT,
    authorize('admin'),
    validate(updateMartSchema),
    martController.updateMart
);

/**
 * Deactivate mart
 * DELETE /api/v1/marts/:martId
 */
router.delete(
    '/:martId',
    authenticateJWT,
    authorize('admin'),
    martController.deactivateMart
);

module.exports = router;
