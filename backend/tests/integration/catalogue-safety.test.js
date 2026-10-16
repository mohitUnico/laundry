const prisma = require('../../src/config/database');
const { resetTestDb } = require('../helpers/db');
const { snapshotCatalogue, clearTransactionalData } = require('../../src/utils/catalogue-io');

jest.setTimeout(120000);

describe('catalogue safety', () => {
    beforeAll(async () => {
        await resetTestDb();
    });

    it('does not delete anything without --confirm', async () => {
        await prisma.customer.create({
            data: {
                full_name: 'Temp Customer',
                email: `temp-${Date.now()}@washbee.test`,
                is_active: true,
            },
        });
        const before = await prisma.customer.count();
        const beforeCat = await snapshotCatalogue(prisma);
        const result = await clearTransactionalData(prisma, { confirm: false });
        expect(result.cleared).toBe(false);
        expect(await prisma.customer.count()).toBe(before);
        const afterCat = await snapshotCatalogue(prisma);
        expect(afterCat.checksum).toBe(beforeCat.checksum);
        expect(afterCat.counts).toEqual(beforeCat.counts);
    });

    it('clears transactional rows and leaves catalogue + checksum unchanged', async () => {
        const beforeCat = await snapshotCatalogue(prisma);
        expect(beforeCat.counts.services).toBeGreaterThan(0);
        expect(beforeCat.counts.clothes).toBeGreaterThan(0);

        const result = await clearTransactionalData(prisma, { confirm: true });
        expect(result.cleared).toBe(true);
        expect(result.after.customers).toBe(0);
        expect(result.after.orders).toBe(0);
        expect(result.after.carts).toBe(0);

        const afterCat = await snapshotCatalogue(prisma);
        expect(afterCat.counts).toEqual(beforeCat.counts);
        expect(afterCat.checksum).toBe(beforeCat.checksum);

        // Seed again must not rewrite catalogue rows
        const { seedTestDatabase } = require('../helpers/db');
        seedTestDatabase();
        const afterSeed = await snapshotCatalogue(prisma);
        expect(afterSeed.counts).toEqual(beforeCat.counts);
        expect(afterSeed.checksum).toBe(beforeCat.checksum);
    });
});
