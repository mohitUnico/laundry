/**
 * Drives a v2 order through the HTTP API. Used by the lifecycle suite.
 */
const crypto = require('crypto');
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

const gatewayPayments = new Map();
const gatewayOrders = new Map();
let razorpayFetchInstalled = false;

function jsonResponse(status, data) {
    return {
        ok: status >= 200 && status < 300,
        status,
        json: async () => data,
        text: async () => JSON.stringify(data),
    };
}

function installRazorpayFetch() {
    if (razorpayFetchInstalled) return;
    const original = global.fetch;
    razorpayFetchInstalled = true;
    global.fetch = async (url, options = {}) => {
        const target = String(url);
        if (!target.startsWith('https://api.razorpay.com/v1')) return original(url, options);
        const path = target.slice('https://api.razorpay.com/v1'.length).split('?')[0];
        const method = String(options.method || 'GET').toUpperCase();
        if (method === 'POST' && path === '/orders') {
            const body = JSON.parse(options.body || '{}');
            const id = `order_${crypto.randomBytes(6).toString('hex')}`;
            const order = { id, amount: body.amount, currency: 'INR', status: 'created', receipt: body.receipt };
            gatewayOrders.set(id, order);
            return jsonResponse(200, order);
        }
        const orderPayments = path.match(/^\/orders\/([^/]+)\/payments$/);
        if (method === 'GET' && orderPayments) {
            const items = [...gatewayPayments.values()].filter((row) => row.order_id === decodeURIComponent(orderPayments[1]));
            return jsonResponse(200, { items });
        }
        const onePayment = path.match(/^\/payments\/([^/]+)$/);
        if (method === 'GET' && onePayment) {
            const payment = gatewayPayments.get(decodeURIComponent(onePayment[1]));
            if (!payment) return jsonResponse(404, { error: { description: 'payment not found' } });
            return jsonResponse(200, payment);
        }
        const refund = path.match(/^\/payments\/([^/]+)\/refund$/);
        if (method === 'POST' && refund) {
            const payment = gatewayPayments.get(decodeURIComponent(refund[1]));
            if (!payment) return jsonResponse(404, { error: { description: 'payment not found' } });
            if (payment.refund_status === 'processed') {
                return jsonResponse(400, { error: { description: 'The payment has been fully refunded already' } });
            }
            payment.refund_status = 'processed';
            return jsonResponse(200, {
                id: `rfnd_${payment.id}`,
                payment_id: payment.id,
                amount: payment.amount,
                status: 'processed',
            });
        }
        const oneOrder = path.match(/^\/orders\/([^/]+)$/);
        if (method === 'GET' && oneOrder) {
            const order = gatewayOrders.get(decodeURIComponent(oneOrder[1]));
            if (!order) return jsonResponse(404, { error: { description: 'order not found' } });
            return jsonResponse(200, order);
        }
        if (method === 'GET' && path === '/orders') return jsonResponse(200, { items: [...gatewayOrders.values()] });
        const oneRefund = path.match(/^\/refunds\/([^/]+)$/);
        if (method === 'GET' && oneRefund) {
            return jsonResponse(200, { id: decodeURIComponent(oneRefund[1]), status: 'processed' });
        }
        return jsonResponse(404, { error: { description: `unmocked ${method} ${path}` } });
    };
}

function rememberPayment({ providerRef, paymentId, amount, status }) {
    if (!paymentId || !providerRef) return;
    gatewayPayments.set(paymentId, {
        id: paymentId,
        order_id: providerRef,
        amount,
        status: status === 'failed' ? 'failed' : 'captured',
        method: 'upi',
    });
}

function razorpayEvent({ providerRef, paymentId, amount, status }) {
    return JSON.stringify({
        event: status === 'failed' ? 'payment.failed' : 'payment.captured',
        payload: {
            payment: {
                entity: {
                    id: paymentId,
                    order_id: providerRef,
                    amount,
                    status: status === 'failed' ? 'failed' : 'captured',
                    method: 'upi',
                    error_description: status === 'failed' ? 'payment_failed' : null,
                },
            },
        },
    });
}

function sendRazorpayWebhook({ providerRef, paymentId, amount, status = 'succeeded' }) {
    installRazorpayFetch();
    rememberPayment({ providerRef, paymentId, amount, status });
    const raw = razorpayEvent({ providerRef, paymentId, amount, status });
    const signature = crypto.createHmac('sha256', process.env.RAZORPAY_WEBHOOK_SECRET).update(raw).digest('hex');
    return request(app)
        .post('/api/v1/payments/webhook/razorpay')
        .set('Content-Type', 'application/json')
        .set('x-razorpay-signature', signature)
        .send(raw);
}

async function payWithRazorpay(orderId, customerToken, status = 'succeeded') {
    installRazorpayFetch();
    const intent = await request(app)
        .post(`/api/v1/payments/orders/${orderId}/pay-intent`)
        .set(auth(customerToken));
    if (intent.status !== 200) return { intent, forced: null };
    const providerRef = intent.body.data.attempt.providerRef;
    const order = gatewayOrders.get(providerRef);
    const paymentId = `pay_${providerRef}`;
    const amount = order ? order.amount : null;
    const forced = await sendRazorpayWebhook({
        providerRef,
        paymentId,
        amount,
        status,
    });
    return {
        intent,
        forced,
        attemptId: intent.body.data.attempt.attemptId,
        providerRef,
        paymentId,
        amount,
    };
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
    payWithRazorpay,
    sendRazorpayWebhook,
    markDelivered,
};
