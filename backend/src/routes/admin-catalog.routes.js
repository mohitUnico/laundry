const express = require('express');
const clothesRoutes = require('./clothes.routes');
const clothesController = require('../controllers/clothes.controller');
const { validate } = require('../middleware/validation.middleware');
const { authenticateJWT, authorize } = require('../middleware/auth.middleware');
const { validateUuidParam } = require('../middleware/delivery-staff-app.middleware');
const { catalogUpload, coerceCatalogFields } = require('../middleware/catalog-upload.middleware');
const { BadRequestError } = require('../utils/errors');

const router = express.Router();
const admin = [authenticateJWT, authorize('admin', 'manager')];
const {
    createServiceCategorySchema,
    updateServiceCategorySchema,
    createServiceSchema,
    updateServiceSchema,
    createClothesItemSchema,
    updateClothesItemSchema,
} = clothesRoutes.schemas;

function blank(value) {
    return value === undefined || value === '';
}

function jsonArray(value, field) {
    if (blank(value)) return undefined;
    if (Array.isArray(value)) return value;
    try {
        const parsed = JSON.parse(value);
        if (!Array.isArray(parsed) || parsed.some((item) => typeof item !== 'string')) {
            throw new Error('not an array of strings');
        }
        return parsed;
    } catch {
        throw new BadRequestError(`${field} must be a JSON array of strings`);
    }
}

function keep(fields) {
    return Object.fromEntries(Object.entries(fields).filter(([, value]) => value !== undefined));
}

function mapCategory(req, _res, next) {
    try {
        const body = req.body || {};
        req.body = keep({
            categoryName: blank(body.category_name) ? undefined : body.category_name,
            description: body.description,
            foregroundColor: blank(body.foreground_color) ? undefined : body.foreground_color,
            backgroundColor: blank(body.background_color) ? undefined : body.background_color,
            displayOrder: blank(body.display_order) ? undefined : body.display_order,
            isActive: blank(body.is_active) ? undefined : body.is_active,
        });
        next();
    } catch (error) {
        next(error);
    }
}

function mapService(req, _res, next) {
    try {
        const body = req.body || {};
        const perKgPrice = body.per_kg_price === undefined ? undefined : (body.per_kg_price === '' ? null : body.per_kg_price);
        req.body = keep({
            categoryId: blank(body.category_id) ? undefined : body.category_id,
            serviceName: blank(body.service_name) ? undefined : body.service_name,
            description: body.description,
            basePrice: blank(body.base_price) ? undefined : body.base_price,
            perKgPrice,
            estimatedHours: blank(body.estimated_hours) ? undefined : body.estimated_hours,
            includes: jsonArray(body.includes, 'includes'),
            excludes: jsonArray(body.excludes, 'excludes'),
            displayOrder: blank(body.display_order) ? undefined : body.display_order,
            isActive: blank(body.is_active) ? undefined : body.is_active,
        });
        next();
    } catch (error) {
        next(error);
    }
}

function mapClothes(req, _res, next) {
    try {
        const body = req.body || {};
        req.body = keep({
            serviceId: blank(body.service_id) ? undefined : body.service_id,
            itemName: blank(body.item_name) ? undefined : body.item_name,
            perUnitPrice: blank(body.per_unit_price) ? undefined : body.per_unit_price,
            displayOrder: blank(body.display_order) ? undefined : body.display_order,
            isActive: blank(body.is_active) ? undefined : body.is_active,
        });
        next();
    } catch (error) {
        next(error);
    }
}

router.post(
    '/categories',
    ...admin,
    catalogUpload('categories', { required: true }),
    mapCategory,
    validate(createServiceCategorySchema),
    clothesController.createServiceCategory
);

router.patch(
    '/categories/:categoryId',
    ...admin,
    validateUuidParam('categoryId'),
    catalogUpload('categories', { required: false }),
    mapCategory,
    validate(updateServiceCategorySchema),
    clothesController.updateServiceCategory
);

router.post(
    '/services',
    ...admin,
    catalogUpload('services', { required: true }),
    mapService,
    coerceCatalogFields,
    validate(createServiceSchema),
    clothesController.createService
);

router.patch(
    '/services/:serviceId',
    ...admin,
    validateUuidParam('serviceId'),
    catalogUpload('services', { required: false }),
    mapService,
    coerceCatalogFields,
    validate(updateServiceSchema),
    clothesController.updateService
);

router.post(
    '/clothes-items',
    ...admin,
    catalogUpload('clothes', { required: true }),
    mapClothes,
    validate(createClothesItemSchema),
    clothesController.createClothesItem
);

router.patch(
    '/clothes-items/:clothId',
    ...admin,
    validateUuidParam('clothId'),
    catalogUpload('clothes', { required: false }),
    mapClothes,
    validate(updateClothesItemSchema),
    clothesController.updateClothesItem
);

module.exports = router;
