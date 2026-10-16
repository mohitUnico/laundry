const prisma = require('../config/database');
const logger = require('../utils/logger');
const { inspectService } = require('./catalogue-rules');
const { NotFoundError } = require('../utils/errors');

async function listServices() {
    const services = await prisma.service.findMany({
        include: {
            category: true,
            service_man: true,
        },
        orderBy: [{ display_order: 'asc' }, { service_name: 'asc' }],
    });
    const rows = [];
    for (const service of services) {
        const inspected = await inspectService(service.service_id);
        const pendingQueueCount = await prisma.serviceQueueItem.count({
            where: { service_id: service.service_id, queue_status: { in: ['pending', 'in_progress'] } },
        });
        const man = service.service_man;
        rows.push({
            serviceId: service.service_id,
            serviceName: service.service_name,
            category: service.category
                ? { categoryId: service.category.category_id, categoryName: service.category.category_name }
                : null,
            perKgPrice: service.per_kg_price == null ? null : String(service.per_kg_price),
            isActive: service.is_active,
            includes: service.includes || [],
            excludes: service.excludes || [],
            serviceMan:
                man && man.role === 'service_man'
                    ? { staffId: man.staff_id, name: man.full_name, isActive: man.is_active }
                    : null,
            bookable: inspected.bookable && (inspected.perKgAvailable || inspected.perUnitAvailable),
            reasons: inspected.reasons,
            hasServiceMan: inspected.hasServiceMan,
            pendingQueueCount,
        });
    }
    return rows;
}

async function releaseServiceMan({ serviceId, actorUserId }) {
    const service = await prisma.service.findUnique({
        where: { service_id: serviceId },
        include: { service_man: true },
    });
    if (!service) throw new NotFoundError('Service');
    const man = service.service_man;
    if (!man) return { serviceId, released: false };
    await prisma.staff.update({
        where: { staff_id: man.staff_id },
        data: { is_active: false, service_id: null },
    });
    logger.info('Service man released', {
        actorUserId,
        serviceId,
        staffId: man.staff_id,
        oldServiceId: serviceId,
        newServiceId: null,
    });
    return { serviceId, released: true, staffId: man.staff_id };
}

async function assignmentHealth() {
    const requests = await prisma.deliveryAssignmentRequest.findMany({
        where: { status: { in: ['pending', 'expired'] } },
        include: { order: { select: { order_status: true, is_express: true } } },
        orderBy: { offered_at: 'desc' },
        take: 100,
    });
    const searching = [];
    const timedOut = [];
    for (const request of requests) {
        const delivery = await prisma.delivery.findUnique({
            where: { delivery_id: request.delivery_id },
            select: { staff_id: true, delivery_type: true },
        });
        if (delivery?.staff_id) continue;
        const row = {
            requestId: request.request_id,
            orderId: request.order_id,
            deliveryType: request.delivery_type,
            status: request.status,
            expiresAt: request.expires_at,
            isExpress: request.order?.is_express || false,
        };
        if (request.status === 'pending') searching.push(row);
        if (request.status === 'expired') timedOut.push(row);
    }
    return { searching, timedOut };
}

module.exports = {
    listServices,
    releaseServiceMan,
    assignmentHealth,
};
