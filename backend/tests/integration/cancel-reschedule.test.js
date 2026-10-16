const request = require('supertest');
const app = require('../helpers/app');
const prisma = require('../../src/config/database');
const { resetTestDb } = require('../helpers/db');
const { tokenFor } = require('../helpers/auth');
const { SEED_EMAILS } = require('../helpers/factories');

jest.setTimeout(120000);

function futureIso(days, hour = 10) {
    const d = new Date();
    d.setDate(d.getDate() + days);
    d.setHours(hour, 0, 0, 0);
    return d.toISOString();
}

describe('Phase 4 cancel and reschedule', () => {
    let token;
    let home;
    let work;
    let service;
    let staffToken;

    beforeAll(async () => {
        await resetTestDb();
        const customer = await prisma.customer.findUnique({
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
        service = await prisma.service.findFirst({ where: { per_kg_price: { not: null }, is_active: true } });
        const staff = await prisma.deliveryStaff.findUnique({ where: { email: SEED_EMAILS.pickup1km } });
        staffToken = tokenFor({
            userId: staff.staff_id,
            email: staff.email,
            role: 'delivery_staff',
            fullName: staff.full_name,
        });
    });

    async function place(body) {
        const added = await request(app)
            .post('/api/v1/carts/items')
            .set('Authorization', `Bearer ${token}`)
            .send({ items: [{ service_id: service.service_id, pricing_type: 'per_kg' }] })
            .expect(201);
        const placed = await request(app)
            .post('/api/v1/orders/create_order')
            .set('Authorization', `Bearer ${token}`)
            .send({
                cart_id: added.body.data.cart_id,
                pickup_address_id: home.address_id,
                delivery_address_id: work.address_id,
                ...body,
            })
            .expect(201);
        return placed.body.data.order_id;
    }

    it('cancels a placed order and rejects a second cancel', async () => {
        const orderId = await place({ is_express: true });
        const missing = await request(app)
            .post(`/api/v1/orders/${orderId}/cancel`)
            .set('Authorization', `Bearer ${token}`)
            .send({});
        expect(missing.status).toBe(400);

        const ok = await request(app)
            .post(`/api/v1/orders/${orderId}/cancel`)
            .set('Authorization', `Bearer ${token}`)
            .send({ reason: 'Changed my mind' })
            .expect(200);
        expect(ok.body.data.order_status).toBe('cancelled');

        const reqRow = await prisma.deliveryAssignmentRequest.findFirst({
            where: { order_id: orderId },
            orderBy: { offered_at: 'desc' },
        });
        expect(reqRow.status).toBe('cancelled');

        const again = await request(app)
            .post(`/api/v1/orders/${orderId}/cancel`)
            .set('Authorization', `Bearer ${token}`)
            .send({ reason: 'Again' });
        expect(again.status).toBe(409);

        const accept = await request(app)
            .post(`/api/v1/delivery-staff/assignment-requests/${reqRow.request_id}/accept`)
            .set('Authorization', `Bearer ${staffToken}`);
        expect(accept.status).toBeGreaterThanOrEqual(400);

        const history = await request(app)
            .get('/api/v1/orders?bucket=history')
            .set('Authorization', `Bearer ${token}`)
            .expect(200);
        expect(history.body.data.orders.some((o) => o.order_id === orderId)).toBe(true);
        const active = await request(app)
            .get('/api/v1/orders?bucket=active')
            .set('Authorization', `Bearer ${token}`)
            .expect(200);
        expect(active.body.data.orders.some((o) => o.order_id === orderId)).toBe(false);
    });

    it('rejects cancel after pickup is assigned, and only one of cancel or accept wins', async () => {
        const assigned = await place({ is_express: true });
        const reqRow = await prisma.deliveryAssignmentRequest.findFirst({
            where: { order_id: assigned, status: 'pending' },
        });
        await request(app)
            .post(`/api/v1/delivery-staff/assignment-requests/${reqRow.request_id}/accept`)
            .set('Authorization', `Bearer ${staffToken}`)
            .expect(200);
        const late = await request(app)
            .post(`/api/v1/orders/${assigned}/cancel`)
            .set('Authorization', `Bearer ${token}`)
            .send({ reason: 'Too late' });
        expect(late.status).toBe(409);

        const racing = await place({ is_express: true });
        const raceReq = await prisma.deliveryAssignmentRequest.findFirst({
            where: { order_id: racing, status: 'pending' },
        });
        const [cancelRes, acceptRes] = await Promise.all([
            request(app)
                .post(`/api/v1/orders/${racing}/cancel`)
                .set('Authorization', `Bearer ${token}`)
                .send({ reason: 'Race' }),
            request(app)
                .post(`/api/v1/delivery-staff/assignment-requests/${raceReq.request_id}/accept`)
                .set('Authorization', `Bearer ${staffToken}`),
        ]);
        const statuses = [cancelRes.status, acceptRes.status].sort();
        expect(statuses).toEqual([200, 409]);
        const order = await prisma.order.findUnique({ where: { order_id: racing } });
        expect(['cancelled', 'pickup_assigned']).toContain(order.order_status);
        if (order.order_status === 'cancelled') {
            const delivery = await prisma.delivery.findFirst({
                where: { order_id: racing, delivery_type: 'pickup' },
            });
            expect(delivery.staff_id).toBeNull();
        }
    });

    it('reschedules a placed order and rejects express or assigned orders', async () => {
        const orderId = await place({
            pickup_mode: 'scheduled',
            pickup_time_from: futureIso(2),
            delivery_mode: 'scheduled',
            delivery_time_from: futureIso(5),
        });
        const bad = await request(app)
            .patch(`/api/v1/orders/${orderId}/schedule`)
            .set('Authorization', `Bearer ${token}`)
            .send({
                pickup_mode: 'scheduled',
                pickup_time_from: futureIso(2),
                delivery_mode: 'scheduled',
                delivery_time_from: futureIso(3),
            });
        expect(bad.status).toBe(400);

        const instant = await request(app)
            .patch(`/api/v1/orders/${orderId}/schedule`)
            .set('Authorization', `Bearer ${token}`)
            .send({ pickup_mode: 'instant', delivery_mode: 'scheduled', delivery_time_from: futureIso(4) })
            .expect(200);
        expect(instant.body.data.pickup_mode).toBe('instant');
        const pending = await prisma.deliveryAssignmentRequest.count({
            where: { order_id: orderId, status: 'pending' },
        });
        expect(pending).toBe(1);

        const express = await place({ is_express: true });
        const denied = await request(app)
            .patch(`/api/v1/orders/${express}/schedule`)
            .set('Authorization', `Bearer ${token}`)
            .send({ pickup_mode: 'scheduled', pickup_time_from: futureIso(2) });
        expect(denied.status).toBe(409);
    });
});
