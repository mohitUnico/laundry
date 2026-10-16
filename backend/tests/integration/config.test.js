const request = require('supertest');
const app = require('../helpers/app');
const prisma = require('../../src/config/database');
const { resetTestDb } = require('../helpers/db');
const { tokenFor } = require('../helpers/auth');
const { SEED_EMAILS } = require('../helpers/factories');
const configService = require('../../src/services/config.service');

jest.setTimeout(120000);

function adminToken(admin) {
    return tokenFor({
        userId: admin.user_id,
        email: admin.email,
        role: admin.role,
        fullName: admin.full_name,
    });
}

describe('Phase 1 config', () => {
    let admin;

    beforeAll(async () => {
        await resetTestDb();
        admin = await prisma.user.findUnique({ where: { email: SEED_EMAILS.admin } });
    });

    afterEach(async () => {
        delete process.env.ASSIGNMENT_TIMEOUT_MINUTES;
        await configService.seedDefaults();
        configService.clearCache();
    });

    it('seeds all eight keys', async () => {
        const all = await configService.listAll();
        expect(all).toHaveLength(8);
        expect(all.map((k) => k.key).sort()).toEqual(configService.KEY_NAMES.slice().sort());
    });

    it('resolves default -> env -> db, and falls back when the row is deleted', async () => {
        await configService.deleteKeyForTests('ASSIGNMENT_MAX_RANGE_KM');
        delete process.env.ASSIGNMENT_MAX_RANGE_KM;
        configService.clearCache();

        let resolved = await configService.resolve('ASSIGNMENT_MAX_RANGE_KM');
        expect(resolved.source).toBe('default');
        expect(resolved.value).toBe(10);

        process.env.ASSIGNMENT_MAX_RANGE_KM = '15';
        configService.clearCache();
        resolved = await configService.resolve('ASSIGNMENT_MAX_RANGE_KM');
        expect(resolved.source).toBe('env');
        expect(resolved.value).toBe(15);

        await configService.setValue('ASSIGNMENT_MAX_RANGE_KM', 12, admin.user_id);
        resolved = await configService.resolve('ASSIGNMENT_MAX_RANGE_KM');
        expect(resolved.source).toBe('db');
        expect(resolved.value).toBe(12);

        await configService.deleteKeyForTests('ASSIGNMENT_MAX_RANGE_KM');
        resolved = await configService.resolve('ASSIGNMENT_MAX_RANGE_KM');
        expect(resolved.source).toBe('env');
        expect(resolved.value).toBe(15);
    });

    it('rejects timeout 7 and accepts 10', async () => {
        await expect(configService.setValue('ASSIGNMENT_TIMEOUT_MINUTES', 7, admin.user_id)).rejects.toMatchObject({
            statusCode: 400,
        });
        const saved = await configService.setValue('ASSIGNMENT_TIMEOUT_MINUTES', 10, admin.user_id);
        expect(saved.value).toBe(10);
        expect(saved.source).toBe('db');
    });

    it('rejects unknown keys', async () => {
        await expect(configService.setValue('NOT_A_KEY', 1, admin.user_id)).rejects.toMatchObject({
            statusCode: 404,
        });
    });

    it('returns the new value immediately after a write (cache bust)', async () => {
        await configService.setValue('DELIVERY_FEE', 25, admin.user_id);
        const again = await configService.getNumber('DELIVERY_FEE');
        expect(again).toBe(25);
    });

    it('GET /api/v1/config returns the client-safe subset', async () => {
        const res = await request(app).get('/api/v1/config').expect(200);
        expect(res.body.success).toBe(true);
        expect(res.body.data).toEqual(
            expect.objectContaining({
                pickupDeliveryBufferDays: expect.any(Number),
                serviceQueuePollSeconds: expect.any(Number),
                directionsRefreshSeconds: expect.any(Number),
                assignmentTimeoutMinutes: expect.any(Number),
            })
        );
        expect(res.body.data).not.toHaveProperty('DELIVERY_FEE');
    });

    it('admin can list and update config; customer and staff get 403', async () => {
        const token = adminToken(admin);
        const listed = await request(app)
            .get('/api/v1/admin/config')
            .set('Authorization', `Bearer ${token}`)
            .expect(200);
        expect(listed.body.data.keys).toHaveLength(8);
        expect(listed.body.data.keys[0]).toEqual(
            expect.objectContaining({
                key: expect.any(String),
                value: expect.anything(),
                source: expect.stringMatching(/^(db|env|default)$/),
                description: expect.any(String),
            })
        );

        await request(app)
            .put('/api/v1/admin/config/EXPRESS_FEE')
            .set('Authorization', `Bearer ${token}`)
            .send({ value: 40 })
            .expect(200);

        const customer = await prisma.customer.findUnique({ where: { email: SEED_EMAILS.customer } });
        const customerToken = tokenFor({
            userId: customer.customer_id,
            email: customer.email,
            role: 'customer',
            fullName: customer.full_name,
        });
        await request(app)
            .get('/api/v1/admin/config')
            .set('Authorization', `Bearer ${customerToken}`)
            .expect(403);

        const cm = await prisma.staff.findUnique({ where: { email: SEED_EMAILS.collectionManager } });
        const cmToken = tokenFor({
            userId: cm.staff_id,
            email: cm.email,
            role: 'collection_manager',
            fullName: cm.full_name,
        });
        await request(app)
            .put('/api/v1/admin/config/EXPRESS_FEE')
            .set('Authorization', `Bearer ${cmToken}`)
            .send({ value: 1 })
            .expect(403);
    });
});
