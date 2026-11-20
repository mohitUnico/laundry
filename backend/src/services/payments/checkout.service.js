const crypto = require('crypto');
const { Prisma } = require('@prisma/client');
const prisma = require('../../config/database');
const logger = require('../../utils/logger');
const razorpayProvider = require('./razorpay.provider');
const { uploadBuffer } = require('../cloudinary-upload.service');
const { assertTransition, ORDER_STATUS } = require('../../constants/order-flow');
const { AppError, ConflictError, ForbiddenError, NotFoundError, ValidationError } = require('../../utils/errors');
const { emitOrderEvent } = require('../notification-events');

const VERIFYING_MESSAGE = "Your payment is being verified. Please don't pay again until we confirm its status.";
const LIVE = ['initiated', 'pending', 'uncertain'];

const PAYABLE = [
    ORDER_STATUS.PICKED_UP,
    ORDER_STATUS.SUBMITTED_TO_CM,
    ORDER_STATUS.RECEIVED_BY_COLLECTION,
    ORDER_STATUS.SUBMITTED_TO_SERVICES,
    ORDER_STATUS.SERVICES_IN_PROGRESS,
    ORDER_STATUS.SERVICES_COMPLETED,
    ORDER_STATUS.OUT_FOR_DELIVERY,
];

function amountPaise(amount) {
    return Number(money(amount).mul(100).toFixed(0));
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
        where: { order_id: orderId, status: { in: LIVE } },
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

function verificationState(bill, attempt, refund) {
    if (refund?.status === 'processed') return 'refund_completed';
    if (refund && (refund.status === 'pending' || refund.status === 'failed')) return 'refund_pending';
    if (bill.payment_status === 'completed') return bill.payment_method === 'cash' ? 'paid_cash' : 'paid';
    if (!attempt) return 'unpaid';
    if (attempt.reconciliation_status === 'needs_review' || attempt.status === 'uncertain') return 'unknown';
    if (attempt.status === 'failed') return 'failed';
    if (attempt.status === 'cancelled') return 'cancelled';
    if (attempt.status === 'expired') return 'expired';
    if (attempt.reconciliation_status === 'awaiting_capture') return 'verifying';
    if (attempt.status === 'pending' || attempt.status === 'initiated') return 'pending';
    return 'unknown';
}

function presentPayment(order, bill, attempt, refund) {
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
        transactionId: bill.transaction_id || null,
        verificationState: verificationState(bill, attempt, refund),
        refund: refund
            ? {
                  refundId: refund.razorpay_refund_id || null,
                  status: refund.status,
                  amount: String(refund.amount),
                  reason: refund.reason,
              }
            : null,
        attempt: attempt
            ? {
                  attemptId: attempt.attempt_id,
                  status: attempt.status,
                  provider: attempt.provider,
                  providerRef: attempt.provider_ref,
                  amount: String(attempt.amount),
                  intent: attempt.intent_payload,
                  failureReason: attempt.failure_reason,
                  reconciliationStatus: attempt.reconciliation_status || null,
              }
            : null,
    };
}

function isUncertain(error) {
    return error && (error.code === 'PAYMENT_OUTCOME_UNKNOWN' || error.code === 'RAZORPAY_RATE_LIMIT');
}

async function withBill(attempt) {
    if (!attempt || attempt.bill) return attempt;
    const bill = await prisma.bill.findUnique({ where: { bill_id: attempt.bill_id } });
    return { ...attempt, bill };
}

async function latestRefund(billId) {
    return prisma.paymentRefund.findFirst({
        where: { bill_id: billId },
        orderBy: { created_at: 'desc' },
    });
}

async function reloadAttempt(attemptId) {
    const fresh = await prisma.paymentAttempt.findUnique({ where: { attempt_id: attemptId } });
    return withBill(fresh);
}

function checked(extra = {}) {
    return { last_checked_at: new Date(), check_count: { increment: 1 }, ...extra };
}

async function issueRefund({ attempt, paymentId, reason, actor }) {
    if (!paymentId || !String(paymentId).startsWith('pay_')) {
        logger.warn('Captured payment needs review before a refund', { orderId: attempt.order_id });
        return null;
    }
    const key = `refund:${paymentId}`;
    let row = await prisma.paymentRefund.findUnique({ where: { idempotency_key: key } });
    if (row?.status === 'processed') return row;
    if (row?.razorpay_refund_id) {
        try {
            const remote = await razorpayProvider.fetchRefund(row.razorpay_refund_id);
            const status = remote.status === 'processed' ? 'processed' : remote.status === 'failed' ? 'failed' : 'pending';
            row = await prisma.paymentRefund.update({ where: { id: row.id }, data: { status } });
            if (row.status === 'processed') return row;
        } catch (error) {
            if (isUncertain(error)) return row;
        }
    }
    if (!row) {
        try {
            row = await prisma.paymentRefund.create({
                data: {
                    attempt_id: attempt.attempt_id,
                    bill_id: attempt.bill_id,
                    razorpay_payment_id: paymentId,
                    amount: attempt.amount,
                    status: 'pending',
                    reason: String(reason || 'refund').slice(0, 255),
                    idempotency_key: key,
                    created_by: actor || 'system',
                },
            });
        } catch (error) {
            if (error.code !== 'P2002') throw error;
            return prisma.paymentRefund.findUnique({ where: { idempotency_key: key } });
        }
    }
    if (row.status === 'processed') return row;
    try {
        const remote = await razorpayProvider.createRefund(paymentId, amountPaise(attempt.amount), { reason });
        row = await prisma.paymentRefund.update({
            where: { id: row.id },
            data: {
                razorpay_refund_id: remote.id,
                status: remote.status === 'processed' ? 'processed' : 'pending',
            },
        });
        logger.info('Refund requested', { orderId: attempt.order_id, refundId: remote.id, status: row.status, actor: actor || 'system' });
        return row;
    } catch (error) {
        if (error.code === 'REFUND_ALREADY_ISSUED') {
            return prisma.paymentRefund.update({ where: { id: row.id }, data: { status: 'processed' } });
        }
        if (isUncertain(error)) {
            logger.warn('Refund outcome is unknown', { orderId: attempt.order_id });
            return row;
        }
        logger.warn('Refund request failed', { orderId: attempt.order_id, message: error.message });
        return prisma.paymentRefund.update({ where: { id: row.id }, data: { status: 'failed' } });
    }
}

async function settleAttempt({ attempt, status, failureReason, paymentId, paymentMethod }) {
    const loaded = await withBill(attempt);
    const currentBill = loaded.bill;
    const sameOnline =
        loaded.status === 'succeeded' &&
        currentBill.payment_status === 'completed' &&
        currentBill.payment_method &&
        currentBill.payment_method !== 'cash' &&
        (!paymentId || currentBill.transaction_id === paymentId);
    if (status !== 'failed' && sameOnline) return { duplicate: true, orderId: loaded.order_id };

    if (status === 'failed') {
        if (loaded.status === 'succeeded' || currentBill.payment_status === 'completed' || loaded.status === 'failed') {
            return { duplicate: true, orderId: loaded.order_id };
        }
        await prisma.paymentAttempt.update({
            where: { attempt_id: loaded.attempt_id },
            data: {
                status: 'failed',
                failure_reason: failureReason || 'failed',
                razorpay_payment_id: paymentId || loaded.razorpay_payment_id,
                reconciliation_status: null,
            },
        });
        emitOrderEvent('payment_failed', { orderId: loaded.order_id }).catch(() => {});
        return { orderId: loaded.order_id, status: 'failed' };
    }

    const transactionId = paymentId || loaded.provider_ref;
    const outcome = await prisma.$transaction(async (tx) => {
        const current = await tx.bill.findUnique({ where: { bill_id: loaded.bill_id } });
        const paidOnline = current.payment_status === 'completed' && current.payment_method && current.payment_method !== 'cash';
        const paidAnotherWay = current.payment_status === 'completed' && (current.payment_method === 'cash' || (paidOnline && current.transaction_id !== transactionId));
        if (paidAnotherWay) {
            await tx.paymentAttempt.update({
                where: { attempt_id: loaded.attempt_id },
                data: {
                    status: 'succeeded',
                    failure_reason: 'refund_required',
                    razorpay_payment_id: paymentId || loaded.razorpay_payment_id,
                    reconciliation_status: null,
                },
            });
            return { refundRequired: true };
        }
        if (paidOnline && current.transaction_id === transactionId) {
            await tx.paymentAttempt.update({
                where: { attempt_id: loaded.attempt_id },
                data: {
                    status: 'succeeded',
                    failure_reason: null,
                    razorpay_payment_id: paymentId || loaded.razorpay_payment_id,
                    reconciliation_status: null,
                },
            });
            return { duplicate: true };
        }
        const won = await tx.bill.updateMany({
            where: { bill_id: loaded.bill_id, payment_status: 'pending' },
            data: {
                payment_status: 'completed',
                payment_method: paymentMethod || 'upi',
                paid_at: new Date(),
                transaction_id: transactionId,
            },
        });
        await tx.paymentAttempt.update({
            where: { attempt_id: loaded.attempt_id },
            data: {
                status: 'succeeded',
                failure_reason: won.count === 0 ? 'refund_required' : null,
                razorpay_payment_id: paymentId || loaded.razorpay_payment_id,
                reconciliation_status: null,
            },
        });
        return won.count === 0 ? { refundRequired: true } : { completed: true };
    });
    if (outcome.refundRequired) {
        const refund = await issueRefund({
            attempt: loaded,
            paymentId,
            reason: 'Captured after the bill was already paid',
            actor: 'system',
        });
        logger.warn('Captured payment arrived after the bill was paid', {
            orderId: loaded.order_id,
            refundStatus: refund?.status || 'pending',
        });
        return { orderId: loaded.order_id, refundRequired: true, refundStatus: refund?.status || 'pending' };
    }
    if (outcome.completed) emitOrderEvent('payment_received', { orderId: loaded.order_id }).catch(() => {});
    return { orderId: loaded.order_id, ...outcome };
}

async function syncAttemptFromGateway(attempt) {
    const loaded = await withBill(attempt);
    if (!loaded.provider_ref) return { outcome: 'unknown', attempt: loaded };
    let items;
    try {
        const collection = await razorpayProvider.listOrderPayments(loaded.provider_ref);
        items = collection.items || collection;
    } catch (error) {
        if (!isUncertain(error)) throw error;
        const saved = await prisma.paymentAttempt.update({
            where: { attempt_id: loaded.attempt_id },
            data: checked({
                status: 'uncertain',
                reconciliation_status: 'needs_review',
                failure_reason: 'gateway_unreachable',
            }),
        });
        return { outcome: 'unknown', attempt: await withBill(saved) };
    }
    const summary = razorpayProvider.summarizePayments(items);
    if (summary.outcome === 'captured') {
        await settleAttempt({
            attempt: loaded,
            status: 'succeeded',
            paymentId: summary.payment.id,
            paymentMethod: summary.payment.method || 'upi',
        });
        return { outcome: 'captured', attempt: await reloadAttempt(loaded.attempt_id), payment: summary.payment };
    }
    if (summary.outcome === 'authorized') {
        if (loaded.status === 'succeeded') return { outcome: 'authorized', attempt: loaded };
        const saved = await prisma.paymentAttempt.update({
            where: { attempt_id: loaded.attempt_id },
            data: checked({
                status: 'pending',
                razorpay_payment_id: summary.payment.id,
                reconciliation_status: 'awaiting_capture',
            }),
        });
        return { outcome: 'authorized', attempt: await withBill(saved), payment: summary.payment };
    }
    if (summary.outcome === 'failed') {
        const billPaidOnline = loaded.bill?.payment_status === 'completed' && loaded.bill?.payment_method !== 'cash';
        if (loaded.status !== 'succeeded' && !billPaidOnline) {
            const saved = await prisma.paymentAttempt.update({
                where: { attempt_id: loaded.attempt_id },
                data: checked({
                    status: 'failed',
                    failure_reason: summary.payment.error_description || summary.payment.error_code || 'failed',
                    razorpay_payment_id: summary.payment.id || loaded.razorpay_payment_id,
                    reconciliation_status: null,
                }),
            });
            return { outcome: 'failed', attempt: await withBill(saved) };
        }
        return { outcome: 'failed', attempt: loaded };
    }
    const saved = await prisma.paymentAttempt.update({
        where: { attempt_id: loaded.attempt_id },
        data: checked(),
    });
    return { outcome: 'none', attempt: await withBill(saved) };
}

async function tryResolveReceipt(attempt) {
    const receipt = `att_${attempt.attempt_id}`.slice(0, 40);
    try {
        const found = await razorpayProvider.findOrderByReceipt(receipt);
        if (!found?.id) return null;
        return prisma.paymentAttempt.update({
            where: { attempt_id: attempt.attempt_id },
            data: { provider_ref: found.id, status: 'pending', reconciliation_status: null },
        });
    } catch (error) {
        if (isUncertain(error)) return null;
        throw error;
    }
}

async function openIntent(order, attempt) {
    try {
        const intent = await razorpayProvider.createIntent({
            amount: String(order.bill.final_amount),
            orderId: order.order_id,
            attemptId: attempt.attempt_id,
        });
        const saved = await prisma.paymentAttempt.update({
            where: { attempt_id: attempt.attempt_id },
            data: {
                provider: razorpayProvider.name,
                provider_ref: intent.providerRef,
                intent_payload: intent.intentPayload,
                status: 'pending',
                failure_reason: null,
                reconciliation_status: null,
            },
        });
        return presentPayment(order, order.bill, saved, await latestRefund(order.bill.bill_id));
    } catch (error) {
        if (isUncertain(error)) {
            await prisma.paymentAttempt.update({
                where: { attempt_id: attempt.attempt_id },
                data: {
                    status: 'uncertain',
                    failure_reason: 'outcome_unknown',
                    reconciliation_status: 'needs_review',
                },
            });
            throw new AppError(VERIFYING_MESSAGE, 503, 'PAYMENT_OUTCOME_UNKNOWN');
        }
        await prisma.paymentAttempt.update({
            where: { attempt_id: attempt.attempt_id },
            data: { status: 'failed', failure_reason: 'intent_failed', reconciliation_status: null },
        });
        throw error;
    }
}

async function createPayIntent({ customerId, orderId, idempotencyKey }) {
    const order = await loadCustomerOrder(customerId, orderId);
    if (!PAYABLE.includes(order.order_status)) {
        throw new ConflictError('This order cannot be paid yet', 'PAY_NOT_ALLOWED');
    }
    if (order.bill.payment_status !== 'pending') {
        throw new ConflictError('The bill is already paid', 'BILL_ALREADY_PAID');
    }
    const live = await prisma.paymentAttempt.findFirst({
        where: { order_id: orderId, status: { in: LIVE } },
        orderBy: { created_at: 'desc' },
    });
    if (live?.status === 'uncertain' && !live.provider_ref) {
        const resolved = await tryResolveReceipt(live);
        if (!resolved) return presentPayment(order, order.bill, live, await latestRefund(order.bill.bill_id));
        const synced = await syncAttemptFromGateway(resolved);
        if (synced.outcome === 'captured') {
            const fresh = await loadCustomerOrder(customerId, orderId);
            return presentPayment(fresh, fresh.bill, synced.attempt, await latestRefund(fresh.bill.bill_id));
        }
        return presentPayment(order, order.bill, synced.attempt, await latestRefund(order.bill.bill_id));
    }
    if (live?.provider_ref) {
        const synced = await syncAttemptFromGateway(live);
        if (synced.outcome === 'captured') {
            const fresh = await loadCustomerOrder(customerId, orderId);
            return presentPayment(fresh, fresh.bill, synced.attempt, await latestRefund(fresh.bill.bill_id));
        }
        if (synced.outcome === 'failed') {
            // The gateway confirmed this checkout cannot be captured. A new order is safe.
        } else {
            return presentPayment(order, order.bill, synced.attempt, await latestRefund(order.bill.bill_id));
        }
    } else if (live) {
        return openIntent(order, live);
    }

    const prior = await prisma.paymentAttempt.count({ where: { order_id: orderId } });
    const keyBase = idempotencyKey || `pay:${orderId}:${order.bill.bill_id}`;
    let attempt;
    try {
        attempt = await prisma.paymentAttempt.create({
            data: {
                order_id: orderId,
                bill_id: order.bill.bill_id,
                provider: razorpayProvider.name,
                idempotency_key: idempotencyKey || `${keyBase}:${prior + 1}`,
                amount: order.bill.final_amount,
                status: 'initiated',
            },
        });
    } catch (error) {
        if (error.code !== 'P2002') throw error;
        const again = await prisma.paymentAttempt.findFirst({
            where: { order_id: orderId, status: { in: LIVE } },
            orderBy: { created_at: 'desc' },
        });
        if (again) return presentPayment(order, order.bill, again, await latestRefund(order.bill.bill_id));
        throw error;
    }
    return openIntent(order, attempt);
}

async function applyRefundEvent(payload) {
    const status = payload.status === 'refund_processed' ? 'processed' : 'failed';
    let refund = await prisma.paymentRefund.findFirst({ where: { razorpay_payment_id: payload.paymentId } });
    if (!refund && payload.refundId) {
        refund = await prisma.paymentRefund.findFirst({ where: { razorpay_refund_id: payload.refundId } });
    }
    if (!refund) {
        const attempt = await prisma.paymentAttempt.findFirst({ where: { razorpay_payment_id: payload.paymentId } });
        if (!attempt) return { ignored: true };
        try {
            refund = await prisma.paymentRefund.create({
                data: {
                    attempt_id: attempt.attempt_id,
                    bill_id: attempt.bill_id,
                    razorpay_payment_id: payload.paymentId,
                    razorpay_refund_id: payload.refundId,
                    amount: attempt.amount,
                    status,
                    reason: 'gateway_refund_event',
                    idempotency_key: `refund:${payload.paymentId}`,
                    created_by: 'webhook',
                },
            });
        } catch (error) {
            if (error.code !== 'P2002') throw error;
            refund = await prisma.paymentRefund.findUnique({ where: { idempotency_key: `refund:${payload.paymentId}` } });
        }
    }
    if (!refund) return { ignored: true };
    const updated = await prisma.paymentRefund.update({
        where: { id: refund.id },
        data: { status, razorpay_refund_id: payload.refundId || refund.razorpay_refund_id },
    });
    return { refundId: updated.razorpay_refund_id, status: updated.status };
}

async function dispatchWebhook(payload) {
    if (payload.kind === 'refund') return applyRefundEvent(payload);
    const providerRef = payload.providerRef;
    if (!providerRef) throw new ValidationError('Webhook payload is missing the Razorpay order id');
    const attempt = await prisma.paymentAttempt.findFirst({
        where: { provider_ref: providerRef, provider: 'razorpay' },
        include: { bill: true },
    });
    if (!attempt) throw new NotFoundError('Payment attempt');
    if (payload.amountPaise != null && amountPaise(attempt.amount) !== Number(payload.amountPaise)) {
        throw new ValidationError('Payment amount does not match the bill');
    }
    if (payload.status === 'authorized') {
        if (attempt.status !== 'succeeded') {
            await prisma.paymentAttempt.update({
                where: { attempt_id: attempt.attempt_id },
                data: {
                    status: 'pending',
                    razorpay_payment_id: payload.paymentId || attempt.razorpay_payment_id,
                    reconciliation_status: 'awaiting_capture',
                    last_checked_at: new Date(),
                },
            });
        }
        return { awaitingCapture: true, orderId: attempt.order_id };
    }
    if (payload.status === 'succeeded' && !payload.paymentId) {
        const synced = await syncAttemptFromGateway(attempt);
        return { orderId: attempt.order_id, outcome: synced.outcome };
    }
    if (!['succeeded', 'failed'].includes(payload.status)) return { ignored: true };
    return settleAttempt({
        attempt,
        status: payload.status,
        failureReason: payload.failureReason,
        paymentId: payload.paymentId,
        paymentMethod: payload.paymentMethod,
    });
}

async function applyWebhook({ providerName, headers, rawBody }) {
    if (providerName !== razorpayProvider.name) throw new NotFoundError('Payment provider');
    const payload = razorpayProvider.verifyWebhook(headers, rawBody);
    const eventId = headers['x-razorpay-event-id'] || crypto.createHash('sha256').update(String(rawBody)).digest('hex');
    let row = await prisma.paymentWebhookEvent.findUnique({ where: { event_id: eventId } });
    if (row?.status === 'processed') return { duplicate: true };
    if (!row) {
        try {
            row = await prisma.paymentWebhookEvent.create({
                data: {
                    event_id: eventId,
                    event_name: payload.eventName || 'unknown',
                    status: 'received',
                },
            });
        } catch (error) {
            if (error.code !== 'P2002') throw error;
            row = await prisma.paymentWebhookEvent.findUnique({ where: { event_id: eventId } });
            if (row?.status === 'processed') return { duplicate: true };
        }
    }
    if (!row) throw new AppError('Webhook event could not be recorded', 500, 'WEBHOOK_NOT_RECORDED');
    try {
        const result = payload.ignored ? { ignored: true } : await dispatchWebhook(payload);
        await prisma.paymentWebhookEvent.update({
            where: { id: row.id },
            data: { status: 'processed', processed_at: new Date(), error: null },
        });
        return result;
    } catch (error) {
        await prisma.paymentWebhookEvent.update({
            where: { id: row.id },
            data: { status: 'failed', error: String(error.message || 'failed').slice(0, 300) },
        }).catch(() => {});
        throw error;
    }
}

async function confirmRazorpayPayment({ customerId, orderId, razorpayOrderId, razorpayPaymentId, razorpaySignature }) {
    const order = await loadCustomerOrder(customerId, orderId);
    const attempt = await prisma.paymentAttempt.findFirst({
        where: { order_id: orderId, provider: 'razorpay', provider_ref: razorpayOrderId },
        orderBy: { created_at: 'desc' },
        include: { bill: true },
    });
    if (!attempt) throw new NotFoundError('Payment attempt');
    if (
        attempt.status === 'succeeded' &&
        attempt.bill.payment_status === 'completed' &&
        attempt.bill.payment_method !== 'cash'
    ) {
        return presentPayment(order, attempt.bill, attempt, await latestRefund(attempt.bill_id));
    }
    razorpayProvider.verifyCheckoutSignature({ razorpayOrderId, razorpayPaymentId, razorpaySignature });
    let remote;
    try {
        remote = await razorpayProvider.fetchPayment(razorpayPaymentId);
    } catch (error) {
        if (!isUncertain(error)) throw error;
        await prisma.paymentAttempt.update({
            where: { attempt_id: attempt.attempt_id },
            data: {
                status: attempt.status === 'failed' ? 'failed' : 'uncertain',
                reconciliation_status: 'needs_review',
                failure_reason: 'outcome_unknown',
            },
        });
        throw new AppError(VERIFYING_MESSAGE, 503, 'PAYMENT_OUTCOME_UNKNOWN');
    }
    if (remote.order_id !== razorpayOrderId) {
        throw new ValidationError('Payment does not belong to this checkout');
    }
    if (amountPaise(attempt.amount) !== Number(remote.amount)) {
        throw new ValidationError('Payment amount does not match the bill');
    }
    if (remote.status === 'authorized') {
        await prisma.paymentAttempt.update({
            where: { attempt_id: attempt.attempt_id },
            data: {
                status: 'pending',
                razorpay_payment_id: razorpayPaymentId,
                reconciliation_status: 'awaiting_capture',
                last_checked_at: new Date(),
            },
        });
        throw new ConflictError(VERIFYING_MESSAGE, 'PAYMENT_AWAITING_CAPTURE');
    }
    if (remote.status === 'failed') {
        await settleAttempt({
            attempt,
            status: 'failed',
            failureReason: remote.error_description || remote.error_code || 'failed',
            paymentId: razorpayPaymentId,
        });
        throw new ConflictError('Payment failed', 'PAYMENT_FAILED');
    }
    if (remote.status !== 'captured') {
        throw new ConflictError('Payment is not captured', 'PAYMENT_NOT_CAPTURED');
    }
    await settleAttempt({
        attempt,
        status: 'succeeded',
        paymentId: razorpayPaymentId,
        paymentMethod: remote.method || 'upi',
    });
    const fresh = await loadCustomerOrder(customerId, orderId);
    const saved = await prisma.paymentAttempt.findUnique({ where: { attempt_id: attempt.attempt_id } });
    return presentPayment(fresh, fresh.bill, saved, await latestRefund(fresh.bill.bill_id));
}

async function paymentStatus({ customerId, orderId }) {
    const order = await loadCustomerOrder(customerId, orderId);
    const attempt = await prisma.paymentAttempt.findFirst({
        where: { order_id: orderId },
        orderBy: { created_at: 'desc' },
    });
    return presentPayment(order, order.bill, attempt, await latestRefund(order.bill.bill_id));
}

async function cancelCheckout({ customerId, orderId }) {
    const order = await loadCustomerOrder(customerId, orderId);
    const attempt = await prisma.paymentAttempt.findFirst({
        where: { order_id: orderId, status: { in: LIVE } },
        orderBy: { created_at: 'desc' },
    });
    if (!attempt) {
        const latest = await prisma.paymentAttempt.findFirst({
            where: { order_id: orderId },
            orderBy: { created_at: 'desc' },
        });
        return presentPayment(order, order.bill, latest, await latestRefund(order.bill.bill_id));
    }
    if (!attempt.provider_ref) {
        if (attempt.status === 'uncertain') {
            return presentPayment(order, order.bill, attempt, await latestRefund(order.bill.bill_id));
        }
        const saved = await prisma.paymentAttempt.update({
            where: { attempt_id: attempt.attempt_id },
            data: { status: 'cancelled', failure_reason: 'customer_cancelled' },
        });
        return presentPayment(order, order.bill, saved, await latestRefund(order.bill.bill_id));
    }
    const synced = await syncAttemptFromGateway(attempt);
    if (synced.outcome === 'captured') {
        const fresh = await loadCustomerOrder(customerId, orderId);
        return presentPayment(fresh, fresh.bill, synced.attempt, await latestRefund(fresh.bill.bill_id));
    }
    if (synced.outcome === 'authorized' || synced.outcome === 'unknown') {
        return presentPayment(order, order.bill, synced.attempt, await latestRefund(order.bill.bill_id));
    }
    if (synced.outcome === 'none' && synced.attempt.status !== 'succeeded') {
        const saved = await prisma.paymentAttempt.update({
            where: { attempt_id: attempt.attempt_id },
            data: { status: 'cancelled', failure_reason: 'customer_cancelled', reconciliation_status: null },
        });
        return presentPayment(order, order.bill, saved, await latestRefund(order.bill.bill_id));
    }
    return presentPayment(order, order.bill, synced.attempt, await latestRefund(order.bill.bill_id));
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
    let latest = await prisma.paymentAttempt.findFirst({
        where: { order_id: orderId },
        orderBy: { created_at: 'desc' },
    });
    if (latest && LIVE.includes(latest.status)) {
        const synced = await syncAttemptFromGateway(latest);
        if (synced.outcome === 'captured') throw new ConflictError('The bill was paid online', 'BILL_ALREADY_PAID');
        if (synced.outcome === 'authorized' || synced.outcome === 'unknown') {
            throw new ConflictError(VERIFYING_MESSAGE, 'PAYMENT_OUTCOME_UNKNOWN');
        }
        latest = synced.attempt;
    }
    if (latest?.provider_ref && ['failed', 'expired', 'cancelled'].includes(latest.status)) {
        const synced = await syncAttemptFromGateway(latest);
        if (synced.outcome === 'captured') throw new ConflictError('The bill was paid online', 'BILL_ALREADY_PAID');
        if (synced.outcome === 'authorized' || synced.outcome === 'unknown') {
            throw new ConflictError(VERIFYING_MESSAGE, 'PAYMENT_OUTCOME_UNKNOWN');
        }
        latest = synced.attempt;
    }
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

async function requestManualRefund({ actorId, orderId, reason }) {
    const note = String(reason || '').trim();
    if (note.length < 3) throw new ValidationError('A refund reason is required');
    const order = await prisma.order.findUnique({
        where: { order_id: orderId },
        include: { bill: true },
    });
    if (!order?.bill) throw new NotFoundError('Bill');
    if (order.bill.payment_status !== 'completed' || order.bill.payment_method === 'cash' || !order.bill.transaction_id) {
        throw new ConflictError('Only a completed online payment can be refunded', 'REFUND_NOT_ALLOWED');
    }
    const remote = await razorpayProvider.fetchPayment(order.bill.transaction_id);
    if (remote.status !== 'captured' && remote.status !== 'refunded') {
        throw new ConflictError('The payment is not captured, so it will not be refunded', 'REFUND_NOT_ALLOWED');
    }
    const attempt = await prisma.paymentAttempt.findFirst({
        where: { order_id: orderId, razorpay_payment_id: order.bill.transaction_id },
        orderBy: { created_at: 'desc' },
    });
    if (!attempt) throw new NotFoundError('Payment attempt');
    const refund = await issueRefund({
        attempt,
        paymentId: order.bill.transaction_id,
        reason: note,
        actor: actorId,
    });
    logger.info('Manual refund requested', { orderId, actorId, refundStatus: refund?.status || 'pending' });
    return {
        orderId,
        refundId: refund?.razorpay_refund_id || null,
        status: refund?.status || 'pending',
    };
}

async function reconcilePendingPayments() {
    const intervalMinutes = Number(process.env.PAYMENT_RECONCILIATION_INTERVAL_MINUTES || 5);
    const staleMinutes = Number(process.env.PAYMENT_ATTEMPT_STALE_MINUTES || 30);
    const maxChecks = 20;
    const olderThan = new Date(Date.now() - Math.max(1, intervalMinutes) * 60 * 1000);
    const attempts = await prisma.paymentAttempt.findMany({
        where: {
            status: { in: LIVE },
            check_count: { lt: maxChecks },
            OR: [{ last_checked_at: null }, { last_checked_at: { lt: olderThan } }],
        },
        include: { bill: true },
        orderBy: { created_at: 'asc' },
        take: 50,
    });
    for (const attempt of attempts) {
        try {
            if (!attempt.provider_ref) {
                const resolved = await tryResolveReceipt(attempt);
                if (!resolved) {
                    const nextCount = (attempt.check_count || 0) + 1;
                    await prisma.paymentAttempt.update({
                        where: { attempt_id: attempt.attempt_id },
                        data: checked({
                            status: 'uncertain',
                            reconciliation_status: 'needs_review',
                        }),
                    });
                    if (nextCount >= maxChecks) {
                        logger.warn('Payment attempt needs manual review', { attemptId: attempt.attempt_id, orderId: attempt.order_id });
                    }
                    continue;
                }
                await syncAttemptFromGateway(await withBill(resolved));
                continue;
            }
            const synced = await syncAttemptFromGateway(attempt);
            if (synced.outcome === 'none' && attempt.bill?.payment_status === 'pending') {
                const ageMs = Date.now() - new Date(attempt.created_at).getTime();
                if (ageMs > Math.max(1, staleMinutes) * 60 * 1000) {
                    await prisma.paymentAttempt.update({
                        where: { attempt_id: attempt.attempt_id },
                        data: { status: 'expired', failure_reason: 'stale', reconciliation_status: null },
                    });
                }
            }
        } catch (error) {
            logger.warn('Payment reconciliation skipped an attempt', { attemptId: attempt.attempt_id, message: error.message });
        }
    }

    const refunds = await prisma.paymentRefund.findMany({
        where: { status: 'pending' },
        orderBy: { created_at: 'asc' },
        take: 50,
    });
    for (const refund of refunds) {
        try {
            const attempt = await prisma.paymentAttempt.findUnique({ where: { attempt_id: refund.attempt_id } });
            if (!attempt) continue;
            await issueRefund({
                attempt,
                paymentId: refund.razorpay_payment_id,
                reason: refund.reason,
                actor: refund.created_by || 'system',
            });
        } catch (error) {
            logger.warn('Refund reconciliation failed', { refundId: refund.id, message: error.message });
        }
    }

    const failedEvents = await prisma.paymentWebhookEvent.findMany({
        where: { status: 'failed' },
        take: 20,
    });
    if (failedEvents.length > 0) {
        logger.warn('Failed payment webhooks need review', { count: failedEvents.length });
    }
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
    confirmRazorpayPayment,
    paymentStatus,
    cancelCheckout,
    recordCash,
    requestManualRefund,
    reconcilePendingPayments,
    markDelivered,
};
