/**
 * Clothes Routes
 * Endpoints for service catalog (ServiceCategory, Service, ClothesItem)
 */

const express = require('express');
const router = express.Router();
const clothesController = require('../controllers/clothes.controller');
const { validate, validateQuery } = require('../middleware/validation.middleware');
const { authenticateJWT, authorize } = require('../middleware/auth.middleware');
const { catalogUpload, coerceCatalogFields } = require('../middleware/catalog-upload.middleware');
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
    foregroundColor: Joi.string().pattern(/^[0-9A-Fa-f]{6}$/),
    backgroundColor: Joi.string().pattern(/^[0-9A-Fa-f]{6}$/),
    displayOrder: Joi.number().integer().min(0).default(0),
    isActive: Joi.boolean().default(true),
});

const updateServiceCategorySchema = Joi.object({
    categoryName: Joi.string().min(2).max(100),
    description: Joi.string().max(1000).allow(null, ''),
    foregroundColor: Joi.string().pattern(/^[0-9A-Fa-f]{6}$/),
    backgroundColor: Joi.string().pattern(/^[0-9A-Fa-f]{6}$/),
    displayOrder: Joi.number().integer().min(0),
    isActive: Joi.boolean(),
});

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
    basePrice: Joi.number().min(0).default(0),
    perKgPrice: Joi.number().min(0).empty('').allow(null),
    includes: Joi.array().items(Joi.string().max(200)).default([]),
    excludes: Joi.array().items(Joi.string().max(200)).default([]),
    estimatedHours: Joi.number().integer().min(0).required(),
    isActive: Joi.boolean().default(true),
    displayOrder: Joi.number().integer().min(0).default(0),
});

const updateServiceSchema = Joi.object({
    categoryId: Joi.string().uuid(),
    serviceName: Joi.string().min(2).max(255),
    description: Joi.string().max(2000).allow(null, ''),
    basePrice: Joi.number().min(0),
    perKgPrice: Joi.number().min(0).empty('').allow(null),
    includes: Joi.array().items(Joi.string().max(200)),
    excludes: Joi.array().items(Joi.string().max(200)),
    estimatedHours: Joi.number().integer().min(0),
    isActive: Joi.boolean(),
    displayOrder: Joi.number().integer().min(0),
});

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
    perUnitPrice: Joi.number().greater(0).required(),
    isActive: Joi.boolean().default(true),
    displayOrder: Joi.number().integer().min(0).default(0),
});

const updateClothesItemSchema = Joi.object({
    serviceId: Joi.string().uuid(),
    itemName: Joi.string().min(2).max(100),
    perUnitPrice: Joi.number().greater(0),
    isActive: Joi.boolean(),
    displayOrder: Joi.number().integer().min(0),
});

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
router.post('/service-categories', authenticateJWT, authorize('admin', 'manager'), catalogUpload('categories', { required: true }), coerceCatalogFields, validate(createServiceCategorySchema), clothesController.createServiceCategory);
// List/get should be available to all authenticated users (customers, delivery staff, etc.)
router.get('/service-categories', authenticateJWT, validateQuery(listCategoriesQuerySchema), clothesController.listServiceCategories);
router.get('/service-categories/:categoryId', authenticateJWT, validateUuidParam('categoryId'), clothesController.getServiceCategory);
router.put('/service-categories/:categoryId', authenticateJWT, authorize('admin', 'manager'), validateUuidParam('categoryId'), catalogUpload('categories', { required: false }), coerceCatalogFields, validate(updateServiceCategorySchema), clothesController.updateServiceCategory);
router.delete('/service-categories/:categoryId', authenticateJWT, authorize('admin', 'manager'), validateUuidParam('categoryId'), clothesController.deleteServiceCategory);

/**
 * Services CRUD
 */
router.post('/services', authenticateJWT, authorize('admin', 'manager'), catalogUpload('services', { required: true }), coerceCatalogFields, validate(createServiceSchema), clothesController.createService);
// List/get should be available to all authenticated users (customers, delivery staff, etc.)
router.get('/services', authenticateJWT, validateQuery(listServicesQuerySchema), clothesController.listServices);
router.get('/services/:serviceId', authenticateJWT, validateUuidParam('serviceId'), clothesController.getService);
router.put('/services/:serviceId', authenticateJWT, authorize('admin', 'manager'), validateUuidParam('serviceId'), catalogUpload('services', { required: false }), coerceCatalogFields, validate(updateServiceSchema), clothesController.updateService);
router.delete('/services/:serviceId', authenticateJWT, authorize('admin', 'manager'), validateUuidParam('serviceId'), clothesController.deleteService);

/**
 * Clothes Items CRUD
 */
router.post('/clothes-items', authenticateJWT, authorize('admin', 'manager'), catalogUpload('clothes', { required: true }), coerceCatalogFields, validate(createClothesItemSchema), clothesController.createClothesItem);
// List/get should be available to all authenticated users (customers, delivery staff, etc.)
router.get('/clothes-items', authenticateJWT, validateQuery(listClothesItemsQuerySchema), clothesController.listClothesItems);
router.get('/clothes-items/:clothId', authenticateJWT, validateUuidParam('clothId'), clothesController.getClothesItem);
router.put('/clothes-items/:clothId', authenticateJWT, authorize('admin', 'manager'), validateUuidParam('clothId'), catalogUpload('clothes', { required: false }), coerceCatalogFields, validate(updateClothesItemSchema), clothesController.updateClothesItem);
router.delete('/clothes-items/:clothId', authenticateJWT, authorize('admin', 'manager'), validateUuidParam('clothId'), clothesController.deleteClothesItem);

/**
 * Backward-compatible alias (previously only supported adding a clothes item)
 * POST /api/v1/clothes
 */
router.post('/', authenticateJWT, authorize('admin', 'manager'), catalogUpload('clothes', { required: true }), coerceCatalogFields, validate(createClothesItemSchema), clothesController.createClothesItem);

module.exports = router;
module.exports.schemas = {
    createServiceCategorySchema,
    updateServiceCategorySchema,
    createServiceSchema,
    updateServiceSchema,
    createClothesItemSchema,
    updateClothesItemSchema,
};


