const { ConflictError } = require('../utils/errors');
const prisma = require('../config/database');

/**
 * A service can go in a cart if the admin has added it and left it active
 * (category active too) and the chosen pricing type is available.
 * An assigned service man is optional at booking; the plant checks that later.
 */
async function inspectService(serviceId, { tx = prisma } = {}) {
    const service = await tx.service.findUnique({
        where: { service_id: serviceId },
        include: {
            category: true,
            service_man: true,
            clothes_items: {
                where: { is_active: true, per_unit_price: { gt: 0 } },
                select: { cloth_id: true, per_unit_price: true },
            },
        },
    });

    const reasons = [];
    if (!service || !service.is_active) reasons.push('service_inactive');
    if (!service?.category?.is_active) reasons.push('category_inactive');

    const man = service?.service_man;
    const hasServiceMan = !!(man && man.role === 'service_man' && man.is_active);

    const perKgAvailable = !!(service && service.per_kg_price != null && Number(service.per_kg_price) > 0);
    const perUnitAvailable = !!(service && service.clothes_items && service.clothes_items.length > 0);

    return {
        service,
        reasons,
        hasServiceMan,
        perKgAvailable,
        perUnitAvailable,
        bookable: reasons.length === 0,
    };
}

async function isServiceBookable(serviceId, pricingType, { tx = prisma } = {}) {
    const inspected = await inspectService(serviceId, { tx });
    const reasons = [...inspected.reasons];
    if (pricingType === 'per_kg' && !inspected.perKgAvailable) reasons.push('no_per_kg_price');
    if (pricingType === 'per_unit' && !inspected.perUnitAvailable) reasons.push('no_clothes_items');
    return {
        bookable: reasons.length === 0,
        hasServiceMan: inspected.hasServiceMan,
        perKgAvailable: inspected.perKgAvailable,
        perUnitAvailable: inspected.perUnitAvailable,
        reasons,
        service: inspected.service,
    };
}

function assertBookable(result, serviceId) {
    if (!result.bookable) {
        throw new ConflictError(
            `Service ${serviceId} is unavailable (${result.reasons.join(', ')})`,
            'SERVICE_UNAVAILABLE'
        );
    }
}

module.exports = {
    inspectService,
    isServiceBookable,
    assertBookable,
};
