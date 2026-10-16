/**
 * Print a bearer token per seeded persona for Postman / curl.
 *
 * Usage: node scripts/dev-tokens.js
 */
require('../src/config/env');
const prisma = require('../src/config/database');
const { generateToken } = require('../src/utils/jwt');
const { SEED_EMAILS } = require('../tests/helpers/factories');

function printToken(label, payload) {
    const token = generateToken(payload);
    console.log(`\n${label}`);
    console.log(`  email: ${payload.email}`);
    console.log(`  role:  ${payload.role}`);
    console.log(`  id:    ${payload.userId}`);
    console.log(`  token: ${token}`);
}

async function main() {
    if (!process.env.JWT_SECRET) {
        throw new Error('JWT_SECRET is not set');
    }

    const admin = await prisma.user.findUnique({ where: { email: SEED_EMAILS.admin } });
    if (admin) {
        printToken('admin', {
            userId: admin.user_id,
            email: admin.email,
            role: admin.role,
            fullName: admin.full_name,
        });
    }

    const customer = await prisma.customer.findUnique({ where: { email: SEED_EMAILS.customer } });
    if (customer) {
        printToken('customer', {
            userId: customer.customer_id,
            email: customer.email,
            role: 'customer',
            fullName: customer.full_name,
        });
    }

    const cm = await prisma.staff.findUnique({ where: { email: SEED_EMAILS.collectionManager } });
    if (cm) {
        printToken('collection_manager', {
            userId: cm.staff_id,
            email: cm.email,
            role: 'collection_manager',
            fullName: cm.full_name,
        });
    }

    const dm = await prisma.staff.findUnique({ where: { email: SEED_EMAILS.distributionManager } });
    if (dm) {
        printToken('distribution_manager', {
            userId: dm.staff_id,
            email: dm.email,
            role: 'distribution_manager',
            fullName: dm.full_name,
        });
    }

    const pickup = await prisma.deliveryStaff.findMany({
        where: { email: { startsWith: 'pickup-' } },
        orderBy: { email: 'asc' },
    });
    for (const staff of pickup) {
        printToken(`delivery_staff ${staff.email}`, {
            userId: staff.staff_id,
            email: staff.email,
            role: 'delivery_staff',
            fullName: staff.full_name,
        });
    }

    const serviceMen = await prisma.staff.findMany({
        where: { role: 'service_man' },
        include: { service: { select: { service_name: true } } },
        orderBy: { email: 'asc' },
    });
    for (const sm of serviceMen) {
        const svc = sm.service?.service_name || sm.service_id;
        printToken(`service_man (${svc})`, {
            userId: sm.staff_id,
            email: sm.email,
            role: 'service_man',
            fullName: sm.full_name,
        });
    }

    console.log('\nDone.');
}

main()
    .catch((err) => {
        console.error('dev-tokens failed:', err);
        process.exit(1);
    })
    .finally(async () => {
        await prisma.$disconnect();
    });
