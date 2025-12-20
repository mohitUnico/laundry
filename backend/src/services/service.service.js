/**
 * Service Service
 * Handles business logic for service catalog management
 */

const { PrismaClient } = require('@prisma/client');
const prisma = new PrismaClient();
const logger = require('../utils/logger');
const { AppError, ValidationError, NotFoundError } = require('../utils/errors');

class ServiceService {
    /**
     * Create default services for a new mart
     * This is called automatically when a new mart is registered
     * @param {string} martId - Mart ID
     * @returns {Promise<Object>} Created services count
     */
    async createDefaultServices(martId) {
        try {
            // Verify mart exists
            const mart = await prisma.laundryMart.findUnique({
                where: { mart_id: martId }
            });

            if (!mart) {
                throw new NotFoundError('Mart');
            }

            // Get all service categories
            const categories = await prisma.serviceCategory.findMany({
                where: { is_active: true },
                orderBy: { display_order: 'asc' }
            });

            // Create a map of category names to IDs
            const categoryMap = {};
            categories.forEach(cat => {
                categoryMap[cat.category_name] = cat.category_id;
            });

            const now = new Date();

            // Define default services based on categories
            const defaultServices = [
                // Regular Wash services
                {
                    category_id: categoryMap['Regular Wash'],
                    mart_id: martId,
                    service_name: 'Wash and Fold',
                    description: 'Professional washing and folding service',
                    base_price: 0.00,
                    per_kg_price: 4,
                    estimated_hours: 4,
                    icon_url: 'https://picsum.photos/seed/wash-fold/200/200',
                    is_active: true,
                    display_order: 1,
                    created_at: now,
                    updated_at: now,
                },
                {
                    category_id: categoryMap['Regular Wash'],
                    mart_id: martId,
                    service_name: 'Wash and Iron',
                    description: 'Professional washing and Ironing service',
                    base_price: 0.00,
                    per_kg_price: 5,
                    estimated_hours: 6,
                    icon_url: 'https://picsum.photos/seed/wash-iron/200/200',
                    is_active: true,
                    display_order: 2,
                    created_at: now,
                    updated_at: now,
                },
                {
                    category_id: categoryMap['Regular Wash'],
                    mart_id: martId,
                    service_name: 'Stain Removal',
                    description: 'Professional Handwash Service',
                    base_price: 0.00,
                    per_kg_price: 8,
                    estimated_hours: 9,
                    icon_url: 'https://picsum.photos/seed/stain-removal/200/200',
                    is_active: true,
                    display_order: 3,
                    created_at: now,
                    updated_at: now,
                },
                // Pro Clean services
                {
                    category_id: categoryMap['Pro Clean'],
                    mart_id: martId,
                    service_name: 'Stain Removal',
                    description: 'Professional Stain removal service',
                    base_price: 0.00,
                    per_kg_price: 5,
                    estimated_hours: 6,
                    icon_url: 'https://picsum.photos/seed/pro-stain-removal/200/200',
                    is_active: true,
                    display_order: 1,
                    created_at: now,
                    updated_at: now,
                },
                {
                    category_id: categoryMap['Pro Clean'],
                    mart_id: martId,
                    service_name: 'Dry Clean',
                    description: 'Professional Dry cleaning service',
                    base_price: 0.00,
                    per_kg_price: 5,
                    estimated_hours: 6,
                    icon_url: 'https://picsum.photos/seed/dry-clean/200/200',
                    is_active: true,
                    display_order: 2,
                    created_at: now,
                    updated_at: now,
                },
                {
                    category_id: categoryMap['Pro Clean'],
                    mart_id: martId,
                    service_name: 'Shoe Cleaning',
                    description: 'Professional Shoe Cleaning service',
                    base_price: 0.00,
                    per_kg_price: 5,
                    estimated_hours: 6,
                    icon_url: 'https://picsum.photos/seed/shoe-cleaning/200/200',
                    is_active: true,
                    display_order: 3,
                    created_at: now,
                    updated_at: now,
                },
                {
                    category_id: categoryMap['Pro Clean'],
                    mart_id: martId,
                    service_name: 'Winter Wear',
                    description: 'Professional winter wear cleaning service',
                    base_price: 0.00,
                    per_kg_price: 5,
                    estimated_hours: 6,
                    icon_url: 'https://picsum.photos/seed/winter-wear/200/200',
                    is_active: true,
                    display_order: 4,
                    created_at: now,
                    updated_at: now,
                },
                // Luxury Care services
                {
                    category_id: categoryMap['Luxury Care'],
                    mart_id: martId,
                    service_name: 'Steam Press',
                    description: 'Professional Steam Press service',
                    base_price: 0.00,
                    per_kg_price: 5,
                    estimated_hours: 6,
                    icon_url: 'https://picsum.photos/seed/steam-press/200/200',
                    is_active: true,
                    display_order: 1,
                    created_at: now,
                    updated_at: now,
                },
                {
                    category_id: categoryMap['Luxury Care'],
                    mart_id: martId,
                    service_name: 'Designer Wear',
                    description: 'Professional designer wear washing service',
                    base_price: 0.00,
                    per_kg_price: 5,
                    estimated_hours: 6,
                    icon_url: 'https://picsum.photos/seed/designer-wear/200/200',
                    is_active: true,
                    display_order: 2,
                    created_at: now,
                    updated_at: now,
                },
                // Home Linens services
                {
                    category_id: categoryMap['Home Linens'],
                    mart_id: martId,
                    service_name: 'Carpet',
                    description: 'Professional Carpet Cleaning service',
                    base_price: 0.00,
                    per_kg_price: 5,
                    estimated_hours: 6,
                    icon_url: 'https://picsum.photos/seed/carpet/200/200',
                    is_active: true,
                    display_order: 1,
                    created_at: now,
                    updated_at: now,
                },
                {
                    category_id: categoryMap['Home Linens'],
                    mart_id: martId,
                    service_name: 'Curtains',
                    description: 'Professional Curtains Cleaning service',
                    base_price: 0.00,
                    per_kg_price: 5,
                    estimated_hours: 6,
                    icon_url: 'https://picsum.photos/seed/curtains/200/200',
                    is_active: true,
                    display_order: 1,
                    created_at: now,
                    updated_at: now,
                },
                {
                    category_id: categoryMap['Home Linens'],
                    mart_id: martId,
                    service_name: 'Blankets',
                    description: 'Professional Blankets Cleaning service',
                    base_price: 0.00,
                    per_kg_price: 5,
                    estimated_hours: 6,
                    icon_url: 'https://picsum.photos/seed/blankets/200/200',
                    is_active: true,
                    display_order: 2,
                    created_at: now,
                    updated_at: now,
                },
                {
                    category_id: categoryMap['Home Linens'],
                    mart_id: martId,
                    service_name: 'Bedsheets',
                    description: 'Professional Bedsheets Cleaning service',
                    base_price: 0.00,
                    per_kg_price: 5,
                    estimated_hours: 6,
                    icon_url: 'https://picsum.photos/seed/bedsheets/200/200',
                    is_active: true,
                    display_order: 1,
                    created_at: now,
                    updated_at: now,
                },
                // Add-On Services
                {
                    category_id: categoryMap['Add-On Services'],
                    mart_id: martId,
                    service_name: 'Express',
                    description: 'Express service for same day delivery(4-6 hours)',
                    base_price: 10.00,
                    per_kg_price: 0,
                    estimated_hours: 6,
                    icon_url: 'https://picsum.photos/seed/express/200/200',
                    is_active: true,
                    display_order: 1,
                    created_at: now,
                    updated_at: now,
                },
            ];

            // Filter out services where category doesn't exist
            const validServices = defaultServices.filter(service => service.category_id);

            if (validServices.length === 0) {
                logger.warn('No valid service categories found for default services', { martId });
                return { count: 0 };
            }

            // Create services in a transaction
            const result = await prisma.service.createMany({
                data: validServices,
                skipDuplicates: false
            });

            logger.info('Default services created for mart', {
                martId,
                servicesCreated: result.count
            });

            return { count: result.count };
        } catch (error) {
            logger.error('Failed to create default services', {
                error: error.message,
                martId
            });
            throw error;
        }
    }

    /**
     * Create default clothes items for key services for a mart
     * Idempotent: skips if clothes already exist for a given service
     * @param {string} martId
     * @returns {Promise<{count:number}>}
     */
    async createDefaultClothesForMart(martId) {
        try {
            // Get services for this mart to map by name
            const services = await prisma.service.findMany({
                where: { mart_id: martId, is_active: true },
                select: { service_id: true, service_name: true }
            });

            const nameToId = new Map(services.map(s => [s.service_name.toLowerCase(), s.service_id]));

            // Helper to build clothes entries
            const build = (serviceName, items) => {
                const sid = nameToId.get(serviceName.toLowerCase());
                if (!sid) return [];
                const now = new Date();
                return items.map(i => ({
                    service_id: sid,
                    item_name: i.name,
                    per_unit_price: i.price,
                    icon_url: i.icon,
                    is_active: true,
                    display_order: i.order,
                    created_at: now,
                    updated_at: now,
                }));
            };

            // Price/icon defaults
            const p = 4.0;
            const icon = (seed) => `https://picsum.photos/seed/${encodeURIComponent(seed)}/200/200`;

            // Definitions per requested mapping
            const defs = [
                // Regular Wash
                ...build('Wash and Fold', [
                    { name: 'top wear', price: p, icon: icon('top-wear'), order: 1 },
                    { name: 'bottom wear', price: p, icon: icon('bottom-wear'), order: 2 },
                    { name: 'kurti/kurta', price: p, icon: icon('kurta'), order: 3 },
                    { name: 'saree', price: p, icon: icon('saree'), order: 4 },
                    { name: 'lingerie', price: p, icon: icon('lingerie'), order: 5 },
                ]),
                ...build('Wash and Iron', [
                    { name: 'top wear', price: p, icon: icon('top-wear-iron'), order: 1 },
                    { name: 'bottom wear', price: p, icon: icon('bottom-wear-iron'), order: 2 },
                    { name: 'kurti/kurta', price: p, icon: icon('kurta-iron'), order: 3 },
                    { name: 'lingerie', price: p, icon: icon('lingerie-iron'), order: 4 },
                    { name: 'saree', price: p, icon: icon('saree-iron'), order: 4 }, // if both 4, unique still by name
                ]),
                // Interpret "handwash service" as 'Stain Removal' under Regular Wash
                ...build('Stain Removal', [
                    { name: 'top wear', price: p, icon: icon('top-wear-handwash'), order: 1 },
                    { name: 'bottom wear', price: p, icon: icon('bottom-wear-handwash'), order: 2 },
                    { name: 'kurti/kurta', price: p, icon: icon('kurta-handwash'), order: 3 },
                    { name: 'saree', price: p, icon: icon('saree-handwash'), order: 4 },
                    { name: 'lingerie', price: p, icon: icon('lingerie-handwash'), order: 5 },
                ]),
                // Pro Clean: Stain Removal (heavy/light)
                ...build('Stain Removal', [
                    { name: 'heavy stained', price: p, icon: icon('heavy-stained'), order: 1 },
                    { name: 'light stained', price: p, icon: icon('light-stained'), order: 4 },
                ]),
                ...build('Dry Clean', [
                    { name: 'top wear', price: p, icon: icon('top-wear-dry'), order: 1 },
                    { name: 'bottom wear', price: p, icon: icon('bottom-wear-dry'), order: 2 },
                    { name: 'kurta/kurti', price: p, icon: icon('kurta-dry'), order: 3 },
                    { name: 'saree', price: p, icon: icon('saree-dry'), order: 4 },
                ]),
                ...build('Shoe Cleaning', [
                    { name: 'sneakers', price: p, icon: icon('sneakers'), order: 1 },
                    { name: 'formal shoes', price: p, icon: icon('formal-shoes'), order: 2 },
                    { name: 'sports shoes', price: p, icon: icon('sports-shoes'), order: 3 },
                    { name: 'loafers', price: p, icon: icon('loafers'), order: 4 },
                ]),
                ...build('Winter Wear', [
                    { name: 'woolens', price: p, icon: icon('woolens'), order: 1 },
                    { name: 'Jackets', price: p, icon: icon('jackets'), order: 3 },
                    { name: 'cashmere sweaters', price: p, icon: icon('cashmere'), order: 4 },
                ]),
                ...build('Steam Press', [
                    { name: 'top wear', price: p, icon: icon('top-wear-press'), order: 1 },
                    { name: 'bottom wear', price: p, icon: icon('bottom-wear-press'), order: 2 },
                    { name: 'kurta/kurti', price: p, icon: icon('kurta-press'), order: 3 },
                    { name: 'saree', price: p, icon: icon('saree-press'), order: 4 },
                ]),
                ...build('Designer Wear', [
                    { name: 'top wear', price: p, icon: icon('top-wear-designer'), order: 1 },
                    { name: 'bottom wear', price: p, icon: icon('bottom-wear-designer'), order: 2 },
                    { name: 'kurta/kurti', price: p, icon: icon('kurta-designer'), order: 3 },
                    { name: 'saree', price: p, icon: icon('saree-designer'), order: 4 },
                ]),
            ].flat().filter(Boolean);

            if (defs.length === 0) return { count: 0 };

            // Filter out items that already exist by (service_id, item_name)
            // Create in batches per service to avoid duplicates
            let created = 0;
            const byService = defs.reduce((acc, d) => {
                (acc[d.service_id] ||= []).push(d);
                return acc;
            }, {});

            for (const [serviceId, items] of Object.entries(byService)) {
                const existing = await prisma.clothesItem.findMany({
                    where: { service_id: serviceId },
                    select: { item_name: true },
                });
                const existingNames = new Set(existing.map(e => e.item_name.toLowerCase()));
                const toCreate = items.filter(i => !existingNames.has(i.item_name.toLowerCase()));
                if (toCreate.length > 0) {
                    const res = await prisma.clothesItem.createMany({
                        data: toCreate,
                        skipDuplicates: true,
                    });
                    created += res.count;
                }
            }

            logger.info('Default clothes items created for mart', {
                martId,
                itemsCreated: created
            });

            return { count: created };
        } catch (error) {
            logger.error('Failed to create default clothes items', {
                error: error.message,
                martId
            });
            throw error;
        }
    }

    /**
     * Add a new service to a mart
     * @param {string} martId - Mart ID
     * @param {Object} serviceData - Service data
     * @returns {Promise<Object>} Created service
     */
    async addService(martId, serviceData) {
        try {
            // Verify mart exists
            const mart = await prisma.laundryMart.findUnique({
                where: { mart_id: martId }
            });

            if (!mart) {
                throw new NotFoundError('Mart');
            }

            // Verify category exists and is active
            const category = await prisma.serviceCategory.findUnique({
                where: { category_id: serviceData.categoryId }
            });

            if (!category) {
                throw new NotFoundError('Service Category');
            }

            if (!category.is_active) {
                throw new ValidationError('Cannot add service to an inactive category');
            }

            // Check if service with same name already exists for this mart
            const existingService = await prisma.service.findFirst({
                where: {
                    mart_id: martId,
                    service_name: serviceData.serviceName,
                    category_id: serviceData.categoryId
                }
            });

            if (existingService) {
                throw new ValidationError('A service with this name already exists in this category for your mart');
            }

            // Create service
            const service = await prisma.service.create({
                data: {
                    category_id: serviceData.categoryId,
                    mart_id: martId,
                    service_name: serviceData.serviceName,
                    description: serviceData.description || null,
                    base_price: serviceData.basePrice || 0,
                    per_kg_price: serviceData.perKgPrice || null,
                    estimated_hours: serviceData.estimatedHours,
                    icon_url: serviceData.iconUrl || null,
                    is_active: serviceData.isActive !== undefined ? serviceData.isActive : true,
                    display_order: serviceData.displayOrder || 0
                },
                include: {
                    category: {
                        select: {
                            category_id: true,
                            category_name: true,
                            description: true
                        }
                    }
                }
            });

            logger.info('Service added to mart', {
                serviceId: service.service_id,
                martId,
                serviceName: service.service_name
            });

            return service;
        } catch (error) {
            logger.error('Failed to add service', {
                error: error.message,
                martId,
                serviceName: serviceData.serviceName
            });
            throw error;
        }
    }

    /**
     * Get all services for a mart
     * @param {string} martId - Mart ID
     * @param {Object} options - Query options
     * @returns {Promise<Object>} Services list
     */
    async getMartServices(martId, options = {}) {
        try {
            const { categoryId, isActive } = options;

            // Verify mart exists
            const mart = await prisma.laundryMart.findUnique({
                where: { mart_id: martId }
            });

            if (!mart) {
                throw new NotFoundError('Mart');
            }

            const where = { mart_id: martId };

            if (categoryId) {
                where.category_id = categoryId;
            }

            if (isActive !== undefined) {
                where.is_active = isActive === 'true' || isActive === true;
            }

            const services = await prisma.service.findMany({
                where,
                include: {
                    category: {
                        select: {
                            category_id: true,
                            category_name: true,
                            description: true,
                            icon_url: true
                        }
                    }
                },
                orderBy: [
                    { category: { display_order: 'asc' } },
                    { display_order: 'asc' }
                ]
            });

            return services;
        } catch (error) {
            logger.error('Failed to get mart services', {
                error: error.message,
                martId
            });
            throw error;
        }
    }

    /**
     * Get all service categories
     * @returns {Promise<Array>} Service categories
     */
    async getServiceCategories() {
        try {
            const categories = await prisma.serviceCategory.findMany({
                where: { is_active: true },
                orderBy: { display_order: 'asc' }
            });

            return categories;
        } catch (error) {
            logger.error('Failed to get service categories', {
                error: error.message
            });
            throw error;
        }
    }

    /**
     * Update a service
     * @param {string} serviceId - Service ID
     * @param {string} martId - Mart ID (for authorization)
     * @param {Object} updateData - Update data
     * @returns {Promise<Object>} Updated service
     */
    async updateService(serviceId, martId, updateData) {
        try {
            // Verify service exists and belongs to mart
            const service = await prisma.service.findUnique({
                where: { service_id: serviceId }
            });

            if (!service) {
                throw new NotFoundError('Service');
            }

            if (service.mart_id !== martId) {
                throw new AppError('Service does not belong to this mart', 403);
            }

            // If category is being updated, verify it exists
            if (updateData.categoryId) {
                const category = await prisma.serviceCategory.findUnique({
                    where: { category_id: updateData.categoryId }
                });

                if (!category) {
                    throw new NotFoundError('Service Category');
                }
            }

            // Build update object
            const dataToUpdate = {};
            if (updateData.categoryId) dataToUpdate.category_id = updateData.categoryId;
            if (updateData.serviceName) dataToUpdate.service_name = updateData.serviceName;
            if (updateData.description !== undefined) dataToUpdate.description = updateData.description;
            if (updateData.basePrice !== undefined) dataToUpdate.base_price = updateData.basePrice;
            if (updateData.perKgPrice !== undefined) dataToUpdate.per_kg_price = updateData.perKgPrice;
            if (updateData.estimatedHours !== undefined) dataToUpdate.estimated_hours = updateData.estimatedHours;
            if (updateData.iconUrl !== undefined) dataToUpdate.icon_url = updateData.iconUrl;
            if (updateData.isActive !== undefined) dataToUpdate.is_active = updateData.isActive;
            if (updateData.displayOrder !== undefined) dataToUpdate.display_order = updateData.displayOrder;

            // Update service
            const updatedService = await prisma.service.update({
                where: { service_id: serviceId },
                data: dataToUpdate,
                include: {
                    category: {
                        select: {
                            category_id: true,
                            category_name: true,
                            description: true
                        }
                    }
                }
            });

            logger.info('Service updated', {
                serviceId,
                martId,
                updatedFields: Object.keys(dataToUpdate)
            });

            return updatedService;
        } catch (error) {
            logger.error('Failed to update service', {
                error: error.message,
                serviceId,
                martId
            });
            throw error;
        }
    }

    /**
     * Delete a service (soft delete by setting is_active to false)
     * @param {string} serviceId - Service ID
     * @param {string} martId - Mart ID (for authorization)
     * @returns {Promise<Object>} Deleted service
     */
    async deleteService(serviceId, martId) {
        try {
            // Verify service exists and belongs to mart
            const service = await prisma.service.findUnique({
                where: { service_id: serviceId }
            });

            if (!service) {
                throw new NotFoundError('Service');
            }

            if (service.mart_id !== martId) {
                throw new AppError('Service does not belong to this mart', 403);
            }

            // Soft delete by setting is_active to false
            const deletedService = await prisma.service.update({
                where: { service_id: serviceId },
                data: { is_active: false }
            });

            logger.info('Service deleted', {
                serviceId,
                martId
            });

            return deletedService;
        } catch (error) {
            logger.error('Failed to delete service', {
                error: error.message,
                serviceId,
                martId
            });
            throw error;
        }
    }
}

module.exports = new ServiceService();

