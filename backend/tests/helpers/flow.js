/**
 * Drives a v2 order through the HTTP API. Used by the lifecycle suite.
 */
const request = require('supertest');
const app = require('./app');
const prisma = require('../../src/config/database');
const { tokenFor } = require('./auth');

function auth(token) {
    return { Authorization: `Bearer ${token}` };
}

function staffToken(person, role) {
    return tokenFor({
        userId: person.staff_id,
        email: person.email,
        role,
        fullName: person.full_name,
    });
}

async function placeOrder({ customerToken, serviceId, pricingType = 'per_kg', homeId, workId, extra = {} }) {
    const added = await request(app)
        .post('/api/v1/carts/items')
        .set(auth(customerToken))
        .send({ items: [{ service_id: serviceId, pricing_type: pricingType }] });
    if (added.status !== 201) {
        throw new Error(`cart add failed ${added.status} ${JSON.stringify(added.body)}`);
    }
    const placed = await request(app)
        .post('/api/v1/orders/create_order')
        .set(auth(customerToken))
        .send({
            cart_id: added.body.data.cart_id,
            pickup_address_id: homeId,
            delivery_address_id: workId,
            ...extra,
        });
    return placed;
}

async function pendingRequest(orderId, deliveryType) {
    return prisma.deliveryAssignmentRequest.findFirst({
        where: { order_id: orderId, delivery_type: deliveryType, status: 'pending' },
        include: { recipients: true },
        orderBy: { offered_at: 'desc' },
    });
}

async function acceptPending(orderId, deliveryType) {
    const row = await pendingRequest(orderId, deliveryType);
    if (!row || row.recipients.length === 0) {
        throw new Error(`no pending ${deliveryType} offer on ${orderId}`);
    }
    const staff = await prisma.deliveryStaff.findUnique({
        where: { staff_id: row.recipients[0].staff_id },
    });
    const token = staffToken(staff, 'delivery_staff');
    const res = await request(app)
        .post(`/api/v1/delivery-staff/assignment-requests/${row.request_id}/accept`)
        .set(auth(token))
        .send({});
    return { res, staff, token, requestId: row.request_id };
}

async function fillDoor(orderId, partnerToken) {
    const items = await prisma.orderItem.findMany({
        where: { order_id: orderId },
        include: { service: { include: { clothes_items: { where: { is_active: true } } } } },
    });
    for (const item of items) {
        const base = `/api/v1/delivery-staff-app/orders/${orderId}/door/services/${item.item_id}`;
        if (item.pricing_type === 'per_kg') {
            const draft = await request(app)
                .patch(base)
                .set(auth(partnerToken))
                .send({ weight_kg: 2.5 });
            if (draft.status !== 200) {
                throw new Error(`door draft failed ${draft.status} ${JSON.stringify(draft.body)}`);
            }
        } else {
            const cloth = item.service.clothes_items[0];
            const draft = await request(app)
                .patch(base)
                .set(auth(partnerToken))
                .send({ selections: [{ cloth_id: cloth.cloth_id, quantity: 2 }] });
            if (draft.status !== 200) {
                throw new Error(`door draft failed ${draft.status} ${JSON.stringify(draft.body)}`);
            }
        }
        const photo = await request(app)
            .post(`${base}/photo`)
            .set(auth(partnerToken))
            .attach('file', Buffer.from('door-photo'), 'door.jpg');
        if (photo.status !== 200) {
            throw new Error(`door photo failed ${photo.status} ${JSON.stringify(photo.body)}`);
        }
    }
}

async function confirmDoor(orderId, partnerToken) {
    return request(app)
        .post(`/api/v1/delivery-staff-app/orders/${orderId}/door/confirm`)
        .set(auth(partnerToken));
}

async function submitToCm(orderId, partnerToken) {
    return request(app)
        .post(`/api/v1/delivery-staff-app/orders/${orderId}/submit-to-cm`)
        .set(auth(partnerToken));
}

async function receiveAndQueue(orderId, cmToken) {
    const received = await request(app)
        .post(`/api/v1/staff-app/collection-manager/orders/${orderId}/mark-received`)
        .set(auth(cmToken));
    if (received.status !== 200) return { received, submitted: null };
    const submitted = await request(app)
        .post(`/api/v1/staff-app/collection-manager/orders/${orderId}/submit-to-services`)
        .set(auth(cmToken));
    return { received, submitted };
}

async function completeAllQueues(orderId) {
    const queues = await prisma.serviceQueueItem.findMany({ where: { order_id: orderId } });
    const results = [];
    for (const queue of queues) {
        const man = await prisma.staff.findFirst({
            where: { role: 'service_man', service_id: queue.service_id, is_active: true },
        });
        if (!man) throw new Error(`no service man for ${queue.service_id}`);
        const token = staffToken(man, 'service_man');
        const res = await request(app)
            .patch(`/api/v1/staff-app/service-man/queue/${queue.queue_id}`)
            .set(auth(token))
            .send({ action: 'completed' });
        results.push(res);
    }
    return results;
}

async function payMock(orderId, customerToken, status = 'succeeded') {
    const intent = await request(app)
        .post(`/api/v1/payments/orders/${orderId}/pay-intent`)
        .set(auth(customerToken));
    if (intent.status !== 200) return { intent, forced: null };
    const attemptId = intent.body.data.attempt.attemptId;
    const forced = await request(app)
        .post(`/api/v1/payments/mock/attempts/${attemptId}/complete`)
        .send({ status });
    return { intent, forced, attemptId };
}

async function markDelivered(orderId, partnerToken) {
    return request(app)
        .post(`/api/v1/delivery-staff-app/orders/${orderId}/mark-delivered`)
        .set(auth(partnerToken))
        .attach('file', Buffer.from('drop-photo'), 'drop.jpg');
}

module.exports = {
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
};
