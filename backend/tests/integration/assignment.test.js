const request = require('supertest');
const app = require('../helpers/app');
const prisma = require('../../src/config/database');
const { resetTestDb } = require('../helpers/db');
const { tokenFor } = require('../helpers/auth');
const { SEED_EMAILS } = require('../helpers/factories');
const engine = require('../../src/services/assignment/assignment-engine.service');
const { runAssignmentCatchup } = require('../../src/services/assignment/assignment-catchup.job');

jest.setTimeout(120000);

describe('Phase 3 assignment engine', () => {
    let customerToken;
    let home;
    let work;
    let service;
    let cmToken;

    beforeAll(async () => {
        await resetTestDb();
        const customer = await prisma.customer.findUnique({
            where: { email: SEED_EMAILS.customer },
            include: { addresses: true },
        });
        customerToken = tokenFor({
            userId: customer.customer_id,
            email: customer.email,
            role: 'customer',
            fullName: customer.full_name,
        });
        home = customer.addresses.find((a) => a.address_label === 'home');
        work = customer.addresses.find((a) => a.address_label === 'work');
        service = await prisma.service.findFirst({ where: { per_kg_price: { not: null }, is_active: true } });
        const cm = await prisma.staff.findUnique({ where: { email: SEED_EMAILS.collectionManager } });
        cmToken = tokenFor({
            userId: cm.staff_id,
            email: cm.email,
            role: 'collection_manager',
            fullName: cm.full_name,
        });
    });

    async function placeExpress() {
        const added = await request(app)
            .post('/api/v1/carts/items')
            .set('Authorization', `Bearer ${customerToken}`)
            .send({ items: [{ service_id: service.service_id, pricing_type: 'per_kg' }] })
            .expect(201);
        const placed = await request(app)
            .post('/api/v1/orders/create_order')
            .set('Authorization', `Bearer ${customerToken}`)
            .send({
                cart_id: added.body.data.cart_id,
                pickup_address_id: home.address_id,
                delivery_address_id: work.address_id,
                is_express: true,
            })
            .expect(201);
        return placed.body.data.order_id;
    }

    async function staffByKm(km) {
        return prisma.deliveryStaff.findUnique({ where: { email: `pickup-${km}km@washbee.test` } });
    }

    async function offeredStaffIds(orderId) {
        const reqRow = await prisma.deliveryAssignmentRequest.findFirst({
            where: { order_id: orderId, delivery_type: 'pickup' },
            orderBy: { offered_at: 'desc' },
            include: { recipients: true },
        });
        return {
            request: reqRow,
            ids: new Set((reqRow?.recipients || []).map((r) => r.staff_id)),
        };
    }

    it('expands rings and never offers the same staff twice', async () => {
        const orderId = await placeExpress();
        const s1 = await staffByKm(1);
        const s3 = await staffByKm(3);
        const s6 = await staffByKm(6);
        const s12 = await staffByKm(12);

        let offered = await offeredStaffIds(orderId);
        expect(offered.request.current_slice).toBe(1);
        expect(offered.ids.has(s1.staff_id)).toBe(true);
        expect(offered.ids.has(s3.staff_id)).toBe(false);

        await engine.advanceSlice(offered.request.request_id, { sliceIndex: 2 });
        offered = await offeredStaffIds(orderId);
        expect(offered.ids.has(s3.staff_id)).toBe(true);
        expect(offered.ids.has(s6.staff_id)).toBe(false);

        await engine.advanceSlice(offered.request.request_id, { sliceIndex: 3 });
        offered = await offeredStaffIds(orderId);
        expect(offered.ids.has(s6.staff_id)).toBe(true);
        expect(offered.ids.has(s12.staff_id)).toBe(false);

        const again = await engine.advanceSlice(offered.request.request_id, { sliceIndex: 3 });
        expect(again.skipped).toBe(true);
        const count = await prisma.deliveryAssignmentRecipient.count({
            where: { request_id: offered.request.request_id, staff_id: s6.staff_id },
        });
        expect(count).toBe(1);
    });

    it('skips off-shift, unverified, and staff with no location', async () => {
        const far = await staffByKm(6);
        await prisma.deliveryStaffShift.updateMany({
            where: { staff_id: far.staff_id },
            data: { is_active: false, ended_at: new Date() },
        });
        const hidden = await staffByKm(3);
        const savedLat = hidden.current_latitude;
        const savedLng = hidden.current_longitude;
        await prisma.deliveryStaff.update({
            where: { staff_id: hidden.staff_id },
            data: { current_latitude: null, current_longitude: null },
        });

        const orderId = await placeExpress();
        await engine.advanceSlice(
            (await offeredStaffIds(orderId)).request.request_id,
            { sliceIndex: 3 }
        );
        const offered = await offeredStaffIds(orderId);
        expect(offered.ids.has(far.staff_id)).toBe(false);
        expect(offered.ids.has(hidden.staff_id)).toBe(false);

        await prisma.deliveryStaff.update({
            where: { staff_id: hidden.staff_id },
            data: { current_latitude: savedLat, current_longitude: savedLng },
        });
        await prisma.deliveryStaffShift.create({
            data: { staff_id: far.staff_id, is_active: true },
        });
    });

    it('lets the first accept win and rejects a second accept', async () => {
        const orderId = await placeExpress();
        const row = (await offeredStaffIds(orderId)).request;
        await engine.advanceSlice(row.request_id, { sliceIndex: 2 });
        const refreshed = await offeredStaffIds(orderId);
        const s1 = await staffByKm(1);
        const s3 = await staffByKm(3);
        const t1 = tokenFor({ userId: s1.staff_id, email: s1.email, role: 'delivery_staff', fullName: s1.full_name });
        const t3 = tokenFor({ userId: s3.staff_id, email: s3.email, role: 'delivery_staff', fullName: s3.full_name });

        const [a, b] = await Promise.all([
            request(app)
                .post(`/api/v1/delivery-staff/assignment-requests/${refreshed.request.request_id}/accept`)
                .set('Authorization', `Bearer ${t1}`),
            request(app)
                .post(`/api/v1/delivery-staff/assignment-requests/${refreshed.request.request_id}/accept`)
                .set('Authorization', `Bearer ${t3}`),
        ]);
        const codes = [a.status, b.status].sort();
        expect(codes).toEqual([200, 409]);
        const order = await prisma.order.findUnique({ where: { order_id: orderId } });
        expect(order.order_status).toBe('pickup_assigned');
    });

    it('blocks force-assign until timeout, then allows any verified staff', async () => {
        const orderId = await placeExpress();
        const s12 = await staffByKm(12);
        await prisma.deliveryStaffShift.updateMany({
            where: { staff_id: s12.staff_id },
            data: { is_active: false, ended_at: new Date() },
        });

        const early = await request(app)
            .post(`/api/v1/staff-app/collection-manager/orders/${orderId}/assign-pickup-direct`)
            .set('Authorization', `Bearer ${cmToken}`)
            .send({ deliveryStaffId: s12.staff_id });
        expect(early.status).toBe(409);
        expect(early.body.errorCode).toBe('ASSIGNMENT_NOT_ENABLED');

        const row = (await offeredStaffIds(orderId)).request;
        await engine.finishTimeout(row.request_id);
        const state = await engine.getAssignState(orderId, 'pickup');
        expect(state.state).toBe('enabled');

        const list = await request(app)
            .get(`/api/v1/staff-app/collection-manager/orders/${orderId}/assignable-staff`)
            .set('Authorization', `Bearer ${cmToken}`)
            .expect(200);
        expect(list.body.data.staff.some((s) => s.staffId === s12.staff_id && s.onShift === false)).toBe(true);

        const late = await request(app)
            .post(`/api/v1/staff-app/collection-manager/orders/${orderId}/assign-pickup-direct`)
            .set('Authorization', `Bearer ${cmToken}`)
            .send({ deliveryStaffId: s12.staff_id })
            .expect(200);
        expect(late.body.success).toBe(true);

        const accept = await request(app)
            .post(`/api/v1/delivery-staff/assignment-requests/${row.request_id}/accept`)
            .set('Authorization', `Bearer ${tokenFor({ userId: s12.staff_id, email: s12.email, role: 'delivery_staff', fullName: s12.full_name })}`);
        expect(accept.status).toBeGreaterThanOrEqual(400);

        await prisma.deliveryStaffShift.create({ data: { staff_id: s12.staff_id, is_active: true } });
    });

    it('does not start a future scheduled search until the handler runs, and catch-up restarts a lost search', async () => {
        const added = await request(app)
            .post('/api/v1/carts/items')
            .set('Authorization', `Bearer ${customerToken}`)
            .send({ items: [{ service_id: service.service_id, pricing_type: 'per_kg' }] })
            .expect(201);
        const later = new Date(Date.now() + 3 * 24 * 60 * 60 * 1000).toISOString();
        const drop = new Date(Date.now() + 6 * 24 * 60 * 60 * 1000).toISOString();
        const placed = await request(app)
            .post('/api/v1/orders/create_order')
            .set('Authorization', `Bearer ${customerToken}`)
            .send({
                cart_id: added.body.data.cart_id,
                pickup_address_id: home.address_id,
                delivery_address_id: work.address_id,
                pickup_mode: 'scheduled',
                pickup_time_from: later,
                delivery_mode: 'scheduled',
                delivery_time_from: drop,
            })
            .expect(201);
        const orderId = placed.body.data.order_id;
        const before = await prisma.deliveryAssignmentRequest.count({ where: { order_id: orderId } });
        expect(before).toBe(0);

        await engine.startSearch({ orderId, deliveryType: 'pickup' });
        const started = await prisma.deliveryAssignmentRequest.count({
            where: { order_id: orderId, status: 'pending' },
        });
        expect(started).toBe(1);

        await prisma.deliveryAssignmentRequest.updateMany({
            where: { order_id: orderId, status: 'pending' },
            data: { status: 'cancelled', ended_reason: 'cancelled' },
        });
        await runAssignmentCatchup(new Date(Date.now() + 4 * 24 * 60 * 60 * 1000));
        const restarted = await prisma.deliveryAssignmentRequest.count({
            where: { order_id: orderId, status: 'pending' },
        });
        expect(restarted).toBe(1);
    });

    it('hides tracking until a pickup partner is assigned', async () => {
        const orderId = await placeExpress();
        const hidden = await request(app)
            .get(`/api/v1/orders/${orderId}/tracking`)
            .set('Authorization', `Bearer ${customerToken}`)
            .expect(200);
        expect(hidden.body.data.trackingAvailable).toBe(false);
    });
});
