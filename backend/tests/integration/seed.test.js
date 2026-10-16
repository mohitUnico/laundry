const prisma = require('../../src/config/database');
const { resetTestDb } = require('../helpers/db');
const { SEED_EMAILS } = require('../helpers/factories');

jest.setTimeout(120000);

describe('seed fixtures', () => {
    beforeAll(async () => {
        await resetTestDb();
    });

    it('gives every service exactly one service man', async () => {
        const services = await prisma.service.findMany();
        expect(services.length).toBeGreaterThan(0);
        for (const service of services) {
            const men = await prisma.staff.findMany({
                where: { role: 'service_man', service_id: service.service_id },
            });
            expect(men).toHaveLength(1);
            expect(men[0].is_active).toBe(true);
        }
    });

    it('has four verified pickup staff with active shifts', async () => {
        const staff = await prisma.deliveryStaff.findMany({
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
        });
        expect(staff).toHaveLength(4);
        for (const s of staff) {
            expect(s.is_verified_by_admin).toBe(true);
            expect(s.verification_status).toBe('verified');
            expect(s.current_latitude).not.toBeNull();
            expect(s.current_longitude).not.toBeNull();
            expect(s.deliveryStaffShifts.length).toBeGreaterThanOrEqual(1);
        }
    });

    it('has admin, CM, DM, customer with two addresses, and coupons', async () => {
        const admin = await prisma.user.findUnique({ where: { email: SEED_EMAILS.admin } });
        expect(admin).toBeTruthy();
        expect(admin.role).toBe('admin');

        const cm = await prisma.staff.findUnique({ where: { email: SEED_EMAILS.collectionManager } });
        const dm = await prisma.staff.findUnique({ where: { email: SEED_EMAILS.distributionManager } });
        expect(cm.role).toBe('collection_manager');
        expect(dm.role).toBe('distribution_manager');

        const customer = await prisma.customer.findUnique({
            where: { email: SEED_EMAILS.customer },
            include: { addresses: true },
        });
        expect(customer).toBeTruthy();
        expect(customer.addresses).toHaveLength(2);

        const codes = ['WASH10', 'FLAT50', 'EXPIRED', 'CAPPED'];
        for (const code of codes) {
            const coupon = await prisma.coupon.findFirst({ where: { code } });
            expect(coupon).toBeTruthy();
        }
    });
});
