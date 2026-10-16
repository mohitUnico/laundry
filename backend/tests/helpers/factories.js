/**
 * Deterministic test personas. Prefer the seed rows; these helpers create
 * extras when a test needs an isolated fixture.
 */
const prisma = require('../../src/config/database');

const SEED_EMAILS = {
    admin: 'admin@washbee.test',
    customer: 'customer@washbee.test',
    collectionManager: 'cm@washbee.test',
    distributionManager: 'dm@washbee.test',
    pickup1km: 'pickup-1km@washbee.test',
    pickup3km: 'pickup-3km@washbee.test',
    pickup6km: 'pickup-6km@washbee.test',
    pickup12km: 'pickup-12km@washbee.test',
};

async function getSeedAdmin() {
    return prisma.user.findUnique({ where: { email: SEED_EMAILS.admin } });
}

async function getSeedCustomer() {
    return prisma.customer.findUnique({
        where: { email: SEED_EMAILS.customer },
        include: { addresses: true },
    });
}

async function getSeedStaffByRole(role) {
    const email =
        role === 'collection_manager'
            ? SEED_EMAILS.collectionManager
            : SEED_EMAILS.distributionManager;
    return prisma.staff.findUnique({ where: { email } });
}

async function getSeedPickupStaff() {
    return prisma.deliveryStaff.findMany({
        where: {
            email: {
                in: [
                    SEED_EMAILS.pickup1km,
                    SEED_EMAILS.pickup3km,
                    SEED_EMAILS.pickup6km,
                    SEED_EMAILS.pickup12km,
                ],
            },
        },
        include: { deliveryStaffShifts: { where: { is_active: true } } },
        orderBy: { email: 'asc' },
    });
}

async function getServiceMen() {
    return prisma.staff.findMany({
        where: { role: 'service_man' },
        include: { service: true },
        orderBy: { email: 'asc' },
    });
}

module.exports = {
    SEED_EMAILS,
    getSeedAdmin,
    getSeedCustomer,
    getSeedStaffByRole,
    getSeedPickupStaff,
    getServiceMen,
};
