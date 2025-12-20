/**
 * Clothes Service
 * Handles business logic for clothes items management
 */

const { PrismaClient } = require('@prisma/client');
const prisma = new PrismaClient();
const logger = require('../utils/logger');
const { AppError, ValidationError, NotFoundError } = require('../utils/errors');

class ClothesService {
    /**
     * Add a new clothes item to a service (scoped to a mart)
     * @param {string} martId
     * @param {Object} data
     * @returns {Promise<Object>}
     */
    async addClothesItem(martId, data) {
        try {
            // Validate service belongs to mart
            const svc = await prisma.service.findUnique({
                where: { service_id: data.serviceId },
                select: { service_id: true, mart_id: true, is_active: true }
            });
            if (!svc) throw new NotFoundError('Service');
            if (svc.mart_id !== martId) throw new AppError('Service does not belong to this mart', 403);
            if (!svc.is_active) throw new ValidationError('Cannot add clothes to an inactive service');

            // Ensure unique name within service
            const existing = await prisma.clothesItem.findFirst({
                where: { service_id: data.serviceId, item_name: data.itemName }
            });
            if (existing) throw new ValidationError('A clothes item with this name already exists for this service');

            // Create clothes item
            const item = await prisma.clothesItem.create({
                data: {
                    service_id: data.serviceId,
                    item_name: data.itemName,
                    per_unit_price: data.perUnitPrice,
                    icon_url: data.iconUrl || null,
                    is_active: data.isActive !== undefined ? data.isActive : true,
                    display_order: data.displayOrder || 0
                },
                include: {
                    service: {
                        select: { service_id: true, service_name: true }
                    }
                }
            });

            logger.info('Clothes item created', {
                clothesItemId: item.cloth_id,
                serviceId: data.serviceId,
                martId
            });

            return item;
        } catch (error) {
            logger.error('Failed to add clothes item', {
                error: error.message,
                martId,
            });
            throw error;
        }
    }
}

module.exports = new ClothesService();


