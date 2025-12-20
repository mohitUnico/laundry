/**
 * Service Routes
 * Endpoints for service catalog management
 */

const express = require('express');
const router = express.Router();
const serviceController = require('../controllers/service.controller');
const { validate } = require('../middleware/validation.middleware');
const { authenticateJWT, authorize } = require('../middleware/auth.middleware');
const Joi = require('joi');

// ============================================================================
// VALIDATION SCHEMAS
// ============================================================================

const addServiceSchema = Joi.object({
    categoryId: Joi.string().uuid().required()
        .messages({
            'string.guid': 'categoryId must be a valid UUID',
            'any.required': 'categoryId is required'
        }),
    serviceName: Joi.string().min(2).max(255).required()
        .messages({
            'string.min': 'serviceName must be at least 2 characters',
            'string.max': 'serviceName must not exceed 255 characters',
            'any.required': 'serviceName is required'
        }),
    description: Joi.string().max(1000).allow(null, '')
        .messages({
            'string.max': 'description must not exceed 1000 characters'
        }),
    basePrice: Joi.number().min(0).default(0)
        .messages({
            'number.min': 'basePrice must be 0 or greater'
        }),
    perKgPrice: Joi.number().min(0).allow(null)
        .messages({
            'number.min': 'perKgPrice must be 0 or greater'
        }),
    estimatedHours: Joi.number().integer().min(1).required()
        .messages({
            'number.integer': 'estimatedHours must be an integer',
            'number.min': 'estimatedHours must be at least 1',
            'any.required': 'estimatedHours is required'
        }),
    iconUrl: Joi.string().uri().max(500).allow(null, '')
        .messages({
            'string.uri': 'iconUrl must be a valid URL',
            'string.max': 'iconUrl must not exceed 500 characters'
        }),
    isActive: Joi.boolean().default(true),
    displayOrder: Joi.number().integer().min(0).default(0)
        .messages({
            'number.integer': 'displayOrder must be an integer',
            'number.min': 'displayOrder must be 0 or greater'
        })
});

const updateServiceSchema = Joi.object({
    categoryId: Joi.string().uuid()
        .messages({
            'string.guid': 'categoryId must be a valid UUID'
        }),
    serviceName: Joi.string().min(2).max(255)
        .messages({
            'string.min': 'serviceName must be at least 2 characters',
            'string.max': 'serviceName must not exceed 255 characters'
        }),
    description: Joi.string().max(1000).allow(null, '')
        .messages({
            'string.max': 'description must not exceed 1000 characters'
        }),
    basePrice: Joi.number().min(0)
        .messages({
            'number.min': 'basePrice must be 0 or greater'
        }),
    perKgPrice: Joi.number().min(0).allow(null)
        .messages({
            'number.min': 'perKgPrice must be 0 or greater'
        }),
    estimatedHours: Joi.number().integer().min(1)
        .messages({
            'number.integer': 'estimatedHours must be an integer',
            'number.min': 'estimatedHours must be at least 1'
        }),
    iconUrl: Joi.string().uri().max(500).allow(null, '')
        .messages({
            'string.uri': 'iconUrl must be a valid URL',
            'string.max': 'iconUrl must not exceed 500 characters'
        }),
    isActive: Joi.boolean(),
    displayOrder: Joi.number().integer().min(0)
        .messages({
            'number.integer': 'displayOrder must be an integer',
            'number.min': 'displayOrder must be 0 or greater'
        })
}).min(1); // At least one field must be present

// ============================================================================
// ROUTES
// ============================================================================

/**
 * Get all service categories
 * GET /api/v1/services/categories
 * Public endpoint (no auth required)
 */
router.get(
    '/categories',
    serviceController.getServiceCategories
);

/**
 * Get all services for a mart
 * GET /api/v1/services
 * Query params: categoryId (optional), isActive (optional)
 */
router.get(
    '/',
    authenticateJWT,
    authorize('admin', 'manager'),
    serviceController.getMartServices
);

/**
 * Add a new service to a mart
 * POST /api/v1/services
 */
router.post(
    '/',
    authenticateJWT,
    authorize('admin', 'manager'),
    validate(addServiceSchema),
    serviceController.addService
);

/**
 * Update a service
 * PATCH /api/v1/services/:serviceId
 */
router.patch(
    '/:serviceId',
    authenticateJWT,
    authorize('admin', 'manager'),
    validate(updateServiceSchema),
    serviceController.updateService
);

/**
 * Delete a service (soft delete)
 * DELETE /api/v1/services/:serviceId
 */
router.delete(
    '/:serviceId',
    authenticateJWT,
    authorize('admin', 'manager'),
    serviceController.deleteService
);

module.exports = router;

