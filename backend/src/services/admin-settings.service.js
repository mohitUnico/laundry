const prisma = require('../config/database');
const logger = require('../utils/logger');
const { ConflictError, NotFoundError, ValidationError } = require('../utils/errors');
const { Prisma } = require('@prisma/client');

const mapUserToTeamMember = (u) => ({
    staffId: u.user_id,
    fullName: u.full_name,
    email: u.email,
    phone: u.phone,
    role: u.role, // 'owner' | 'admin'
    isActive: u.is_active,
    service: null,
    createdAt: u.created_at,
    updatedAt: u.updated_at,
});

const mapStaffToTeamMember = (s) => ({
    staffId: s.staff_id,
    fullName: s.full_name,
    email: s.email,
    phone: s.phone,
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

exports.getTeamMembersGrouped = async () => {
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
            orderBy: { created_at: 'desc' },
            include: {
                service: { select: { service_id: true, service_name: true } },
            },
        }),
    ]);

    const grouped = {
        owner: owners.map(mapUserToTeamMember),
        service_men: [],
        collection_managers: [],
        distribution_managers: [],
    };

    for (const s of staffs) {
        const mapped = mapStaffToTeamMember(s);
        if (s.role === 'service_man') grouped.service_men.push(mapped);
        else if (s.role === 'collection_manager') grouped.collection_managers.push(mapped);
        else if (s.role === 'distribution_manager') grouped.distribution_managers.push(mapped);
    }

    return grouped;
};

exports.createTeamMember = async ({ fullName, email, phone, role, serviceId, isActive }) => {
    if (!fullName || !email || !role) throw new ValidationError('fullName, email and role are required');

    // Normalize email
    const normalizedEmail = String(email).trim().toLowerCase();

    // Role: owner -> users table
    if (role === 'owner') {
        // prevent duplicates
        const existing = await prisma.user.findUnique({ where: { email: normalizedEmail }, select: { user_id: true } });
        if (existing) throw new ConflictError('Email already exists');

        const created = await prisma.user.create({
            data: {
                full_name: fullName.trim(),
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

        return mapUserToTeamMember(created);
    }

    // Staff roles MUST be created via OTP registration flow (send-otp -> verify-otp -> complete-registration).
    // This endpoint is intentionally restricted to prevent bypassing identity verification.
    throw new ValidationError(
        'Staff roles must be created via OTP flow. Use /api/v1/auth/{collection-manager|distribution-manager|service-man}/* endpoints.'
    );
};

