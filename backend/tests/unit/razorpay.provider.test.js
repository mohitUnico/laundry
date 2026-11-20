const crypto = require('crypto');

describe('razorpay provider signatures', () => {
    const previous = {};

    beforeAll(() => {
        previous.keyId = process.env.RAZORPAY_KEY_ID;
        previous.keySecret = process.env.RAZORPAY_KEY_SECRET;
        previous.webhookSecret = process.env.RAZORPAY_WEBHOOK_SECRET;
        process.env.RAZORPAY_KEY_ID = 'rzp_test_dummy';
        process.env.RAZORPAY_KEY_SECRET = 'test_secret';
        process.env.RAZORPAY_WEBHOOK_SECRET = 'whsec_test';
        jest.resetModules();
    });

    afterAll(() => {
        process.env.RAZORPAY_KEY_ID = previous.keyId;
        process.env.RAZORPAY_KEY_SECRET = previous.keySecret;
        process.env.RAZORPAY_WEBHOOK_SECRET = previous.webhookSecret;
    });

    function provider() {
        return require('../../src/services/payments/razorpay.provider');
    }

    it('accepts a checkout signature signed with the key secret', () => {
        const razorpayOrderId = 'order_123';
        const razorpayPaymentId = 'pay_456';
        const razorpaySignature = crypto
            .createHmac('sha256', 'test_secret')
            .update(`${razorpayOrderId}|${razorpayPaymentId}`)
            .digest('hex');

        expect(() =>
            provider().verifyCheckoutSignature({ razorpayOrderId, razorpayPaymentId, razorpaySignature })
        ).not.toThrow();
    });

    it('rejects a checkout signature signed with the wrong secret', () => {
        const razorpaySignature = crypto.createHmac('sha256', 'other').update('order_123|pay_456').digest('hex');
        expect(() =>
            provider().verifyCheckoutSignature({
                razorpayOrderId: 'order_123',
                razorpayPaymentId: 'pay_456',
                razorpaySignature,
            })
        ).toThrow('Invalid Razorpay payment signature');
    });

    it('maps a signed payment.captured webhook onto the shared success payload', () => {
        const body = JSON.stringify({
            event: 'payment.captured',
            payload: {
                payment: {
                    entity: {
                        id: 'pay_1',
                        order_id: 'order_1',
                        amount: 10000,
                        status: 'captured',
                        method: 'upi',
                    },
                },
            },
        });
        const signature = crypto.createHmac('sha256', 'whsec_test').update(body).digest('hex');
        const parsed = provider().verifyWebhook({ 'x-razorpay-signature': signature }, body);
        expect(parsed).toMatchObject({
            providerRef: 'order_1',
            paymentId: 'pay_1',
            amountPaise: 10000,
            status: 'succeeded',
        });
    });

    it('rejects a webhook with a bad signature', () => {
        expect(() => provider().verifyWebhook({ 'x-razorpay-signature': 'deadbeef' }, '{}')).toThrow(
            'Invalid webhook signature'
        );
    });

    it('does not treat an authorized payment as captured', () => {
        const body = JSON.stringify({
            event: 'payment.authorized',
            payload: { payment: { entity: { id: 'pay_1', order_id: 'order_1', amount: 10000, status: 'authorized' } } },
        });
        const signature = crypto.createHmac('sha256', 'whsec_test').update(body).digest('hex');
        const parsed = provider().verifyWebhook({ 'x-razorpay-signature': signature }, body);
        expect(parsed.status).toBe('authorized');
        expect(parsed.status).not.toBe('succeeded');
    });

    it('maps a refund.processed webhook', () => {
        const body = JSON.stringify({
            event: 'refund.processed',
            payload: { refund: { entity: { id: 'rfnd_1', payment_id: 'pay_1', amount: 10000, status: 'processed' } } },
        });
        const signature = crypto.createHmac('sha256', 'whsec_test').update(body).digest('hex');
        const parsed = provider().verifyWebhook({ 'x-razorpay-signature': signature }, body);
        expect(parsed).toMatchObject({ kind: 'refund', status: 'refund_processed', refundId: 'rfnd_1', paymentId: 'pay_1' });
    });

    it('keeps an authorized payment out of the captured outcome', () => {
        expect(provider().summarizePayments([{ id: 'pay_auth', status: 'authorized' }]).outcome).toBe('authorized');
        expect(provider().summarizePayments([{ id: 'pay_cap', status: 'captured' }]).outcome).toBe('captured');
    });

    it('retries a timed-out read and does not retry order creation', async () => {
        const original = global.fetch;
        let reads = 0;
        global.fetch = jest.fn(async (_url, options = {}) => {
            if (options.method === 'POST') {
                const error = new Error('aborted');
                error.name = 'AbortError';
                throw error;
            }
            reads += 1;
            if (reads < 3) {
                const error = new Error('aborted');
                error.name = 'AbortError';
                throw error;
            }
            return {
                ok: true,
                status: 200,
                json: async () => ({ id: 'pay_1', status: 'captured', amount: 10000, order_id: 'order_1' }),
            };
        });
        try {
            await expect(provider().createIntent({ amount: '10.00', orderId: 'order-1', attemptId: 7 })).rejects.toMatchObject({
                code: 'PAYMENT_OUTCOME_UNKNOWN',
            });
            expect(global.fetch).toHaveBeenCalledTimes(1);
            const payment = await provider().fetchPayment('pay_1');
            expect(payment.status).toBe('captured');
            expect(reads).toBe(3);
        } finally {
            global.fetch = original;
        }
    });
});
