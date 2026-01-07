/**
 * Clothes Routes
 * Endpoints for service catalog (ServiceCategory, Service, ClothesItem)
 */

const express = require('express');
const router = express.Router();
const clothesController = require('../controllers/clothes.controller');
const { validate, validateQuery } = require('../middleware/validation.middleware');
const { authenticateJWT, authorize } = require('../middleware/auth.middleware');
const { ValidationError } = require('../utils/errors');
const Joi = require('joi');

// ============================================================================
// VALIDATION SCHEMAS
// ============================================================================

const uuidParam = Joi.string().uuid().required();

const validateUuidParam = (paramName) => {
    return (req, _res, next) => {
        const { error } = uuidParam.validate(req.params[paramName]);
        if (error) {
            return next(new ValidationError('Validation failed', [{ field: paramName, message: error.message }]));
        }
        next();
    };
};

// -----------------------------
// Service Categories
// -----------------------------

const createServiceCategorySchema = Joi.object({
    categoryName: Joi.string().min(2).max(100).required(),
    description: Joi.string().max(1000).allow(null, ''),
    iconUrl: Joi.string().uri().max(500).allow(null, ''),
    displayOrder: Joi.number().integer().min(0).default(0),
    isActive: Joi.boolean().default(true),
});

const updateServiceCategorySchema = Joi.object({
    categoryName: Joi.string().min(2).max(100),
    description: Joi.string().max(1000).allow(null, ''),
    iconUrl: Joi.string().uri().max(500).allow(null, ''),
    displayOrder: Joi.number().integer().min(0),
    isActive: Joi.boolean(),
}).min(1);

const listCategoriesQuerySchema = Joi.object({
    isActive: Joi.boolean(),
});

// -----------------------------
// Services
// -----------------------------

const createServiceSchema = Joi.object({
    categoryId: Joi.string().uuid().required(),
    serviceName: Joi.string().min(2).max(255).required(),
    description: Joi.string().max(2000).allow(null, ''),
    basePrice: Joi.number().min(0).required(),
    perKgPrice: Joi.number().min(0).allow(null),
    estimatedHours: Joi.number().integer().min(0).required(),
    iconUrl: Joi.string().uri().max(500).allow(null, ''),
    isActive: Joi.boolean().default(true),
    displayOrder: Joi.number().integer().min(0).default(0),
});

const updateServiceSchema = Joi.object({
    categoryId: Joi.string().uuid(),
    serviceName: Joi.string().min(2).max(255),
    description: Joi.string().max(2000).allow(null, ''),
    basePrice: Joi.number().min(0),
    perKgPrice: Joi.number().min(0).allow(null),
    estimatedHours: Joi.number().integer().min(0),
    iconUrl: Joi.string().uri().max(500).allow(null, ''),
    isActive: Joi.boolean(),
    displayOrder: Joi.number().integer().min(0),
}).min(1);

const listServicesQuerySchema = Joi.object({
    categoryId: Joi.string().uuid(),
    isActive: Joi.boolean(),
});

// -----------------------------
// Clothes Items
// -----------------------------

const createClothesItemSchema = Joi.object({
    // Required: must belong to a Service
    serviceId: Joi.string().uuid().required(),
    itemName: Joi.string().min(2).max(100).required(),
    perUnitPrice: Joi.number().min(0).required(),
    iconUrl: Joi.string().uri().max(500).allow(null, ''),
    isActive: Joi.boolean().default(true),
    displayOrder: Joi.number().integer().min(0).default(0),
});

const updateClothesItemSchema = Joi.object({
    serviceId: Joi.string().uuid(),
    itemName: Joi.string().min(2).max(100),
    perUnitPrice: Joi.number().min(0),
    iconUrl: Joi.string().uri().max(500).allow(null, ''),
    isActive: Joi.boolean(),
    displayOrder: Joi.number().integer().min(0),
}).min(1);

const listClothesItemsQuerySchema = Joi.object({
    serviceId: Joi.string().uuid(),
    isActive: Joi.boolean(),
});

// ============================================================================
// ROUTES
// ============================================================================

/**
 * Service Categories CRUD
 * Mounted at /api/v1/clothes
 */
router.post('/service-categories', authenticateJWT, authorize('admin', 'manager'), validate(createServiceCategorySchema), clothesController.createServiceCategory);
router.get('/service-categories', authenticateJWT, authorize('admin', 'manager'), validateQuery(listCategoriesQuerySchema), clothesController.listServiceCategories);
router.get('/service-categories/:categoryId', authenticateJWT, authorize('admin', 'manager'), validateUuidParam('categoryId'), clothesController.getServiceCategory);
router.put('/service-categories/:categoryId', authenticateJWT, authorize('admin', 'manager'), validateUuidParam('categoryId'), validate(updateServiceCategorySchema), clothesController.updateServiceCategory);
router.delete('/service-categories/:categoryId', authenticateJWT, authorize('admin', 'manager'), validateUuidParam('categoryId'), clothesController.deleteServiceCategory);

/**
 * Services CRUD
 */
router.post('/services', authenticateJWT, authorize('admin', 'manager'), validate(createServiceSchema), clothesController.createService);
router.get('/services', authenticateJWT, authorize('admin', 'manager'), validateQuery(listServicesQuerySchema), clothesController.listServices);
router.get('/services/:serviceId', authenticateJWT, authorize('admin', 'manager'), validateUuidParam('serviceId'), clothesController.getService);
router.put('/services/:serviceId', authenticateJWT, authorize('admin', 'manager'), validateUuidParam('serviceId'), validate(updateServiceSchema), clothesController.updateService);
router.delete('/services/:serviceId', authenticateJWT, authorize('admin', 'manager'), validateUuidParam('serviceId'), clothesController.deleteService);

/**
 * Clothes Items CRUD
 */
router.post('/clothes-items', authenticateJWT, authorize('admin', 'manager'), validate(createClothesItemSchema), clothesController.createClothesItem);
router.get('/clothes-items', authenticateJWT, authorize('admin', 'manager'), validateQuery(listClothesItemsQuerySchema), clothesController.listClothesItems);
router.get('/clothes-items/:clothId', authenticateJWT, authorize('admin', 'manager'), validateUuidParam('clothId'), clothesController.getClothesItem);
router.put('/clothes-items/:clothId', authenticateJWT, authorize('admin', 'manager'), validateUuidParam('clothId'), validate(updateClothesItemSchema), clothesController.updateClothesItem);
router.delete('/clothes-items/:clothId', authenticateJWT, authorize('admin', 'manager'), validateUuidParam('clothId'), clothesController.deleteClothesItem);

/**
 * Backward-compatible alias (previously only supported adding a clothes item)
 * POST /api/v1/clothes
 */
router.post('/', authenticateJWT, authorize('admin', 'manager'), validate(createClothesItemSchema), clothesController.createClothesItem);

module.exports = router;


