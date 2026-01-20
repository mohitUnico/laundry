/**
 * Clothes Service
 * Handles business logic for service catalog (ServiceCategory, Service, ClothesItem)
 */

const prisma = require('../config/database');
const logger = require('../utils/logger');
const { AppError, ValidationError, NotFoundError } = require('../utils/errors');

class ClothesService {
    /**
     * Ensure a record exists.
     * @param {string} resourceName
     * @param {Object|null} record
     */
    _ensureFound(resourceName, record) {
        if (!record) throw new NotFoundError(resourceName);
    }

    // =========================================================================
    // SERVICE CATEGORIES
    // =========================================================================

    async createServiceCategory(data) {
        try {
            const category = await prisma.serviceCategory.create({
                data: {
                    category_name: data.categoryName,
                    description: data.description || null,
                    icon_url: data.iconUrl || null,
                    display_order: data.displayOrder ?? 0,
                    is_active: data.isActive ?? true,
                },
            });

            logger.info('Service category created', { categoryId: category.category_id });
            return category;
        } catch (error) {
            logger.error('Failed to create service category', { error: error.message });
            throw error;
        }
    }

    async listServiceCategories(query = {}) {
        const { isActive } = query;
        try {
            const where = {};
            if (typeof isActive === 'boolean') where.is_active = isActive;

            return await prisma.serviceCategory.findMany({
                where,
                orderBy: [{ display_order: 'asc' }, { created_at: 'desc' }],
                // List endpoint should return only categories (no nested services)
            });
        } catch (error) {
            logger.error('Failed to list service categories', { error: error.message });
            throw error;
        }
    }

    async getServiceCategoryById(categoryId) {
        try {
            const category = await prisma.serviceCategory.findUnique({
                where: { category_id: categoryId },
                include: {
                    services: {
                        orderBy: [{ display_order: 'asc' }, { created_at: 'desc' }],
                    },
                },
            });
            this._ensureFound('ServiceCategory', category);
            return category;
        } catch (error) {
            logger.error('Failed to get service category', { error: error.message, categoryId });
            throw error;
        }
    }

    async updateServiceCategory(categoryId, data) {
        try {
            await this.getServiceCategoryById(categoryId);

            const category = await prisma.serviceCategory.update({
                where: { category_id: categoryId },
                data: {
                    ...(data.categoryName !== undefined && { category_name: data.categoryName }),
                    ...(data.description !== undefined && { description: data.description }),
                    ...(data.iconUrl !== undefined && { icon_url: data.iconUrl }),
                    ...(data.displayOrder !== undefined && { display_order: data.displayOrder }),
                    ...(data.isActive !== undefined && { is_active: data.isActive }),
                },
            });

            logger.info('Service category updated', { categoryId });
            return category;
        } catch (error) {
            logger.error('Failed to update service category', { error: error.message, categoryId });
            throw error;
        }
    }

    async deleteServiceCategory(categoryId) {
        try {
            await this.getServiceCategoryById(categoryId);

            const serviceCount = await prisma.service.count({
                where: { category_id: categoryId },
            });
            if (serviceCount > 0) {
                throw new ValidationError('Cannot delete category while services exist under it');
            }

            await prisma.serviceCategory.delete({ where: { category_id: categoryId } });
            logger.info('Service category deleted', { categoryId });
        } catch (error) {
            logger.error('Failed to delete service category', { error: error.message, categoryId });
            throw error;
        }
    }

    // =========================================================================
    // SERVICES
    // =========================================================================

    async createService(data) {
        try {
            // Enforce: service requires valid category_id
            const category = await prisma.serviceCategory.findUnique({
                where: { category_id: data.categoryId },
                select: { category_id: true },
            });
            this._ensureFound('ServiceCategory', category);

            const service = await prisma.service.create({
                data: {
                    category_id: data.categoryId,
                    service_name: data.serviceName,
                    description: data.description || null,
                    base_price: data.basePrice,
                    per_kg_price: data.perKgPrice ?? null,
                    estimated_hours: data.estimatedHours,
                    icon_url: data.iconUrl || null,
                    is_active: data.isActive ?? true,
                    display_order: data.displayOrder ?? 0,
                },
                include: {
                    category: true,
                },
            });

            logger.info('Service created', { serviceId: service.service_id, categoryId: data.categoryId });
            return service;
        } catch (error) {
            logger.error('Failed to create service', { error: error.message });
            throw error;
        }
    }

    async listServices(query = {}) {
        const { categoryId, isActive } = query;
        try {
            const where = {
                ...(categoryId ? { category_id: categoryId } : {}),
                ...(typeof isActive === 'boolean' ? { is_active: isActive } : {}),
            };

            return await prisma.service.findMany({
                where,
                orderBy: [{ display_order: 'asc' }, { created_at: 'desc' }],
                include: {
                    // List endpoint should not include category details in each service
                    clothes_items: {
                        orderBy: [{ display_order: 'asc' }, { created_at: 'desc' }],
                    },
                },
            });
        } catch (error) {
            logger.error('Failed to list services', { error: error.message });
            throw error;
        }
    }

    async getServiceById(serviceId) {
        try {
            const service = await prisma.service.findUnique({
                where: { service_id: serviceId },
                include: {
                    category: true,
                    clothes_items: {
                        orderBy: [{ display_order: 'asc' }, { created_at: 'desc' }],
                    },
                    service_man: true,
                },
            });
            this._ensureFound('Service', service);
            return service;
        } catch (error) {
            logger.error('Failed to get service', { error: error.message, serviceId });
            throw error;
        }
    }

    async updateService(serviceId, data) {
        try {
            await this.getServiceById(serviceId);

            if (data.categoryId !== undefined) {
                const category = await prisma.serviceCategory.findUnique({
                    where: { category_id: data.categoryId },
                    select: { category_id: true },
                });
                this._ensureFound('ServiceCategory', category);
            }

            const service = await prisma.service.update({
                where: { service_id: serviceId },
                data: {
                    ...(data.categoryId !== undefined && { category_id: data.categoryId }),
                    ...(data.serviceName !== undefined && { service_name: data.serviceName }),
                    ...(data.description !== undefined && { description: data.description }),
                    ...(data.basePrice !== undefined && { base_price: data.basePrice }),
                    ...(data.perKgPrice !== undefined && { per_kg_price: data.perKgPrice }),
                    ...(data.estimatedHours !== undefined && { estimated_hours: data.estimatedHours }),
                    ...(data.iconUrl !== undefined && { icon_url: data.iconUrl }),
                    ...(data.isActive !== undefined && { is_active: data.isActive }),
                    ...(data.displayOrder !== undefined && { display_order: data.displayOrder }),
                },
                include: { category: true },
            });

            logger.info('Service updated', { serviceId });
            return service;
        } catch (error) {
            logger.error('Failed to update service', { error: error.message, serviceId });
            throw error;
        }
    }

    async deleteService(serviceId) {
        try {
            await this.getServiceById(serviceId);

            const [clothesCount, cartCount, queueCount, staffCount] = await Promise.all([
                prisma.clothesItem.count({ where: { service_id: serviceId } }),
                prisma.cartItem.count({ where: { service_id: serviceId } }),
                prisma.serviceQueueItem.count({ where: { service_id: serviceId } }),
                prisma.staff.count({ where: { service_id: serviceId } }),
            ]);

            if (clothesCount > 0) throw new ValidationError('Cannot delete service while clothes items exist under it');
            if (cartCount > 0) throw new ValidationError('Cannot delete service while it is referenced by cart items');
            if (queueCount > 0) throw new ValidationError('Cannot delete service while it is referenced by service queue items');
            if (staffCount > 0) throw new ValidationError('Cannot delete service while a staff member is assigned to it');

            await prisma.service.delete({ where: { service_id: serviceId } });
            logger.info('Service deleted', { serviceId });
        } catch (error) {
            logger.error('Failed to delete service', { error: error.message, serviceId });
            throw error;
        }
    }

    // =========================================================================
    // CLOTHES ITEMS
    // =========================================================================

    async createClothesItem(data) {
        try {
            // Enforce: clothes item requires valid service_id
            const svc = await prisma.service.findUnique({
                where: { service_id: data.serviceId },
                select: { service_id: true, is_active: true },
            });
            this._ensureFound('Service', svc);
            if (!svc.is_active) throw new ValidationError('Cannot add clothes items to an inactive service');

            // Ensure unique name within service
            const existing = await prisma.clothesItem.findFirst({
                where: { service_id: data.serviceId, item_name: data.itemName },
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
                    display_order: data.displayOrder ?? 0,
                },
                include: {
                    service: {
                        select: { service_id: true, service_name: true, category_id: true },
                    },
                },
            });

            logger.info('Clothes item created', { clothesItemId: item.cloth_id, serviceId: data.serviceId });

            return item;
        } catch (error) {
            logger.error('Failed to create clothes item', { error: error.message });
            throw error;
        }
    }

    async listClothesItems(query = {}) {
        const { serviceId, isActive } = query;
        try {
            const where = {
                ...(serviceId ? { service_id: serviceId } : {}),
                ...(typeof isActive === 'boolean' ? { is_active: isActive } : {}),
            };

            return await prisma.clothesItem.findMany({
                where,
                orderBy: [{ display_order: 'asc' }, { created_at: 'desc' }],
                // List endpoint should not include service details in each clothes item
            });
        } catch (error) {
            logger.error('Failed to list clothes items', { error: error.message });
            throw error;
        }
    }

    async getClothesItemById(clothId) {
        try {
            const item = await prisma.clothesItem.findUnique({
                where: { cloth_id: clothId },
                include: {
                    service: {
                        include: { category: true },
                    },
                },
            });
            this._ensureFound('ClothesItem', item);
            return item;
        } catch (error) {
            logger.error('Failed to get clothes item', { error: error.message, clothId });
            throw error;
        }
    }

    async updateClothesItem(clothId, data) {
        try {
            const existingItem = await this.getClothesItemById(clothId);

            const targetServiceId = data.serviceId !== undefined ? data.serviceId : existingItem.service_id;

            if (data.serviceId !== undefined) {
                const svc = await prisma.service.findUnique({
                    where: { service_id: data.serviceId },
                    select: { service_id: true, is_active: true },
                });
                this._ensureFound('Service', svc);
                if (!svc.is_active) throw new ValidationError('Cannot move clothes item to an inactive service');
            }

            const targetItemName = data.itemName !== undefined ? data.itemName : existingItem.item_name;
            // If either key part changes, enforce unique constraint proactively
            if (targetServiceId !== existingItem.service_id || targetItemName !== existingItem.item_name) {
                const dup = await prisma.clothesItem.findFirst({
                    where: {
                        service_id: targetServiceId,
                        item_name: targetItemName,
                        NOT: { cloth_id: clothId },
                    },
                    select: { cloth_id: true },
                });
                if (dup) throw new ValidationError('A clothes item with this name already exists for this service');
            }

            const item = await prisma.clothesItem.update({
                where: { cloth_id: clothId },
                data: {
                    ...(data.serviceId !== undefined && { service_id: data.serviceId }),
                    ...(data.itemName !== undefined && { item_name: data.itemName }),
                    ...(data.perUnitPrice !== undefined && { per_unit_price: data.perUnitPrice }),
                    ...(data.iconUrl !== undefined && { icon_url: data.iconUrl }),
                    ...(data.isActive !== undefined && { is_active: data.isActive }),
                    ...(data.displayOrder !== undefined && { display_order: data.displayOrder }),
                },
                include: {
                    service: { include: { category: true } },
                },
            });

            logger.info('Clothes item updated', { clothId });
            return item;
        } catch (error) {
            logger.error('Failed to update clothes item', { error: error.message, clothId });
            throw error;
        }
    }

    async deleteClothesItem(clothId) {
        try {
            await this.getClothesItemById(clothId);

            const [orderItemCount, cartSelCount] = await Promise.all([
                prisma.orderItem.count({ where: { item_id: clothId } }),
                prisma.cartItemSelection.count({ where: { cloth_id: clothId } }),
            ]);

            if (orderItemCount > 0) {
                throw new ValidationError('Cannot delete clothes item while it is referenced by order items');
            }
            if (cartSelCount > 0) {
                throw new ValidationError('Cannot delete clothes item while it is referenced by cart item selections');
            }

            await prisma.clothesItem.delete({ where: { cloth_id: clothId } });
            logger.info('Clothes item deleted', { clothId });
        } catch (error) {
            logger.error('Failed to delete clothes item', { error: error.message, clothId });
            throw error;
        }
    }
}

module.exports = new ClothesService();


