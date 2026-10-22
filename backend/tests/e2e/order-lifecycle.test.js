jest.mock('../../src/services/cloudinary-upload.service', () => ({
    uploadBuffer: jest.fn(async () => 'https://cdn.test/photo.jpg'),
    ensureConfigured: jest.fn(),
}));

const request = require('supertest');
const prisma = require('../../src/config/database');
const { resetTestDb } = require('../helpers/db');
const { tokenFor } = require('../helpers/auth');
const { SEED_EMAILS } = require('../helpers/factories');
const configService = require('../../src/services/config.service');
const engine = require('../../src/services/assignment/assignment-engine.service');
const { runAssignmentCatchup } = require('../../src/services/assignment/assignment-catchup.job');
const dropTrigger = require('../../src/services/assignment/drop-trigger.service');
const mockProvider = require('../../src/services/payments/mock.provider');
const {
    app,
    auth,
    staffToken,
    placeOrder,
    pendingRequest,
    acceptPending,
    fillDoor,
    confirmDoor,
    submitToCm,
    receiveAndQueue,
    completeAllQueues,
    payMock,
    markDelivered,
} = require('../helpers/flow');

jest.setTimeout(180000);

describe('v2 order lifecycle', () => {
    let customer;
    let customerToken;
    let home;
    let work;
    let perKg;
    let perUnit;
    let cm;
    let cmToken;
    let dmToken;
    let adminToken;

    beforeAll(async () => {
        await resetTestDb();
        customer = await prisma.customer.findUnique({
            where: { email: SEED_EMAILS.customer },
            include: { addresses: true },
        });
        customerToken = tokenFor({
            userId: customer.customer_id,
            email: customer.email,
            role: 'customer',
            fullName: customer.full_name,
        });
        home = customer.addresses.find((row) => row.address_label === 'home');
        work = customer.addresses.find((row) => row.address_label === 'work');
        perKg = await prisma.service.findFirst({
            where: { per_kg_price: { not: null }, is_active: true },
            orderBy: { service_name: 'asc' },
        });
        perUnit = await prisma.service.findFirst({
            where: { per_kg_price: null, is_active: true, clothes_items: { some: { is_active: true } } },
        });
        cm = await prisma.staff.findUnique({ where: { email: SEED_EMAILS.collectionManager } });
        cmToken = staffToken(cm, 'collection_manager');
        const dm = await prisma.staff.findUnique({ where: { email: SEED_EMAILS.distributionManager } });
        dmToken = staffToken(dm, 'distribution_manager');
        const admin = await prisma.user.findUnique({ where: { email: SEED_EMAILS.admin } });
        adminToken = tokenFor({
            userId: admin.user_id,
            email: admin.email,
            role: 'admin',
            fullName: admin.full_name,
        });
    });

    async function place(extra = {}, service = perKg, pricingType = 'per_kg') {
        const res = await placeOrder({
            customerToken,
            serviceId: service.service_id,
            pricingType,
            homeId: home.address_id,
            workId: work.address_id,
            extra,
        });
        expect(res.status).toBe(201);
        return res.body.data.order_id;
    }

    async function walkToServices(orderId) {
        const pickup = await acceptPending(orderId, 'pickup');
        expect(pickup.res.status).toBe(200);
        const early = await confirmDoor(orderId, pickup.token);
        expect(early.status).toBe(409);
        expect(early.body.errorCode).toBe('DOOR_INCOMPLETE');
        await fillDoor(orderId, pickup.token);
        const confirmed = await confirmDoor(orderId, pickup.token);
        expect(confirmed.status).toBe(200);
        const again = await confirmDoor(orderId, pickup.token);
        expect(again.status).toBe(200);
        const bills = await prisma.bill.count({ where: { order_id: orderId } });
        expect(bills).toBe(1);
        const submitted = await submitToCm(orderId, pickup.token);
        expect(submitted.status).toBe(200);
        const plant = await receiveAndQueue(orderId, cmToken);
        expect(plant.received.status).toBe(200);
        expect(plant.submitted.status).toBe(200);
        return pickup;
    }

    it('runs the happy path from place to delivered and exposes the customer read APIs', async () => {
        const orderId = await place({ is_express: true });

        const hidden = await request(app)
            .get(`/api/v1/orders/${orderId}/tracking`)
            .set(auth(customerToken));
        expect(hidden.status).toBe(200);
        expect(hidden.body.data.trackingAvailable).toBe(false);

        const pickup = await walkToServices(orderId);
        const bill = await request(app)
            .get(`/api/v1/payments/orders/${orderId}/bill`)
            .set(auth(customerToken));
        expect(bill.status).toBe(200);
        expect(bill.body.data.bill).toBeTruthy();

        const queues = await completeAllQueues(orderId);
        expect(queues.every((row) => row.status === 200)).toBe(true);
        const afterPlant = await prisma.order.findUnique({ where: { order_id: orderId } });
        expect(afterPlant.order_status).toBe('services_completed');
        if (!(await pendingRequest(orderId, 'drop'))) {
            await dropTrigger.evaluate(orderId);
        }

        const drop = await acceptPending(orderId, 'drop');
        expect(drop.res.status).toBe(200);
        const out = await prisma.order.findUnique({ where: { order_id: orderId } });
        expect(out.order_status).toBe('out_for_delivery');

        const cashTooSoon = await request(app)
            .post(`/api/v1/delivery-staff-app/orders/${orderId}/record-cash`)
            .set(auth(drop.token));
        expect(cashTooSoon.status).toBe(409);

        const paid = await payMock(orderId, customerToken, 'succeeded');
        expect(paid.forced.status).toBe(200);
        const duplicate = await request(app)
            .post(`/api/v1/payments/mock/attempts/${paid.attemptId}/complete`)
            .send({ status: 'succeeded' });
        expect(duplicate.status).toBe(200);

        const delivered = await markDelivered(orderId, drop.token);
        expect(delivered.status).toBe(200);
        const repeat = await markDelivered(orderId, drop.token);
        expect(repeat.status).toBe(200);

        const detail = await request(app).get(`/api/v1/orders/${orderId}`).set(auth(customerToken));
        expect(detail.status).toBe(200);
        expect(detail.body.data.orderStatus || detail.body.data.order_status).toBe('delivered');

        const history = await request(app)
            .get('/api/v1/orders?bucket=history')
            .set(auth(customerToken));
        expect(history.status).toBe(200);

        const tracking = await request(app)
            .get(`/api/v1/orders/${orderId}/tracking`)
            .set(auth(customerToken));
        expect(tracking.status).toBe(200);
        expect(tracking.body.data.trackingAvailable).toBe(true);

        const catalogue = await request(app).get('/api/v1/catalog/pricing').set(auth(customerToken));
        expect(catalogue.status).toBe(200);
        expect(catalogue.body.data.length).toBeGreaterThan(0);

        const services = await request(app).get('/api/v1/admin/services').set(auth(adminToken));
        expect(services.status).toBe(200);

        const oldPay = await request(app)
            .post(`/api/v1/payments/orders/${orderId}/process`)
            .set(auth(customerToken));
        expect(oldPay.status).toBe(410);

        expect(pickup.staff.staff_id).toBeTruthy();
    });

    it('snapshots the express fee and lists the express queue ahead of ordinary work', async () => {
        await configService.setValue('EXPRESS_FEE', 40, 'test');
        const ordinaryId = await place({
            pickup_mode: 'instant',
            delivery_mode: 'scheduled',
            delivery_time_from: new Date(Date.now() + 4 * 86400000).toISOString(),
        });
        await walkToServices(ordinaryId);

        const expressId = await place({ is_express: true });
        const pickup = await acceptPending(expressId, 'pickup');
        expect(pickup.res.status).toBe(200);
        await fillDoor(expressId, pickup.token);
        const confirmed = await confirmDoor(expressId, pickup.token);
        expect(confirmed.status).toBe(200);
        const bill = await prisma.bill.findUnique({ where: { order_id: expressId } });
        expect(Number(bill.express_fee)).toBe(40);
        expect(bill.payment_method).toBeNull();
        await submitToCm(expressId, pickup.token);
        const plant = await receiveAndQueue(expressId, cmToken);
        expect(plant.submitted.status).toBe(200);

        const man = await prisma.staff.findFirst({
            where: { role: 'service_man', service_id: perKg.service_id, is_active: true },
        });
        const listed = await request(app)
            .get('/api/v1/staff-app/service-man/queue')
            .set(auth(staffToken(man, 'service_man')));
        expect(listed.status).toBe(200);
        const rows = listed.body.data.queue || listed.body.data.items || listed.body.data;
        const ids = (Array.isArray(rows) ? rows : []).map((row) => row.orderId || row.order_id);
        expect(ids.indexOf(expressId)).toBeGreaterThanOrEqual(0);
        expect(ids.indexOf(expressId)).toBeLessThan(ids.indexOf(ordinaryId));

        await configService.setValue('EXPRESS_FEE', 0, 'test');
        await completeAllQueues(expressId);
        await completeAllQueues(ordinaryId);
    });

    it('cancels only while the order is placed', async () => {
        const openId = await place({ is_express: true });
        const cancelled = await request(app)
            .post(`/api/v1/orders/${openId}/cancel`)
            .set(auth(customerToken))
            .send({ reason: 'changed my mind' });
        expect(cancelled.status).toBe(200);
        const again = await request(app)
            .post(`/api/v1/orders/${openId}/cancel`)
            .set(auth(customerToken))
            .send({ reason: 'changed my mind' });
        expect(again.status).toBe(409);

        const acceptedId = await place({ is_express: true });
        const pickup = await acceptPending(acceptedId, 'pickup');
        expect(pickup.res.status).toBe(200);
        const tooLate = await request(app)
            .post(`/api/v1/orders/${acceptedId}/cancel`)
            .set(auth(customerToken))
            .send({ reason: 'too late now' });
        expect(tooLate.status).toBe(409);
        expect(tooLate.body.errorCode).toBe('CANCEL_NOT_ALLOWED');
    });

    it('force-assigns pickup and drop only after the search times out', async () => {
        const orderId = await place({ is_express: true });
        const far = await prisma.deliveryStaff.findUnique({ where: { email: SEED_EMAILS.pickup12km } });
        const early = await request(app)
            .post(`/api/v1/staff-app/collection-manager/orders/${orderId}/assign-pickup-direct`)
            .set(auth(cmToken))
            .send({ deliveryStaffId: far.staff_id });
        expect(early.status).toBe(409);
        expect(early.body.errorCode).toBe('ASSIGNMENT_NOT_ENABLED');

        const search = await pendingRequest(orderId, 'pickup');
        await engine.finishTimeout(search.request_id);
        const forced = await request(app)
            .post(`/api/v1/staff-app/collection-manager/orders/${orderId}/assign-pickup-direct`)
            .set(auth(cmToken))
            .send({ deliveryStaffId: far.staff_id });
        expect(forced.status).toBe(200);
        const order = await prisma.order.findUnique({ where: { order_id: orderId } });
        expect(order.order_status).toBe('pickup_assigned');

        const partnerToken = staffToken(far, 'delivery_staff');
        await fillDoor(orderId, partnerToken);
        expect((await confirmDoor(orderId, partnerToken)).status).toBe(200);
        expect((await submitToCm(orderId, partnerToken)).status).toBe(200);
        const plant = await receiveAndQueue(orderId, cmToken);
        expect(plant.submitted.status).toBe(200);
        const done = await completeAllQueues(orderId);
        expect(done.every((row) => row.status === 200)).toBe(true);
        if (!(await pendingRequest(orderId, 'drop'))) {
            await dropTrigger.evaluate(orderId);
        }

        const dropEarly = await request(app)
            .post(`/api/v1/staff-app/distribution-manager/orders/${orderId}/assign-drop`)
            .set(auth(dmToken))
            .send({ deliveryStaffId: far.staff_id });
        expect(dropEarly.status).toBe(409);

        const dropSearch = await pendingRequest(orderId, 'drop');
        expect(dropSearch).toBeTruthy();
        await engine.finishTimeout(dropSearch.request_id);
        const dropForced = await request(app)
            .post(`/api/v1/staff-app/distribution-manager/orders/${orderId}/assign-drop`)
            .set(auth(dmToken))
            .send({ deliveryStaffId: far.staff_id });
        expect(dropForced.status).toBe(200);
        const out = await prisma.order.findUnique({ where: { order_id: orderId } });
        expect(out.order_status).toBe('out_for_delivery');
    });

    it('holds a scheduled drop until the window, then starts the search', async () => {
        const later = new Date(Date.now() + 5 * 86400000).toISOString();
        const orderId = await place({
            pickup_mode: 'instant',
            delivery_mode: 'scheduled',
            delivery_time_from: later,
        });
        await walkToServices(orderId);
        await completeAllQueues(orderId);
        const held = await dropTrigger.evaluate(orderId);
        expect(held.started).toBe(false);
        expect(held.mode).toBe('scheduled');

        const ready = await request(app)
            .get('/api/v1/staff-app/distribution-manager/orders/ready-to-dispatch')
            .set(auth(dmToken));
        expect(ready.status).toBe(200);
        const row = (ready.body.data || []).find((item) => item.orderId === orderId);
        expect(row.assign.state).toBe('available_from');

        await prisma.order.update({
            where: { order_id: orderId },
            data: { delivery_time_from: new Date(Date.now() - 60 * 1000) },
        });
        const started = await dropTrigger.evaluate(orderId);
        expect(started.started).toBe(true);
        const search = await pendingRequest(orderId, 'drop');
        expect(search).toBeTruthy();
    });

    it('falls back to cash after a failed UPI attempt and flags a late UPI as refund required', async () => {
        const orderId = await place({ is_express: true });
        await walkToServices(orderId);
        await completeAllQueues(orderId);
        if (!(await pendingRequest(orderId, 'drop'))) {
            await dropTrigger.evaluate(orderId);
        }
        const drop = await acceptPending(orderId, 'drop');
        expect(drop.res.status).toBe(200);

        const failed = await payMock(orderId, customerToken, 'failed');
        expect(failed.forced.status).toBe(200);
        const attempt = await prisma.paymentAttempt.findUnique({ where: { attempt_id: failed.attemptId } });
        expect(attempt.status).toBe('failed');

        const stranger = await prisma.deliveryStaff.findUnique({ where: { email: SEED_EMAILS.pickup12km } });
        const denied = await request(app)
            .post(`/api/v1/delivery-staff-app/orders/${orderId}/record-cash`)
            .set(auth(staffToken(stranger, 'delivery_staff')));
        expect(denied.status).toBe(403);

        const cash = await request(app)
            .post(`/api/v1/delivery-staff-app/orders/${orderId}/record-cash`)
            .set(auth(drop.token));
        expect(cash.status).toBe(200);
        expect(cash.body.data.paymentMethod).toBe('cash');

        const body = JSON.stringify({
            providerRef: attempt.provider_ref,
            status: 'succeeded',
        });
        const late = await request(app)
            .post('/api/v1/payments/webhook/mock')
            .set('Content-Type', 'application/json')
            .set('x-mock-signature', mockProvider.signBody(body))
            .send(body);
        expect(late.status).toBe(200);
        expect(late.body.data.refundRequired).toBe(true);
        const bill = await prisma.bill.findUnique({ where: { order_id: orderId } });
        expect(bill.payment_method).toBe('cash');

        const delivered = await markDelivered(orderId, drop.token);
        expect(delivered.status).toBe(200);

        const couponLate = await request(app)
            .post(`/api/v1/payments/orders/${orderId}/coupon`)
            .set(auth(customerToken))
            .send({ code: 'WASH10' });
        expect(couponLate.status).toBe(409);
    });

    it('applies and removes a coupon before a live payment attempt', async () => {
        const orderId = await place({ is_express: true });
        const pickup = await acceptPending(orderId, 'pickup');
        await fillDoor(orderId, pickup.token);
        expect((await confirmDoor(orderId, pickup.token)).status).toBe(200);

        const applied = await request(app)
            .post(`/api/v1/payments/orders/${orderId}/coupon`)
            .set(auth(customerToken))
            .send({ code: 'WASH10' });
        expect(applied.status).toBe(200);
        expect(applied.body.data.couponCode).toBe('WASH10');
        expect(Number(applied.body.data.discount)).toBeGreaterThan(0);

        const expired = await request(app)
            .post(`/api/v1/payments/orders/${orderId}/coupon`)
            .set(auth(customerToken))
            .send({ code: 'EXPIRED' });
        expect(expired.status).toBe(409);

        const removed = await request(app)
            .delete(`/api/v1/payments/orders/${orderId}/coupon`)
            .set(auth(customerToken));
        expect(removed.status).toBe(200);
        expect(Number(removed.body.data.discount)).toBe(0);
    });

    it('refuses to queue an order whose service has no service man', async () => {
        const category = await prisma.serviceCategory.findFirst({ where: { is_active: true } });
        const orphan = await prisma.service.create({
            data: {
                category_id: category.category_id,
                service_name: `Orphan Bookable ${Date.now()}`,
                base_price: 10,
                per_kg_price: 80,
                estimated_hours: 24,
                is_active: true,
            },
        });
        const orderId = await place({ is_express: true }, orphan);
        const pickup = await acceptPending(orderId, 'pickup');
        await fillDoor(orderId, pickup.token);
        expect((await confirmDoor(orderId, pickup.token)).status).toBe(200);
        expect((await submitToCm(orderId, pickup.token)).status).toBe(200);
        const received = await request(app)
            .post(`/api/v1/staff-app/collection-manager/orders/${orderId}/mark-received`)
            .set(auth(cmToken));
        expect(received.status).toBe(200);
        const blocked = await request(app)
            .post(`/api/v1/staff-app/collection-manager/orders/${orderId}/submit-to-services`)
            .set(auth(cmToken));
        expect(blocked.status).toBe(409);
        expect(blocked.body.errorCode).toBe('NO_SERVICE_MAN');
    });

    it('lets exactly one partner win an accept race', async () => {
        const orderId = await place({ is_express: true });
        const search = await pendingRequest(orderId, 'pickup');
        await engine.advanceSlice(search.request_id, { sliceIndex: 2 });
        const fresh = await pendingRequest(orderId, 'pickup');
        expect(fresh.recipients.length).toBeGreaterThanOrEqual(2);
        const racers = fresh.recipients.slice(0, 2);
        const results = await Promise.all(
            racers.map(async (recipient) => {
                const staff = await prisma.deliveryStaff.findUnique({ where: { staff_id: recipient.staff_id } });
                return request(app)
                    .post(`/api/v1/delivery-staff/assignment-requests/${fresh.request_id}/accept`)
                    .set(auth(staffToken(staff, 'delivery_staff')))
                    .send({});
            })
        );
        const statuses = results.map((row) => row.status).sort();
        expect(statuses).toEqual([200, 409]);
        const order = await prisma.order.findUnique({ where: { order_id: orderId } });
        expect(order.order_status).toBe('pickup_assigned');
        const owners = await prisma.delivery.count({
            where: { order_id: orderId, delivery_type: 'pickup', staff_id: { not: null } },
        });
        expect(owners).toBe(1);
    });

    it('completes the last two services without leaving the order in progress', async () => {
        const added = await request(app)
            .post('/api/v1/carts/items')
            .set(auth(customerToken))
            .send({
                items: [
                    { service_id: perKg.service_id, pricing_type: 'per_kg' },
                    { service_id: perUnit.service_id, pricing_type: 'per_unit' },
                ],
            });
        expect(added.status).toBe(201);
        const placed = await request(app)
            .post('/api/v1/orders/create_order')
            .set(auth(customerToken))
            .send({
                cart_id: added.body.data.cart_id,
                pickup_address_id: home.address_id,
                delivery_address_id: work.address_id,
                is_express: true,
            });
        expect(placed.status).toBe(201);
        const orderId = placed.body.data.order_id;
        const pickup = await acceptPending(orderId, 'pickup');
        await fillDoor(orderId, pickup.token);
        expect((await confirmDoor(orderId, pickup.token)).status).toBe(200);
        expect((await submitToCm(orderId, pickup.token)).status).toBe(200);
        const plant = await receiveAndQueue(orderId, cmToken);
        expect(plant.submitted.status).toBe(200);

        const queues = await prisma.serviceQueueItem.findMany({ where: { order_id: orderId } });
        expect(queues).toHaveLength(2);
        const results = await Promise.all(
            queues.map(async (queue) => {
                const man = await prisma.staff.findFirst({
                    where: { role: 'service_man', service_id: queue.service_id, is_active: true },
                });
                return request(app)
                    .patch(`/api/v1/staff-app/service-man/queue/${queue.queue_id}`)
                    .set(auth(staffToken(man, 'service_man')))
                    .send({ action: 'completed' });
            })
        );
        expect(results.every((row) => row.status === 200)).toBe(true);
        const order = await prisma.order.findUnique({ where: { order_id: orderId } });
        expect(order.order_status).toBe('services_completed');
    });

    it('covers catalogue release, plant lists, and assignment catch-up', async () => {
        const health = await request(app)
            .get('/api/v1/admin/services/assignment-health')
            .set(auth(adminToken));
        expect(health.status).toBe(200);
        expect(health.body.data).toEqual(expect.objectContaining({ searching: expect.any(Array), timedOut: expect.any(Array) }));

        const listed = await request(app).get('/api/v1/admin/services').set(auth(adminToken));
        const target = listed.body.data.find((row) => row.hasServiceMan && row.serviceId !== perKg.service_id);
        const released = await request(app)
            .post(`/api/v1/admin/services/${target.serviceId}/service-man/release`)
            .set(auth(adminToken));
        expect(released.status).toBe(200);
        expect(released.body.data.released).toBe(true);
        const second = await request(app)
            .post(`/api/v1/admin/services/${target.serviceId}/service-man/release`)
            .set(auth(adminToken));
        expect(second.body.data.released).toBe(false);

        const missing = await request(app)
            .post('/api/v1/admin/services/00000000-0000-4000-8000-000000000000/service-man/release')
            .set(auth(adminToken));
        expect(missing.status).toBe(404);

        const incoming = await request(app)
            .get('/api/v1/staff-app/collection-manager/orders/incoming')
            .set(auth(cmToken));
        expect(incoming.status).toBe(200);
        const received = await request(app)
            .get('/api/v1/staff-app/collection-manager/orders/received')
            .set(auth(cmToken));
        expect(received.status).toBe(200);
        const cmHistory = await request(app)
            .get('/api/v1/staff-app/collection-manager/orders/history')
            .set(auth(cmToken));
        expect(cmHistory.status).toBe(200);

        const inPlant = await request(app)
            .get('/api/v1/staff-app/distribution-manager/orders/in-plant')
            .set(auth(dmToken));
        expect(inPlant.status).toBe(200);
        const dmHistory = await request(app)
            .get('/api/v1/staff-app/distribution-manager/orders/history')
            .set(auth(dmToken));
        expect(dmHistory.status).toBe(200);

        const cart = await request(app).get('/api/v1/carts').set(auth(customerToken));
        expect(cart.status).toBe(200);

        await runAssignmentCatchup();
    });
});
