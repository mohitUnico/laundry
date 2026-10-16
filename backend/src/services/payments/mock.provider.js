const crypto = require('crypto');
const { UnauthorizedError } = require('../../utils/errors');

const secret = () => process.env.PAYMENT_WEBHOOK_SECRET || 'mock-webhook-secret';

async function createIntent({ amount, orderId, attemptId }) {
    const providerRef = `mock_${attemptId}`;
    return {
        providerRef,
        intentPayload: {
            upiLink: `upi://pay?pa=washbee@mock&am=${amount}&tn=order-${orderId}&tr=${providerRef}`,
            provider: 'mock',
        },
    };
}

function verifyWebhook(headers, rawBody) {
    const signature = headers['x-mock-signature'] || headers['X-Mock-Signature'];
    if (!signature) throw new UnauthorizedError('Missing webhook signature');
    const expected = crypto.createHmac('sha256', secret()).update(rawBody).digest('hex');
    const given = Buffer.from(String(signature));
    const wanted = Buffer.from(expected);
    if (given.length !== wanted.length || !crypto.timingSafeEqual(given, wanted)) {
        throw new UnauthorizedError('Invalid webhook signature');
    }
    return JSON.parse(rawBody);
}

function signBody(rawBody) {
    return crypto.createHmac('sha256', secret()).update(rawBody).digest('hex');
}

async function fetchStatus(ref) {
    return { status: 'pending', providerRef: ref };
}

module.exports = {
    name: 'mock',
    createIntent,
    verifyWebhook,
    fetchStatus,
    signBody,
};
