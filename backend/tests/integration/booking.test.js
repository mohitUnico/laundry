const request = require('supertest');
const app = require('../helpers/app');
const prisma = require('../../src/config/database');
const { resetTestDb } = require('../helpers/db');
const { tokenFor } = require('../helpers/auth');
const { SEED_EMAILS } = require('../helpers/factories');
const configService = require('../../src/services/config.service');
const assignmentTrigger = require('../../src/services/assignment/assignment-trigger');

jest.setTimeout(120000);

function futureIso(daysFromNow, hour = 10) {
    const d = new Date();
    d.setDate(d.getDate() + daysFromNow);
    d.setHours(hour, 0, 0, 0);
    return d.toISOString();
}

describe('Phase 2 booking', () => {
    let customer;
    let token;
    let home;
    let work;
    let perKgService;
    let perUnitOnlyService;

    beforeAll(async () => {
        await resetTestDb();
        customer = await prisma.customer.findUnique({
            where: { email: SEED_EMAILS.customer },
            include: { addresses: true },
        });
        token = tokenFor({
            userId: customer.customer_id,
            email: customer.email,
            role: 'customer',
            fullName: customer.full_name,
        });
        home = customer.addresses.find((a) => a.address_label === 'home');
        work = customer.addresses.find((a) => a.address_label === 'work');

        perKgService = await prisma.service.findFirst({
            where: { per_kg_price: { not: null }, is_active: true },
        });
        perUnitOnlyService = await prisma.service.findFirst({
            where: { per_kg_price: null, is_active: true },
        });
    });

    async function addAndPlace(items, body) {
        const added = await request(app)
            .post('/api/v1/carts/items')
            .set('Authorization', `Bearer ${token}`)
            .send({ items })
            .expect(201);
        const cartId = added.body.data.cart_id;
        const res = await request(app)
            .post('/api/v1/orders/create_order')
            .set('Authorization', `Bearer ${token}`)
            .send({
                cart_id: cartId,
                pickup_address_id: home.address_id,
                delivery_address_id: work.address_id,
                ...body,
            });
        return { cartId, res };
    }

    it('places a scheduled/scheduled order with no bill and two legs', async () => {
        const spy = jest.spyOn(assignmentTrigger, 'onOrderPlaced');
        const { res, cartId } = await addAndPlace(
            [{ service_id: perKgService.service_id, pricing_type: 'per_kg' }],
            {
                pickup_mode: 'scheduled',
                pickup_time_from: futureIso(1),
                pickup_time_to: futureIso(1, 12),
                delivery_mode: 'scheduled',
                delivery_time_from: futureIso(4),
                delivery_time_to: futureIso(4, 12),
            }
        );
        expect(res.status).toBe(201);
        expect(res.body.data.bill).toBeNull();
        expect(res.body.data.order_status).toBe('placed');
        expect(res.body.data.can_cancel).toBe(true);
        expect(res.body.data.can_reschedule).toBe(true);

        const bills = await prisma.bill.count({ where: { order_id: res.body.data.order_id } });
        const deliveries = await prisma.delivery.findMany({
            where: { order_id: res.body.data.order_id },
        });
        expect(bills).toBe(0);
        expect(deliveries).toHaveLength(2);
        expect(deliveries.map((d) => d.delivery_type).sort()).toEqual(['drop', 'pickup']);
        expect(await prisma.cart.findUnique({ where: { cart_id: cartId } })).toBeNull();
        expect(spy).toHaveBeenCalledTimes(1);
        spy.mockRestore();

        const again = await request(app)
            .post('/api/v1/orders/create_order')
            .set('Authorization', `Bearer ${token}`)
            .send({
                cart_id: cartId,
                pickup_address_id: home.address_id,
                delivery_address_id: work.address_id,
                pickup_mode: 'instant',
                delivery_mode: 'scheduled',
                delivery_time_from: futureIso(3),
            });
        expect(again.status).toBe(404);
    });

    it('accepts instant pickup + scheduled delivery and scheduled pickup + instant delivery', async () => {
        const a = await addAndPlace(
            [{ service_id: perKgService.service_id, pricing_type: 'per_kg' }],
            {
                pickup_mode: 'instant',
                delivery_mode: 'scheduled',
                delivery_time_from: futureIso(3),
            }
        );
        expect(a.res.status).toBe(201);

        const b = await addAndPlace(
            [{ service_id: perUnitOnlyService.service_id, pricing_type: 'per_unit' }],
            {
                pickup_mode: 'scheduled',
                pickup_time_from: futureIso(1),
                delivery_mode: 'instant',
            }
        );
        expect(b.res.status).toBe(201);
    });

    it('enforces the pickup/delivery buffer and respects a config of 0', async () => {
        const tooSoon = await addAndPlace(
            [{ service_id: perKgService.service_id, pricing_type: 'per_kg' }],
            {
                pickup_mode: 'scheduled',
                pickup_time_from: futureIso(2),
                delivery_mode: 'scheduled',
                delivery_time_from: futureIso(3),
            }
        );
        expect(tooSoon.res.status).toBe(400);

        const ok = await addAndPlace(
            [{ service_id: perKgService.service_id, pricing_type: 'per_kg' }],
            {
                pickup_mode: 'scheduled',
                pickup_time_from: futureIso(2),
                delivery_mode: 'scheduled',
                delivery_time_from: futureIso(4),
            }
        );
        expect(ok.res.status).toBe(201);

        await configService.setValue('PICKUP_DELIVERY_BUFFER_DAYS', 0, 'test');
        const sameDay = await addAndPlace(
            [{ service_id: perKgService.service_id, pricing_type: 'per_kg' }],
            {
                pickup_mode: 'scheduled',
                pickup_time_from: futureIso(2),
                delivery_mode: 'scheduled',
                delivery_time_from: futureIso(2, 16),
            }
        );
        expect(sameDay.res.status).toBe(201);
        await configService.setValue('PICKUP_DELIVERY_BUFFER_DAYS', 2, 'test');
    });

    it('places an Express order and rejects times', async () => {
        const ok = await addAndPlace(
            [{ service_id: perKgService.service_id, pricing_type: 'per_kg' }],
            { is_express: true }
        );
        expect(ok.res.status).toBe(201);
        expect(ok.res.body.data.is_express).toBe(true);
        expect(ok.res.body.data.pickup_mode).toBe('instant');
        expect(ok.res.body.data.delivery_mode).toBe('instant');
        expect(ok.res.body.data.can_reschedule).toBe(false);

        const bad = await addAndPlace(
            [{ service_id: perKgService.service_id, pricing_type: 'per_kg' }],
            { is_express: true, pickup_time_from: futureIso(1) }
        );
        expect(bad.res.status).toBe(400);
    });

    it('accepts a mixed cart and rejects per_unit without clothes / empty cart / legacy payload', async () => {
        const mixed = await request(app)
            .post('/api/v1/carts/items')
            .set('Authorization', `Bearer ${token}`)
            .send({
                items: [
                    { service_id: perKgService.service_id, pricing_type: 'per_kg' },
                    { service_id: perUnitOnlyService.service_id, pricing_type: 'per_unit' },
                ],
            })
            .expect(201);
        expect(mixed.body.data.added_cart_item_ids).toHaveLength(2);

        const place = await request(app)
            .post('/api/v1/orders/create_order')
            .set('Authorization', `Bearer ${token}`)
            .send({
                cart_id: mixed.body.data.cart_id,
                pickup_address_id: home.address_id,
                delivery_address_id: work.address_id,
                is_express: true,
            })
            .expect(201);
        expect(place.body.data.items).toHaveLength(2);

        const dryClean = await prisma.service.findFirst({
            where: { service_name: 'Dry Cleaning' },
        });
        if (dryClean) {
            await prisma.clothesItem.updateMany({
                where: { service_id: dryClean.service_id },
                data: { is_active: false },
            });
            const rejected = await request(app)
                .post('/api/v1/carts/items')
                .set('Authorization', `Bearer ${token}`)
                .send({ items: [{ service_id: dryClean.service_id, pricing_type: 'per_unit' }] });
            expect(rejected.status).toBe(409);
            await prisma.clothesItem.updateMany({
                where: { service_id: dryClean.service_id },
                data: { is_active: true },
            });
        }

        const legacy = await request(app)
            .post('/api/v1/orders/create_order')
            .set('Authorization', `Bearer ${token}`)
            .send({
                cart_id: '00000000-0000-0000-0000-000000000001',
                pickup_address_id: home.address_id,
                delivery_address_id: work.address_id,
                order_type: 'both',
            });
        expect(legacy.status).toBe(400);
        expect(JSON.stringify(legacy.body)).toMatch(/order_type/);
    });

    it('lets the customer book a service that has no service man yet', async () => {
        const orphan = await prisma.service.create({
            data: {
                category_id: perKgService.category_id,
                service_name: `Orphan Bookable ${Date.now()}`,
                description: 'No service man assigned',
                base_price: 0,
                per_kg_price: 70,
                estimated_hours: 24,
                is_active: true,
                display_order: 99,
            },
        });

        const { isServiceBookable } = require('../../src/services/catalogue-rules');
        const check = await isServiceBookable(orphan.service_id, 'per_kg');
        expect(check.bookable).toBe(true);
        expect(check.hasServiceMan).toBe(false);

        const placed = await addAndPlace(
            [{ service_id: orphan.service_id, pricing_type: 'per_kg' }],
            { is_express: true }
        );
        expect(placed.res.status).toBe(201);
        expect(placed.res.body.data.items[0].service_id).toBe(orphan.service_id);
    });
});
