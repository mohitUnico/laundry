/**
 * Service Controller
 * Handles HTTP requests for service catalog operations
 */

const serviceService = require('../services/service.service');
const logger = require('../utils/logger');

/**
 * Add a new service to a mart
 * POST /api/v1/services
 */
exports.addService = async (req, res, next) => {
    try {
        const martId = req.user.mart_id; // Extracted from JWT token
        const serviceData = req.body;

        const service = await serviceService.addService(martId, serviceData);

        logger.info('Service added', {
            serviceId: service.service_id,
            martId,
            correlationId: req.correlationId
        });

        res.status(201).json({
            success: true,
            data: service,
            message: 'Service added successfully'
        });
    } catch (error) {
        next(error);
    }
};

/**
 * Get all services for a mart
 * GET /api/v1/services
 */
exports.getMartServices = async (req, res, next) => {
    try {
        const martId = req.user.mart_id; // Extracted from JWT token
        const { categoryId, isActive } = req.query;

        const services = await serviceService.getMartServices(martId, {
            categoryId,
            isActive
        });

        res.status(200).json({
            success: true,
            data: services
        });
    } catch (error) {
        next(error);
    }
};

/**
 * Get all service categories
 * GET /api/v1/services/categories
 */
exports.getServiceCategories = async (req, res, next) => {
    try {
        const categories = await serviceService.getServiceCategories();

        res.status(200).json({
            success: true,
            data: categories
        });
    } catch (error) {
        next(error);
    }
};

/**
 * Update a service
 * PATCH /api/v1/services/:serviceId
 */
exports.updateService = async (req, res, next) => {
    try {
        const { serviceId } = req.params;
        const martId = req.user.mart_id; // Extracted from JWT token
        const updateData = req.body;

        const service = await serviceService.updateService(serviceId, martId, updateData);

        logger.info('Service updated', {
            serviceId,
            martId,
            correlationId: req.correlationId
        });

        res.status(200).json({
            success: true,
            data: service,
            message: 'Service updated successfully'
        });
    } catch (error) {
        next(error);
    }
};

/**
 * Delete a service (soft delete)
 * DELETE /api/v1/services/:serviceId
 */
exports.deleteService = async (req, res, next) => {
    try {
        const { serviceId } = req.params;
        const martId = req.user.mart_id; // Extracted from JWT token

        await serviceService.deleteService(serviceId, martId);

        logger.info('Service deleted', {
            serviceId,
            martId,
            correlationId: req.correlationId
        });

        res.status(200).json({
            success: true,
            message: 'Service deleted successfully'
        });
    } catch (error) {
        next(error);
    }
};

module.exports = exports;

