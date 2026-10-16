const { Prisma } = require('@prisma/client');
const prisma = require('../../config/database');
const logger = require('../../utils/logger');
const mockProvider = require('./mock.provider');
const { uploadBuffer } = require('../cloudinary-upload.service');
const { assertTransition, ORDER_STATUS } = require('../../constants/order-flow');
const { ConflictError, ForbiddenError, NotFoundError, ValidationError, AppError } = require('../../utils/errors');
const { emitOrderEvent } = require('../notification-events');

const PAYABLE = [
    ORDER_STATUS.PICKED_UP,
    ORDER_STATUS.SUBMITTED_TO_CM,
    ORDER_STATUS.RECEIVED_BY_COLLECTION,
    ORDER_STATUS.SUBMITTED_TO_SERVICES,
    ORDER_STATUS.SERVICES_IN_PROGRESS,
    ORDER_STATUS.SERVICES_COMPLETED,
    ORDER_STATUS.OUT_FOR_DELIVERY,
];

function providerFor() {
    return mockProvider;
}

function money(value) {
    return new Prisma.Decimal(value == null ? 0 : value);
}

async function loadCustomerOrder(customerId, orderId) {
    const order = await prisma.order.findFirst({
        where: { order_id: orderId, customer_id: customerId },
        include: { bill: true },
    });
    if (!order) throw new NotFoundError('Order');
    if (!order.bill) throw new ConflictError('Bill is not ready yet', 'BILL_NOT_READY');
    return order;
}

function assertCouponWindow(order) {
    if (!PAYABLE.includes(order.order_status)) {
        throw new ConflictError('A coupon can be applied only after the bill exists and before delivery', 'COUPON_NOT_ALLOWED');
    }
    if (order.bill.payment_status !== 'pending') {
        throw new ConflictError('The bill is already paid', 'BILL_ALREADY_PAID');
    }
}

async function assertNoLiveAttempt(orderId) {
    const live = await prisma.paymentAttempt.findFirst({
        where: { order_id: orderId, status: { in: ['initiated', 'pending'] } },
    });
    if (live) {
        throw new ConflictError('Cancel the open payment attempt before changing the coupon', 'ATTEMPT_OPEN');
    }
}

function computeDiscount(coupon, subtotal) {
    const base = money(subtotal);
    let discount =
        coupon.discount_type === 'percentage' || coupon.discount_type === 'percent'
            ? base.mul(money(coupon.discount_value)).div(100)
            : money(coupon.discount_value);
    if (coupon.max_discount != null) {
        const cap = money(coupon.max_discount);
        if (discount.gt(cap)) discount = cap;
    }
    if (discount.gt(base)) discount = base;
    if (discount.lt(0)) discount = new Prisma.Decimal(0);
    return discount;
}

function totals(bill, discount) {
    const finalAmount = money(bill.subtotal).add(money(bill.delivery_fee)).add(money(bill.express_fee)).sub(discount);
    const floor = new Prisma.Decimal('1.00');
    if (finalAmount.lt(floor)) {
        const cappedDiscount = money(bill.subtotal).add(money(bill.delivery_fee)).add(money(bill.express_fee)).sub(floor);
        return { discount: cappedDiscount.lt(0) ? new Prisma.Decimal(0) : cappedDiscount, finalAmount: floor };
    }
    return { discount, finalAmount };
}

async function usageCounts(couponId, customerId) {
    const [used, byUser] = await Promise.all([
        prisma.bill.count({ where: { coupon_id: couponId, payment_status: 'completed' } }),
        prisma.bill.count({
            where: { coupon_id: couponId, payment_status: 'completed', order: { customer_id: customerId } },
        }),
    ]);
    return { used, byUser };
}

async function applyCoupon({ customerId, orderId, code }) {
    const order = await loadCustomerOrder(customerId, orderId);
    assertCouponWindow(order);
    await assertNoLiveAttempt(orderId);
    const coupon = await prisma.coupon.findFirst({
        where: { code: { equals: code, mode: 'insensitive' }, is_active: true },
    });
    if (!coupon) throw new NotFoundError('Coupon');
    const now = new Date();
    if (coupon.valid_from && coupon.valid_from > now) throw new ConflictError('Coupon is not active yet', 'COUPON_INVALID');
    if (coupon.valid_till && coupon.valid_till < now) throw new ConflictError('Coupon has expired', 'COUPON_INVALID');
    if (coupon.min_order_value && money(order.bill.subtotal).lt(money(coupon.min_order_value))) {
        throw new ConflictError('Order is below the coupon minimum', 'COUPON_INVALID');
    }
    const counts = await usageCounts(coupon.id, customerId);
    if (coupon.usage_limit != null && counts.used >= coupon.usage_limit) {
        throw new ConflictError('Coupon usage limit reached', 'COUPON_INVALID');
    }
    if (coupon.usage_per_user != null && counts.byUser >= coupon.usage_per_user) {
        throw new ConflictError('You have already used this coupon', 'COUPON_INVALID');
    }
    const raw = computeDiscount(coupon, order.bill.subtotal);
    const next = totals(order.bill, raw);
    const bill = await prisma.bill.update({
        where: { bill_id: order.bill.bill_id },
        data: {
            discount: next.discount,
            final_amount: next.finalAmount,
            coupon_id: coupon.id,
            coupon_code: coupon.code,
        },
    });
    await prisma.order.update({
        where: { order_id: orderId },
        data: { total_amount: next.finalAmount },
    });
    return presentPayment(order, bill);
}

async function removeCoupon({ customerId, orderId }) {
    const order = await loadCustomerOrder(customerId, orderId);
    assertCouponWindow(order);
    await assertNoLiveAttempt(orderId);
    const next = totals(order.bill, new Prisma.Decimal(0));
    const bill = await prisma.bill.update({
        where: { bill_id: order.bill.bill_id },
        data: {
            discount: new Prisma.Decimal(0),
            final_amount: next.finalAmount,
            coupon_id: null,
            coupon_code: null,
        },
    });
    await prisma.order.update({
        where: { order_id: orderId },
        data: { total_amount: next.finalAmount },
    });
    return presentPayment(order, bill);
}

function presentPayment(order, bill, attempt) {
    return {
        orderId: order.order_id,
        paymentStatus: bill.payment_status,
        paymentMethod: bill.payment_method,
        subtotal: String(bill.subtotal),
        deliveryFee: String(bill.delivery_fee),
        expressFee: String(bill.express_fee),
        discount: String(bill.discount),
        finalAmount: String(bill.final_amount),
        couponCode: bill.coupon_code,
        attempt: attempt
            ? {
                  attemptId: attempt.attempt_id,
                  status: attempt.status,
                  provider: attempt.provider,
                  providerRef: attempt.provider_ref,
                  amount: String(attempt.amount),
                  intent: attempt.intent_payload,
                  failureReason: attempt.failure_reason,
              }
            : null,
    };
}

async function createPayIntent({ customerId, orderId, idempotencyKey }) {
    const order = await loadCustomerOrder(customerId, orderId);
    if (!PAYABLE.includes(order.order_status)) {
        throw new ConflictError('This order cannot be paid yet', 'PAY_NOT_ALLOWED');
    }
    if (order.bill.payment_status !== 'pending') {
        throw new ConflictError('The bill is already paid', 'BILL_ALREADY_PAID');
    }
    const key = idempotencyKey || `pay:${orderId}:${order.bill.bill_id}`;
    const existing = await prisma.paymentAttempt.findFirst({
        where: {
            order_id: orderId,
            status: { in: ['initiated', 'pending'] },
        },
        orderBy: { created_at: 'desc' },
    });
    if (existing) return presentPayment(order, order.bill, existing);

    const provider = providerFor();
    const attempt = await prisma.paymentAttempt.create({
        data: {
            order_id: orderId,
            bill_id: order.bill.bill_id,
            provider: provider.name,
            idempotency_key: key,
            amount: order.bill.final_amount,
            status: 'initiated',
        },
    });
    const intent = await provider.createIntent({
        amount: String(order.bill.final_amount),
        orderId,
        attemptId: attempt.attempt_id,
    });
    const saved = await prisma.paymentAttempt.update({
        where: { attempt_id: attempt.attempt_id },
        data: {
            provider_ref: intent.providerRef,
            intent_payload: intent.intentPayload,
            status: 'pending',
        },
    });
    return presentPayment(order, order.bill, saved);
}

async function applyWebhook({ providerName, headers, rawBody }) {
    if (providerName !== 'mock') throw new NotFoundError('Payment provider');
    const payload = mockProvider.verifyWebhook(headers, rawBody);
    const providerRef = payload.providerRef || payload.provider_ref;
    const status = payload.status;
    if (!providerRef || !['succeeded', 'failed'].includes(status)) {
        throw new ValidationError('Webhook payload must include providerRef and status succeeded|failed');
    }
    const attempt = await prisma.paymentAttempt.findFirst({
        where: { provider_ref: providerRef, provider: 'mock' },
        include: { bill: true },
    });
    if (!attempt) throw new NotFoundError('Payment attempt');
    if (attempt.status === 'succeeded' && attempt.bill.payment_status === 'completed' && attempt.bill.payment_method === 'upi') {
        return { duplicate: true, orderId: attempt.order_id };
    }

    if (status === 'failed') {
        if (attempt.status === 'failed') return { duplicate: true, orderId: attempt.order_id };
        await prisma.paymentAttempt.update({
            where: { attempt_id: attempt.attempt_id },
            data: { status: 'failed', failure_reason: payload.failureReason || 'failed' },
        });
        emitOrderEvent('payment_failed', { orderId: attempt.order_id }).catch(() => {});
        return { orderId: attempt.order_id, status: 'failed' };
    }

    const outcome = await prisma.$transaction(async (tx) => {
        const current = await tx.bill.findUnique({ where: { bill_id: attempt.bill_id } });
        if (current.payment_status === 'completed' && current.payment_method === 'cash') {
            await tx.paymentAttempt.update({
                where: { attempt_id: attempt.attempt_id },
                data: { status: 'succeeded', failure_reason: 'refund_required' },
            });
            return { refundRequired: true };
        }
        const won = await tx.bill.updateMany({
            where: { bill_id: attempt.bill_id, payment_status: 'pending' },
            data: {
                payment_status: 'completed',
                payment_method: 'upi',
                paid_at: new Date(),
                transaction_id: providerRef,
            },
        });
        await tx.paymentAttempt.update({
            where: { attempt_id: attempt.attempt_id },
            data: { status: 'succeeded', failure_reason: won.count === 0 ? attempt.failure_reason : null },
        });
        return { completed: won.count > 0 };
    });
    if (outcome.refundRequired) {
        logger.warn('UPI succeeded after cash was recorded', { orderId: attempt.order_id, providerRef });
    }
    if (outcome.completed) emitOrderEvent('payment_received', { orderId: attempt.order_id }).catch(() => {});
    return { orderId: attempt.order_id, ...outcome };
}

async function paymentStatus({ customerId, orderId }) {
    const order = await loadCustomerOrder(customerId, orderId);
    const attempt = await prisma.paymentAttempt.findFirst({
        where: { order_id: orderId },
        orderBy: { created_at: 'desc' },
    });
    return presentPayment(order, order.bill, attempt);
}

async function devForceAttempt({ attemptId, status }) {
    if (process.env.NODE_ENV === 'production') {
        throw new AppError('Mock payment controls are disabled in production', 404, 'NOT_FOUND');
    }
    if (!['succeeded', 'failed'].includes(status)) throw new ValidationError('status must be succeeded or failed');
    const attempt = await prisma.paymentAttempt.findUnique({ where: { attempt_id: Number(attemptId) } });
    if (!attempt || !attempt.provider_ref) throw new NotFoundError('Payment attempt');
    const body = JSON.stringify({
        providerRef: attempt.provider_ref,
        status,
        failureReason: status === 'failed' ? 'mock_failed' : null,
    });
    return applyWebhook({
        providerName: 'mock',
        headers: { 'x-mock-signature': mockProvider.signBody(body) },
        rawBody: body,
    });
}

async function recordCash({ staffId, orderId }) {
    const delivery = await prisma.delivery.findFirst({
        where: { order_id: orderId, delivery_type: 'drop', staff_id: staffId },
        include: { order: { include: { bill: true } } },
    });
    if (!delivery) throw new ForbiddenError('Only the assigned drop captain can record cash');
    if (delivery.order.order_status !== ORDER_STATUS.OUT_FOR_DELIVERY) {
        throw new ConflictError('Cash can be recorded only while the order is out for delivery', 'CASH_NOT_ALLOWED');
    }
    if (!delivery.order.bill || delivery.order.bill.payment_status !== 'pending') {
        throw new ConflictError('The bill is not awaiting payment', 'CASH_NOT_ALLOWED');
    }
    const latest = await prisma.paymentAttempt.findFirst({
        where: { order_id: orderId },
        orderBy: { created_at: 'desc' },
    });
    if (!latest || !['failed', 'expired', 'cancelled'].includes(latest.status)) {
        throw new ConflictError('Cash is available only after a UPI attempt has failed', 'CASH_NOT_ALLOWED');
    }
    const won = await prisma.bill.updateMany({
        where: { bill_id: delivery.order.bill.bill_id, payment_status: 'pending' },
        data: {
            payment_status: 'completed',
            payment_method: 'cash',
            cash_recorded_by: staffId,
            paid_at: new Date(),
        },
    });
    if (won.count === 0) throw new ConflictError('The bill was already paid', 'BILL_ALREADY_PAID');
    emitOrderEvent('payment_received', { orderId }).catch(() => {});
    return { orderId, paymentMethod: 'cash', paymentStatus: 'completed' };
}

async function markDelivered({ staffId, orderId, file }) {
    if (!file || !file.buffer) throw new ValidationError('Exactly one drop photo is required');
    const delivery = await prisma.delivery.findFirst({
        where: { order_id: orderId, delivery_type: 'drop', staff_id: staffId },
        include: { order: { include: { bill: true } } },
    });
    if (!delivery) throw new ForbiddenError('Only the assigned drop captain can mark this order delivered');
    if (delivery.order.order_status === ORDER_STATUS.DELIVERED) {
        return { orderId, orderStatus: ORDER_STATUS.DELIVERED, idempotent: true };
    }
    if (delivery.order.order_status !== ORDER_STATUS.OUT_FOR_DELIVERY) {
        throw new ConflictError('The order is not out for delivery', 'DELIVER_NOT_ALLOWED');
    }
    if (!delivery.order.bill || delivery.order.bill.payment_status !== 'completed') {
        throw new ConflictError('Payment must be completed before delivery', 'PAYMENT_REQUIRED');
    }
    assertTransition(delivery.order.order_status, ORDER_STATUS.DELIVERED);
    const photoUrl = await uploadBuffer({
        buffer: file.buffer,
        folder: `orders/${orderId}/drop`,
        mimetype: file.mimetype || 'image/jpeg',
    });
    const now = new Date();
    const moved = await prisma.order.updateMany({
        where: { order_id: orderId, order_status: ORDER_STATUS.OUT_FOR_DELIVERY },
        data: { order_status: ORDER_STATUS.DELIVERED },
    });
    if (moved.count === 0) {
        const current = await prisma.order.findUnique({ where: { order_id: orderId } });
        if (current?.order_status === ORDER_STATUS.DELIVERED) {
            return { orderId, orderStatus: ORDER_STATUS.DELIVERED, idempotent: true };
        }
        throw new ConflictError('The order is not out for delivery', 'DELIVER_NOT_ALLOWED');
    }
    await prisma.delivery.update({
        where: { delivery_id: delivery.delivery_id },
        data: { delivery_status: 'completed', completed_at: now },
    });
    await prisma.dropForDelivery.update({
        where: { delivery_id: delivery.delivery_id },
        data: { drop_status: 'completed', drop_time: now, drop_proof: photoUrl },
    });
    emitOrderEvent('delivered', { orderId }).catch(() => {});
    return { orderId, orderStatus: ORDER_STATUS.DELIVERED, dropProof: photoUrl };
}

module.exports = {
    applyCoupon,
    removeCoupon,
    createPayIntent,
    applyWebhook,
    paymentStatus,
    devForceAttempt,
    recordCash,
    markDelivered,
};
