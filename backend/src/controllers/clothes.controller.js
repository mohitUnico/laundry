/**
 * Clothes Controller
 * Handles HTTP requests for service catalog (ServiceCategory, Service, ClothesItem)
 */

const clothesService = require('../services/clothes.service');

// ============================================================================
// SERVICE CATEGORIES
// ============================================================================

exports.createServiceCategory = async (req, res, next) => {
    try {
        const category = await clothesService.createServiceCategory(req.body);
        res.status(201).json({
            success: true,
            data: category,
            message: 'Service category created successfully',
        });
    } catch (error) {
        next(error);
    }
};

exports.listServiceCategories = async (req, res, next) => {
    try {
        const categories = await clothesService.listServiceCategories(req.query);
        res.status(200).json({
            success: true,
            data: categories,
            message: 'Service categories fetched successfully',
        });
    } catch (error) {
        next(error);
    }
};

exports.getServiceCategory = async (req, res, next) => {
    try {
        const category = await clothesService.getServiceCategoryById(req.params.categoryId);
        res.status(200).json({
            success: true,
            data: category,
            message: 'Service category fetched successfully',
        });
    } catch (error) {
        next(error);
    }
};

exports.updateServiceCategory = async (req, res, next) => {
    try {
        const category = await clothesService.updateServiceCategory(req.params.categoryId, req.body);
        res.status(200).json({
            success: true,
            data: category,
            message: 'Service category updated successfully',
        });
    } catch (error) {
        next(error);
    }
};

exports.deleteServiceCategory = async (req, res, next) => {
    try {
        await clothesService.deleteServiceCategory(req.params.categoryId);
        res.status(200).json({
            success: true,
            data: null,
            message: 'Service category deleted successfully',
        });
    } catch (error) {
        next(error);
    }
};

// ============================================================================
// SERVICES
// ============================================================================

exports.createService = async (req, res, next) => {
    try {
        const service = await clothesService.createService(req.body);
        res.status(201).json({
            success: true,
            data: service,
            message: 'Service created successfully',
        });
    } catch (error) {
        next(error);
    }
};

exports.listServices = async (req, res, next) => {
    try {
        const services = await clothesService.listServices(req.query);
        res.status(200).json({
            success: true,
            data: services,
            message: 'Services fetched successfully',
        });
    } catch (error) {
        next(error);
    }
};

exports.getService = async (req, res, next) => {
    try {
        const service = await clothesService.getServiceById(req.params.serviceId);
        res.status(200).json({
            success: true,
            data: service,
            message: 'Service fetched successfully',
        });
    } catch (error) {
        next(error);
    }
};

exports.updateService = async (req, res, next) => {
    try {
        const service = await clothesService.updateService(req.params.serviceId, req.body);
        res.status(200).json({
            success: true,
            data: service,
            message: 'Service updated successfully',
        });
    } catch (error) {
        next(error);
    }
};

exports.deleteService = async (req, res, next) => {
    try {
        await clothesService.deleteService(req.params.serviceId);
        res.status(200).json({
            success: true,
            data: null,
            message: 'Service deleted successfully',
        });
    } catch (error) {
        next(error);
    }
};

// ============================================================================
// CLOTHES ITEMS
// ============================================================================

exports.createClothesItem = async (req, res, next) => {
    try {
        const item = await clothesService.createClothesItem(req.body);
        res.status(201).json({
            success: true,
            data: item,
            message: 'Clothes item created successfully',
        });
    } catch (error) {
        next(error);
    }
};

exports.listClothesItems = async (req, res, next) => {
    try {
        const items = await clothesService.listClothesItems(req.query);
        res.status(200).json({
            success: true,
            data: items,
            message: 'Clothes items fetched successfully',
        });
    } catch (error) {
        next(error);
    }
};

exports.getClothesItem = async (req, res, next) => {
    try {
        const item = await clothesService.getClothesItemById(req.params.clothId);
        res.status(200).json({
            success: true,
            data: item,
            message: 'Clothes item fetched successfully',
        });
    } catch (error) {
        next(error);
    }
};

exports.updateClothesItem = async (req, res, next) => {
    try {
        const item = await clothesService.updateClothesItem(req.params.clothId, req.body);
        res.status(200).json({
            success: true,
            data: item,
            message: 'Clothes item updated successfully',
        });
    } catch (error) {
        next(error);
    }
};

exports.deleteClothesItem = async (req, res, next) => {
    try {
        await clothesService.deleteClothesItem(req.params.clothId);
        res.status(200).json({
            success: true,
            data: null,
            message: 'Clothes item deleted successfully',
        });
    } catch (error) {
        next(error);
    }
};

module.exports = exports;


