const { PrismaClient } = require('@prisma/client');
const bcrypt = require('bcrypt');
const prisma = new PrismaClient();
const { AppError, ValidationError, NotFoundError } = require('../utils/errors');
const logger = require('../utils/logger');
const { generateToken } = require('../utils/jwt');

/**
 * Mart Service
 * Handles business logic for laundry mart operations
 * 
 * NOTE: Mart registration with email-first OTP authentication is now handled
 * entirely in otp.service.js via completeOwnerRegistration().
 * This service contains legacy methods and utility functions for mart management.
 */
class MartService {
    /**
     * Register a new laundry mart with an owner user (LEGACY METHOD)
     * 
     * NOTE: This method is no longer used in the email-first OTP authentication flow.
     * Mart registration now happens via otp.service.completeOwnerRegistration()
     * 
     * @deprecated Use otp.service.completeOwnerRegistration() instead
     * @param {Object} martData - Mart registration data
     * @param {boolean} martPhoneVerified - Whether mart phone is verified via OTP
     * @param {boolean} ownerPhoneVerified - Whether owner phone is verified via OTP
     * @returns {Promise<Object>} Created mart and user details
     */
    async registerMart(martData, martPhoneVerified = false, ownerPhoneVerified = false) {
        try {
            // Verify that both phones are verified via OTP
            if (!martPhoneVerified || !ownerPhoneVerified) {
                throw new ValidationError('Both mart phone and owner phone must be verified via OTP before registration');
            }

            // Check if mart with same email already exists
            const existingMart = await prisma.laundryMart.findUnique({
                where: { contact_email: martData.contactEmail },
            });

            if (existingMart) {
                throw new ValidationError('A mart with this email already exists');
            }

            // Check if mart phone already exists
            const existingMartPhone = await prisma.laundryMart.findFirst({
                where: { contact_phone: martData.contactPhone },
            });

            if (existingMartPhone) {
                throw new ValidationError('A mart with this phone number already exists');
            }

            // Check if user email already exists
            const existingUser = await prisma.user.findUnique({
                where: { email: martData.owner.email },
            });

            if (existingUser) {
                throw new ValidationError('A user with this email already exists');
            }

            // Check if owner phone already exists
            const existingUserPhone = await prisma.user.findFirst({
                where: { phone: martData.owner.phone },
            });

            if (existingUserPhone) {
                throw new ValidationError('A user with this phone number already exists');
            }

            // Create mart and owner user in a transaction
            const result = await prisma.$transaction(async (tx) => {
                // Create mart with verified phone
                const mart = await tx.laundryMart.create({
                    data: {
                        mart_name: martData.martName,
                        contact_email: martData.contactEmail,
                        contact_phone: martData.contactPhone,
                        address: martData.address,
                        latitude: martData.latitude,
                        longitude: martData.longitude,
                        service_radius_km: martData.serviceRadiusKm,
                        is_phone_verified: true, // Phone verified via OTP
                        is_active: martData.isActive ?? true,
                    },
                });

                // Create owner user with verified phone (NO PASSWORD - OTP-based auth)
                const owner = await tx.user.create({
                    data: {
                        mart_id: mart.mart_id,
                        full_name: martData.owner.fullName,
                        email: martData.owner.email,
                        phone: martData.owner.phone,
                        // NO PASSWORD FIELD - using OTP-based authentication
                        role: 'admin', // First user is always admin
                        is_phone_verified: true, // Phone verified via OTP
                        is_active: true,
                    },
                    include: {
                        mart: {
                            select: {
                                mart_id: true,
                                mart_name: true,
                                contact_email: true,
                                contact_phone: true,
                            },
                        },
                    },
                });

                return { mart, owner };
            });

            logger.info('Mart registered successfully with OTP verification', {
                martId: result.mart.mart_id,
                martName: result.mart.mart_name,
                ownerEmail: result.owner.email,
                ownerPhone: result.owner.phone,
            });

            // Remove password from response
            const { password, ...ownerWithoutPassword } = result.owner;

            // Generate JWT token for owner
            const token = generateToken(result.owner);

            logger.info('JWT token generated for owner', {
                userId: result.owner.user_id,
                email: result.owner.email,
                role: result.owner.role,
            });

            return {
                mart: result.mart,
                owner: ownerWithoutPassword,
                token, // JWT token for immediate use
            };
        } catch (error) {
            logger.error('Mart registration failed', {
                error: error.message,
                martEmail: martData.contactEmail,
            });
            throw error;
        }
    }

    /**
     * Add a new user to an existing mart
     * @param {Object} userData - User data
     * @returns {Promise<Object>} Created user details
     */
    async addUserToMart(userData) {
        try {
            // Verify mart exists and is active
            const mart = await prisma.laundryMart.findUnique({
                where: { mart_id: userData.martId },
            });

            if (!mart) {
                throw new NotFoundError('Mart');
            }

            if (!mart.is_active) {
                throw new AppError('Cannot add users to an inactive mart', 400);
            }

            // Check if user email already exists
            const existingUser = await prisma.user.findUnique({
                where: { email: userData.email },
            });

            if (existingUser) {
                throw new ValidationError('A user with this email already exists');
            }

            // Hash password
            const hashedPassword = await bcrypt.hash(userData.password, 10);

            // Create user
            const user = await prisma.user.create({
                data: {
                    mart_id: userData.martId,
                    full_name: userData.fullName,
                    email: userData.email,
                    phone: userData.phone,
                    password: hashedPassword,
                    role: userData.role || 'staff',
                    is_active: userData.isActive ?? true,
                },
                include: {
                    mart: {
                        select: {
                            mart_id: true,
                            mart_name: true,
                            contact_email: true,
                        },
                    },
                },
            });

            logger.info('User added to mart', {
                userId: user.user_id,
                martId: userData.martId,
                email: user.email,
                role: user.role,
            });

            // Remove password from response
            const { password, ...userWithoutPassword } = user;

            // Generate JWT token for user
            const token = generateToken(user);

            logger.info('JWT token generated for user', {
                userId: user.user_id,
                email: user.email,
                role: user.role,
            });

            return {
                user: userWithoutPassword,
                token, // JWT token for immediate use
            };
        } catch (error) {
            logger.error('Failed to add user to mart', {
                error: error.message,
                martId: userData.martId,
                email: userData.email,
            });
            throw error;
        }
    }

    /**
     * Add a manager to an existing mart
     * Convenience method that specifically adds a manager role user
     * @param {string} martId - Mart ID
     * @param {Object} managerData - Manager data
     * @returns {Promise<Object>} Created manager details
     */
    async addManagerToMart(martId, managerData) {
        try {
            // Verify mart exists and is active
            const mart = await prisma.laundryMart.findUnique({
                where: { mart_id: martId },
            });

            if (!mart) {
                throw new NotFoundError('Mart');
            }

            if (!mart.is_active) {
                throw new AppError('Cannot add managers to an inactive mart', 400);
            }

            // Check if user email already exists
            const existingUser = await prisma.user.findUnique({
                where: { email: managerData.email },
            });

            if (existingUser) {
                throw new ValidationError('A user with this email already exists');
            }

            // Hash password
            const hashedPassword = await bcrypt.hash(managerData.password, 10);

            // Create manager user
            const manager = await prisma.user.create({
                data: {
                    mart_id: martId,
                    full_name: managerData.fullName,
                    email: managerData.email,
                    phone: managerData.phone,
                    password: hashedPassword,
                    role: 'manager', // Fixed role
                    is_active: managerData.isActive ?? true,
                },
                include: {
                    mart: {
                        select: {
                            mart_id: true,
                            mart_name: true,
                            contact_email: true,
                            contact_phone: true,
                        },
                    },
                },
            });

            logger.info('Manager added to mart', {
                userId: manager.user_id,
                martId: martId,
                email: manager.email,
                role: manager.role,
            });

            // Remove password from response
            const { password, ...managerWithoutPassword } = manager;

            // Generate JWT token for manager
            const token = generateToken(manager);

            logger.info('JWT token generated for manager', {
                userId: manager.user_id,
                email: manager.email,
                role: manager.role,
            });

            return {
                manager: managerWithoutPassword,
                token, // JWT token for immediate use
            };
        } catch (error) {
            logger.error('Failed to add manager to mart', {
                error: error.message,
                martId: martId,
                email: managerData.email,
            });
            throw error;
        }
    }

    /**
     * Get mart details by ID
     * @param {string} martId - Mart ID
     * @returns {Promise<Object>} Mart details
     */
    async getMartById(martId) {
        const mart = await prisma.laundryMart.findUnique({
            where: { mart_id: martId },
            include: {
                users: {
                    select: {
                        user_id: true,
                        full_name: true,
                        email: true,
                        phone: true,
                        role: true,
                        is_active: true,
                        created_at: true,
                    },
                },
                _count: {
                    select: {
                        orders: true,
                        services: true,
                        delivery_staffs: true,
                    },
                },
            },
        });

        if (!mart) {
            throw new NotFoundError('Mart');
        }

        return mart;
    }

    /**
     * Update mart details
     * @param {string} martId - Mart ID
     * @param {Object} updateData - Data to update
     * @returns {Promise<Object>} Updated mart details
     */
    async updateMart(martId, updateData) {
        // Verify mart exists
        const existingMart = await prisma.laundryMart.findUnique({
            where: { mart_id: martId },
        });

        if (!existingMart) {
            throw new NotFoundError('Mart');
        }

        // If email is being updated, check for duplicates
        if (updateData.contactEmail && updateData.contactEmail !== existingMart.contact_email) {
            const duplicateMart = await prisma.laundryMart.findUnique({
                where: { contact_email: updateData.contactEmail },
            });

            if (duplicateMart) {
                throw new ValidationError('A mart with this email already exists');
            }
        }

        // Build update object
        const dataToUpdate = {};
        if (updateData.martName) dataToUpdate.mart_name = updateData.martName;
        if (updateData.contactEmail) dataToUpdate.contact_email = updateData.contactEmail;
        if (updateData.contactPhone) dataToUpdate.contact_phone = updateData.contactPhone;
        if (updateData.address) dataToUpdate.address = updateData.address;
        if (updateData.latitude !== undefined) dataToUpdate.latitude = updateData.latitude;
        if (updateData.longitude !== undefined) dataToUpdate.longitude = updateData.longitude;
        if (updateData.serviceRadiusKm) dataToUpdate.service_radius_km = updateData.serviceRadiusKm;
        if (updateData.isActive !== undefined) dataToUpdate.is_active = updateData.isActive;

        // Update mart
        const updatedMart = await prisma.laundryMart.update({
            where: { mart_id: martId },
            data: dataToUpdate,
        });

        logger.info('Mart updated', {
            martId,
            updatedFields: Object.keys(dataToUpdate),
        });

        return updatedMart;
    }

    /**
     * Get all marts with pagination
     * @param {Object} options - Query options
     * @returns {Promise<Object>} Marts list with pagination
     */
    async getAllMarts(options = {}) {
        const { page = 1, limit = 10, isActive, search } = options;
        const skip = (page - 1) * limit;

        const where = {};

        if (isActive !== undefined) {
            where.is_active = isActive === 'true';
        }

        if (search) {
            where.OR = [
                { mart_name: { contains: search, mode: 'insensitive' } },
                { contact_email: { contains: search, mode: 'insensitive' } },
                { contact_phone: { contains: search } },
            ];
        }

        const [marts, total] = await Promise.all([
            prisma.laundryMart.findMany({
                where,
                skip,
                take: parseInt(limit),
                orderBy: { created_at: 'desc' },
                include: {
                    _count: {
                        select: {
                            users: true,
                            orders: true,
                            services: true,
                        },
                    },
                },
            }),
            prisma.laundryMart.count({ where }),
        ]);

        return {
            marts,
            pagination: {
                page: parseInt(page),
                limit: parseInt(limit),
                total,
                totalPages: Math.ceil(total / limit),
                hasNext: page * limit < total,
                hasPrev: page > 1,
            },
        };
    }

    /**
     * Get all users of a mart
     * @param {string} martId - Mart ID
     * @param {Object} options - Query options
     * @returns {Promise<Object>} Users list
     */
    async getMartUsers(martId, options = {}) {
        const { role, isActive } = options;

        // Verify mart exists
        const mart = await prisma.laundryMart.findUnique({
            where: { mart_id: martId },
        });

        if (!mart) {
            throw new NotFoundError('Mart');
        }

        const where = { mart_id: martId };

        if (role) {
            where.role = role;
        }

        if (isActive !== undefined) {
            where.is_active = isActive === 'true';
        }

        const users = await prisma.user.findMany({
            where,
            select: {
                user_id: true,
                full_name: true,
                email: true,
                phone: true,
                role: true,
                is_active: true,
                created_at: true,
                updated_at: true,
            },
            orderBy: { created_at: 'desc' },
        });

        return users;
    }

    /**
     * Deactivate a mart (soft delete)
     * @param {string} martId - Mart ID
     * @returns {Promise<Object>} Updated mart
     */
    async deactivateMart(martId) {
        const mart = await prisma.laundryMart.findUnique({
            where: { mart_id: martId },
        });

        if (!mart) {
            throw new NotFoundError('Mart');
        }

        const updatedMart = await prisma.laundryMart.update({
            where: { mart_id: martId },
            data: { is_active: false },
        });

        logger.info('Mart deactivated', { martId });

        return updatedMart;
    }
}

module.exports = new MartService();

