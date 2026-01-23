const prisma = require('../config/database');
const logger = require('../utils/logger');
const { ConflictError, ValidationError } = require('../utils/errors');

/**
 * Admin Settings Service
 * - Team members (owner + staff roles)
 */

const mapOwnerToTeamMember = (u) => ({
    staffId: u.user_id,
    fullName: u.full_name,
    email: u.email,
    phone: u.phone || null,
    role: u.role,
    isActive: u.is_active,
    service: null,
    createdAt: u.created_at,
    updatedAt: u.updated_at,
});

const mapStaffToTeamMember = (s) => ({
    staffId: s.staff_id,
    fullName: s.full_name,
    email: s.email,
    phone: s.phone || null,
    role: s.role,
    isActive: s.is_active,
    service: s.service
        ? {
            serviceId: s.service.service_id,
            serviceName: s.service.service_name,
        }
        : null,
    createdAt: s.created_at,
    updatedAt: s.updated_at,
});

exports.getTeamMembers = async () => {
    const [owners, staffs] = await Promise.all([
        prisma.user.findMany({
            where: { role: 'owner' },
            orderBy: { created_at: 'desc' },
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
        }),
        prisma.staff.findMany({
            where: { role: { in: ['service_man', 'collection_manager', 'distribution_manager'] } },
            orderBy: { created_at: 'desc' },
            include: {
                service: { select: { service_id: true, service_name: true } },
            },
        }),
    ]);

    const result = {
        owner: owners.map(mapOwnerToTeamMember),
        service_men: [],
        collection_managers: [],
        distribution_managers: [],
    };

    for (const s of staffs) {
        const mapped = mapStaffToTeamMember(s);
        if (s.role === 'service_man') result.service_men.push(mapped);
        else if (s.role === 'collection_manager') result.collection_managers.push(mapped);
        else if (s.role === 'distribution_manager') result.distribution_managers.push(mapped);
    }

    logger.info('Admin settings team members fetched', {
        owners: result.owner.length,
        serviceMen: result.service_men.length,
        collectionManagers: result.collection_managers.length,
        distributionManagers: result.distribution_managers.length,
    });

    return result;
};

// Backwards-compatible alias (older controller name)
exports.getTeamMembersGrouped = exports.getTeamMembers;

exports.createTeamMember = async ({ fullName, email, phone, role, serviceId, isActive }) => {
    if (!fullName || !email || !role) throw new ValidationError('fullName, email and role are required');

    // Normalize email
    const normalizedEmail = String(email).trim().toLowerCase();

    // Role: owner -> users table
    if (role === 'owner') {
        // prevent duplicates
        const existing = await prisma.user.findUnique({
            where: { email: normalizedEmail },
            select: { user_id: true },
        });
        if (existing) throw new ConflictError('Email already exists');

        const created = await prisma.user.create({
            data: {
                full_name: String(fullName).trim(),
                email: normalizedEmail,
                phone: phone || null,
                role: 'owner',
                is_active: typeof isActive === 'boolean' ? isActive : true,
            },
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
        });

        return mapOwnerToTeamMember(created);
    }

    // Staff roles MUST be created via OTP registration flow (send-otp -> verify-otp -> complete-registration).
    // This endpoint is intentionally restricted to prevent bypassing identity verification.
    throw new ValidationError(
        'Staff roles must be created via OTP flow. Use /api/v1/auth/{collection-manager|distribution-manager|service-man}/* endpoints.'
    );
};

module.exports = exports;

