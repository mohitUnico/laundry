/**
 * Clothes Routes
 * Endpoints for clothes items management
 */

const express = require('express');
const router = express.Router();
const clothesController = require('../controllers/clothes.controller');
const { validate } = require('../middleware/validation.middleware');
const { authenticateJWT, authorize } = require('../middleware/auth.middleware');
const Joi = require('joi');

// ============================================================================
// VALIDATION SCHEMAS
// ============================================================================

const addClothesSchema = Joi.object({
    serviceId: Joi.string().uuid().required()
        .messages({
            'string.guid': 'serviceId must be a valid UUID',
            'any.required': 'serviceId is required'
        }),
    itemName: Joi.string().min(2).max(100).required()
        .messages({
            'string.min': 'itemName must be at least 2 characters',
            'string.max': 'itemName must not exceed 100 characters',
            'any.required': 'itemName is required'
        }),
    perUnitPrice: Joi.number().min(0).required()
        .messages({
            'number.base': 'perUnitPrice must be a number',
            'number.min': 'perUnitPrice must be 0 or greater',
            'any.required': 'perUnitPrice is required'
        }),
    iconUrl: Joi.string().uri().max(500).allow(null, ''),
    isActive: Joi.boolean().default(true),
    displayOrder: Joi.number().integer().min(0).default(0)
});

// ============================================================================
// ROUTES
// ============================================================================

/**
 * Add a clothes item to a service
 * POST /api/v1/clothes
 */
router.post(
    '/',
    authenticateJWT,
    authorize('admin', 'manager'),
    validate(addClothesSchema),
    clothesController.addClothesItem
);

module.exports = router;


