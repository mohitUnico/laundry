const crypto = require('crypto');
const { AppError, UnauthorizedError, ValidationError } = require('../../utils/errors');

const API_BASE = 'https://api.razorpay.com/v1';

function keyId() {
    return process.env.RAZORPAY_KEY_ID || '';
}

function keySecret() {
    return process.env.RAZORPAY_KEY_SECRET || '';
}

function webhookSecret() {
    return process.env.RAZORPAY_WEBHOOK_SECRET || '';
}

function timeoutMs() {
    const parsed = Number(process.env.PAYMENT_API_TIMEOUT_MS || 10000);
    return Number.isFinite(parsed) && parsed > 0 ? parsed : 10000;
}

function maxRetries() {
    const parsed = Number(process.env.PAYMENT_MAX_RETRIES || 3);
    if (!Number.isFinite(parsed) || parsed < 1) return 3;
    return Math.min(parsed, 5);
}

function assertKeys() {
    if (!keyId() || !keySecret()) {
        throw new AppError('Razorpay keys are not configured', 503, 'PAYMENTS_NOT_CONFIGURED');
    }
}

function safeEqual(given, expected) {
    const left = Buffer.from(String(given));
    const right = Buffer.from(String(expected));
    if (left.length !== right.length) return false;
    return crypto.timingSafeEqual(left, right);
}

function toPaise(amount) {
    const rupees = Number(amount);
    if (!Number.isFinite(rupees) || rupees <= 0) {
        throw new ValidationError('Payment amount must be greater than zero');
    }
    return Math.round(rupees * 100);
}

function sleep(ms) {
    return new Promise((resolve) => setTimeout(resolve, ms));
}

function unknownOutcome(message) {
    return new AppError(message, 503, 'PAYMENT_OUTCOME_UNKNOWN');
}

async function razorpayRequestOnce(method, path, body) {
    assertKeys();
    const auth = Buffer.from(`${keyId()}:${keySecret()}`).toString('base64');
    const controller = new AbortController();
    const timer = setTimeout(() => controller.abort(), timeoutMs());
    let response;
    try {
        response = await fetch(`${API_BASE}${path}`, {
            method,
            headers: {
                Authorization: `Basic ${auth}`,
                'Content-Type': 'application/json',
            },
            body: body ? JSON.stringify(body) : undefined,
            signal: controller.signal,
        });
    } catch (error) {
        const aborted = error && (error.name === 'AbortError' || error.name === 'TimeoutError');
        throw unknownOutcome(aborted ? 'Razorpay did not respond in time' : 'Razorpay could not be reached');
    } finally {
        clearTimeout(timer);
    }
    const data = await response.json().catch(() => ({}));
    if (response.status === 429) {
        throw new AppError('Razorpay is busy', 503, 'RAZORPAY_RATE_LIMIT');
    }
    if (!response.ok) {
        const message = data?.error?.description || 'Razorpay request failed';
        if (response.status >= 500) throw unknownOutcome(message);
        throw new AppError(message, 502, 'RAZORPAY_ERROR');
    }
    return data;
}

async function razorpayRequest(method, path, body, { read = false } = {}) {
    const attempts = read ? maxRetries() : 1;
    let lastError;
    for (let attempt = 0; attempt < attempts; attempt += 1) {
        try {
            return await razorpayRequestOnce(method, path, body);
        } catch (error) {
            lastError = error;
            const retryable = error.code === 'PAYMENT_OUTCOME_UNKNOWN' || error.code === 'RAZORPAY_RATE_LIMIT';
            if (!read || !retryable || attempt === attempts - 1) throw error;
            await sleep(200 * 2 ** attempt);
        }
    }
    throw lastError;
}

async function createIntent({ amount, orderId, attemptId }) {
    const amountPaise = toPaise(amount);
    const order = await razorpayRequest('POST', '/orders', {
        amount: amountPaise,
        currency: 'INR',
        receipt: `att_${attemptId}`.slice(0, 40),
        payment_capture: 1,
        notes: {
            orderId: String(orderId),
            attemptId: String(attemptId),
        },
    });
    return {
        providerRef: order.id,
        intentPayload: {
            provider: 'razorpay',
            keyId: keyId(),
            razorpayOrderId: order.id,
            amount: amountPaise,
            currency: 'INR',
        },
    };
}

function verifyCheckoutSignature({ razorpayOrderId, razorpayPaymentId, razorpaySignature }) {
    assertKeys();
    if (!razorpayOrderId || !razorpayPaymentId || !razorpaySignature) {
        throw new ValidationError('Razorpay payment details are required');
    }
    const expected = crypto
        .createHmac('sha256', keySecret())
        .update(`${razorpayOrderId}|${razorpayPaymentId}`)
        .digest('hex');
    if (!safeEqual(razorpaySignature, expected)) {
        throw new UnauthorizedError('Invalid Razorpay payment signature');
    }
}

function verifyWebhook(headers, rawBody) {
    const secret = webhookSecret();
    if (!secret) throw new AppError('Razorpay webhook secret is not configured', 503, 'PAYMENTS_NOT_CONFIGURED');
    const signature = headers['x-razorpay-signature'];
    if (!signature) throw new UnauthorizedError('Missing webhook signature');
    const expected = crypto.createHmac('sha256', secret).update(rawBody).digest('hex');
    if (!safeEqual(signature, expected)) throw new UnauthorizedError('Invalid webhook signature');

    let event;
    try {
        event = JSON.parse(rawBody);
    } catch {
        throw new ValidationError('Webhook body is not valid JSON');
    }
    const paymentStatus = {
        'payment.captured': 'succeeded',
        'order.paid': 'succeeded',
        'payment.failed': 'failed',
        'payment.authorized': 'authorized',
    }[event.event];
    if (paymentStatus) {
        const payment = event.payload?.payment?.entity;
        const order = event.payload?.order?.entity;
        const providerRef = payment?.order_id || order?.id || null;
        return {
            ignored: false,
            kind: 'payment',
            eventName: event.event,
            providerRef,
            paymentId: payment?.id || null,
            amountPaise: payment?.amount ?? null,
            paymentMethod: payment?.method || 'upi',
            status: paymentStatus,
            failureReason: payment?.error_description || payment?.error_code || null,
        };
    }
    const refundStatus = {
        'refund.processed': 'refund_processed',
        'refund.failed': 'refund_failed',
    }[event.event];
    if (refundStatus) {
        const refund = event.payload?.refund?.entity;
        if (!refund?.id || !refund?.payment_id) {
            throw new ValidationError('Refund webhook is missing the refund id');
        }
        return {
            ignored: false,
            kind: 'refund',
            eventName: event.event,
            refundId: refund.id,
            paymentId: refund.payment_id,
            amountPaise: refund.amount ?? null,
            status: refundStatus,
        };
    }
    return { ignored: true, eventName: event.event || 'unknown' };
}

async function fetchPayment(paymentId) {
    return razorpayRequest('GET', `/payments/${encodeURIComponent(paymentId)}`, null, { read: true });
}

async function fetchOrder(orderId) {
    return razorpayRequest('GET', `/orders/${encodeURIComponent(orderId)}`, null, { read: true });
}

async function listOrderPayments(orderId) {
    return razorpayRequest('GET', `/orders/${encodeURIComponent(orderId)}/payments`, null, { read: true });
}

async function findOrderByReceipt(receipt) {
    try {
        const data = await razorpayRequest(
            'GET',
            `/orders?receipt=${encodeURIComponent(receipt)}&count=10`,
            null,
            { read: true }
        );
        const items = Array.isArray(data?.items) ? data.items : [];
        return items.find((item) => item.receipt === receipt) || null;
    } catch (error) {
        if (error.code === 'RAZORPAY_ERROR') return null;
        throw error;
    }
}

async function fetchRefund(refundId) {
    return razorpayRequest('GET', `/refunds/${encodeURIComponent(refundId)}`, null, { read: true });
}

async function createRefund(paymentId, amountPaise, { reason } = {}) {
    try {
        return await razorpayRequest('POST', `/payments/${encodeURIComponent(paymentId)}/refund`, {
            amount: amountPaise,
            notes: { reason: String(reason || 'refund').slice(0, 255) },
        });
    } catch (error) {
        const message = String(error.message || '').toLowerCase();
        if (message.includes('fully refunded') || message.includes('already been refunded')) {
            throw new AppError('This payment has already been refunded', 409, 'REFUND_ALREADY_ISSUED');
        }
        throw error;
    }
}

function summarizePayments(payments) {
    const list = Array.isArray(payments) ? payments : payments?.items || [];
    const captured = list.find((item) => item && item.status === 'captured');
    if (captured) return { outcome: 'captured', payment: captured };
    const authorized = list.find((item) => item && item.status === 'authorized');
    if (authorized) return { outcome: 'authorized', payment: authorized };
    const failed = list.filter((item) => item && item.status === 'failed');
    if (list.length > 0 && failed.length === list.length) {
        return { outcome: 'failed', payment: failed[failed.length - 1] };
    }
    return { outcome: 'none', payment: null };
}

async function fetchStatus(ref) {
    if (String(ref).startsWith('pay_')) {
        const payment = await fetchPayment(ref);
        return { status: payment.status === 'captured' ? 'succeeded' : payment.status, providerRef: payment.order_id };
    }
    const order = await fetchOrder(ref);
    return { status: order.status, providerRef: order.id };
}

module.exports = {
    name: 'razorpay',
    createIntent,
    verifyWebhook,
    verifyCheckoutSignature,
    fetchPayment,
    fetchOrder,
    listOrderPayments,
    findOrderByReceipt,
    fetchRefund,
    createRefund,
    summarizePayments,
    fetchStatus,
};
