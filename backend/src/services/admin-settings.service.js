const prisma = require('../config/database');
const logger = require('../utils/logger');

/**
 * Admin Settings Service
 * - Team members (owner + staff roles)
 */

const mapOwner = (u) => ({
    userId: u.user_id,
    fullName: u.full_name,
    email: u.email,
    phone: u.phone || null,
    role: u.role,
    isActive: u.is_active,
    createdAt: u.created_at,
    updatedAt: u.updated_at,
});

const mapStaff = (s) => ({
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
            orderBy: { created_at: 'asc' },
        }),
        prisma.staff.findMany({
            where: { role: { in: ['service_man', 'collection_manager', 'distribution_manager'] } },
            orderBy: { created_at: 'asc' },
            include: {
                service: { select: { service_id: true, service_name: true } },
            },
        }),
    ]);

    const serviceMen = [];
    const collectionManagers = [];
    const distributionManagers = [];

    for (const s of staffs) {
        if (s.role === 'service_man') serviceMen.push(mapStaff(s));
        if (s.role === 'collection_manager') collectionManagers.push(mapStaff(s));
        if (s.role === 'distribution_manager') distributionManagers.push(mapStaff(s));
    }

    const result = {
        owner: owners.map(mapOwner),
        service_men: serviceMen,
        collection_managers: collectionManagers,
        distribution_managers: distributionManagers,
    };

    logger.info('Admin settings team members fetched', {
        owners: result.owner.length,
        serviceMen: result.service_men.length,
        collectionManagers: result.collection_managers.length,
        distributionManagers: result.distribution_managers.length,
    });

    return result;
};

module.exports = exports;

