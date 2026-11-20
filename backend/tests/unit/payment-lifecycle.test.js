jest.mock('../../src/config/database', () => require('../helpers/payment-memory').prisma);
jest.mock('../../src/services/notification-events', () => ({ emitOrderEvent: jest.fn(() => Promise.resolve()) }));
jest.mock('../../src/services/cloudinary-upload.service', () => ({ uploadBuffer: jest.fn() }));
jest.mock('../../src/services/payments/razorpay.provider', () => {
    const actual = jest.requireActual('../../src/services/payments/razorpay.provider');
    return {
        name: 'razorpay',
        createIntent: jest.fn(),
        verifyWebhook: jest.fn(),
        verifyCheckoutSignature: jest.fn(),
        fetchPayment: jest.fn(),
        fetchRefund: jest.fn(),
        listOrderPayments: jest.fn(),
        findOrderByReceipt: jest.fn(),
        createRefund: jest.fn(),
        summarizePayments: actual.summarizePayments,
    };
});

const { AppError, UnauthorizedError } = require('../../src/utils/errors');
const { memory, reset } = require('../helpers/payment-memory');
const provider = require('../../src/services/payments/razorpay.provider');
const checkout = require('../../src/services/payments/checkout.service');
const { emitOrderEvent } = require('../../src/services/notification-events');

const ORDER = 'order-1';
const CUSTOMER = 'cust-1';
const BILL = 'bill-1';

function seed() {
    reset();
    memory.bills.push({
        bill_id: BILL,
        order_id: ORDER,
        payment_status: 'pending',
        payment_method: null,
        final_amount: '100.00',
        subtotal: '100.00',
        delivery_fee: '0.00',
        express_fee: '0.00',
        discount: '0.00',
        tax_amount: '0.00',
        coupon_code: null,
        transaction_id: null,
        paid_at: null,
    });
    memory.orders.push({ order_id: ORDER, customer_id: CUSTOMER, order_status: 'picked_up' });
}

function addAttempt(overrides = {}) {
    const row = {
        attempt_id: memory.seq++,
        order_id: ORDER,
        bill_id: BILL,
        provider: 'razorpay',
        provider_ref: 'order_rzp_1',
        razorpay_payment_id: null,
        idempotency_key: `key-${memory.seq}`,
        amount: '100.00',
        status: 'pending',
        intent_payload: { keyId: 'rzp_test', razorpayOrderId: 'order_rzp_1', amount: 10000, currency: 'INR' },
        failure_reason: null,
        last_checked_at: null,
        check_count: 0,
        reconciliation_status: null,
        created_at: new Date(),
        updated_at: new Date(),
        ...overrides,
    };
    memory.attempts.push(row);
    return row;
}

function confirm() {
    return checkout.confirmRazorpayPayment({
        customerId: CUSTOMER,
        orderId: ORDER,
        razorpayOrderId: 'order_rzp_1',
        razorpayPaymentId: 'pay_1',
        razorpaySignature: 'signed',
    });
}

function webhook({ status = 'succeeded', eventId = 'evt_1', paymentId = 'pay_1', amountPaise = 10000 } = {}) {
    provider.verifyWebhook.mockReturnValue({
        ignored: false,
        kind: 'payment',
        eventName: status === 'failed' ? 'payment.failed' : 'payment.captured',
        providerRef: 'order_rzp_1',
        paymentId,
        amountPaise,
        paymentMethod: 'upi',
        status,
        failureReason: status === 'failed' ? 'declined' : null,
    });
    return checkout.applyWebhook({
        providerName: 'razorpay',
        headers: { 'x-razorpay-signature': 'ok', 'x-razorpay-event-id': eventId },
        rawBody: JSON.stringify({ eventId, paymentId, status }),
    });
}

describe('payment lifecycle', () => {
    beforeEach(() => {
        seed();
        jest.clearAllMocks();
        provider.createIntent.mockReset();
        provider.verifyWebhook.mockReset();
        provider.verifyCheckoutSignature.mockReset();
        provider.fetchPayment.mockReset();
        provider.fetchRefund.mockReset();
        provider.listOrderPayments.mockReset();
        provider.findOrderByReceipt.mockReset();
        provider.createRefund.mockReset();
        provider.verifyCheckoutSignature.mockImplementation(() => {});
        provider.listOrderPayments.mockResolvedValue({ items: [] });
        provider.findOrderByReceipt.mockResolvedValue(null);
    });

    it('settles a captured payment and ignores the client amount', async () => {
        addAttempt();
        provider.fetchPayment.mockResolvedValue({
            id: 'pay_1',
            order_id: 'order_rzp_1',
            amount: 10000,
            status: 'captured',
            method: 'upi',
        });
        const result = await confirm();
        expect(result.paymentStatus).toBe('completed');
        expect(result.transactionId).toBe('pay_1');
        expect(result.verificationState).toBe('paid');
        expect(emitOrderEvent).toHaveBeenCalledTimes(1);
        expect(emitOrderEvent).toHaveBeenCalledWith('payment_received', { orderId: ORDER });
    });

    it('rejects an invalid checkout signature', async () => {
        addAttempt();
        provider.verifyCheckoutSignature.mockImplementation(() => {
            throw new UnauthorizedError('Invalid Razorpay payment signature');
        });
        await expect(confirm()).rejects.toThrow('Invalid Razorpay payment signature');
        expect(memory.bills[0].payment_status).toBe('pending');
    });

    it('rejects a captured payment whose amount does not match the bill', async () => {
        addAttempt();
        provider.fetchPayment.mockResolvedValue({
            id: 'pay_1',
            order_id: 'order_rzp_1',
            amount: 5000,
            status: 'captured',
            method: 'upi',
        });
        await expect(confirm()).rejects.toThrow('Payment amount does not match the bill');
        expect(memory.bills[0].payment_status).toBe('pending');
    });

    it('records a failed payment without marking the bill paid', async () => {
        addAttempt();
        const result = await webhook({ status: 'failed', eventId: 'evt_fail' });
        expect(result.status).toBe('failed');
        expect(memory.attempts[0].status).toBe('failed');
        expect(memory.bills[0].payment_status).toBe('pending');
        expect(emitOrderEvent).toHaveBeenCalledWith('payment_failed', { orderId: ORDER });
    });

    it('cancels checkout only after the gateway shows no captured payment', async () => {
        addAttempt();
        provider.listOrderPayments.mockResolvedValue({ items: [] });
        const result = await checkout.cancelCheckout({ customerId: CUSTOMER, orderId: ORDER });
        expect(result.attempt.status).toBe('cancelled');
        expect(result.verificationState).toBe('cancelled');
        expect(memory.bills[0].payment_status).toBe('pending');
    });

    it('settles a captured webhook when the app never calls confirm', async () => {
        addAttempt();
        const result = await webhook({ eventId: 'evt_capture' });
        expect(result.completed).toBe(true);
        expect(memory.bills[0].payment_status).toBe('completed');
        expect(memory.bills[0].transaction_id).toBe('pay_1');
    });

    it('settles one successful confirmation when confirm is repeated', async () => {
        addAttempt();
        provider.fetchPayment.mockResolvedValue({
            id: 'pay_1',
            order_id: 'order_rzp_1',
            amount: 10000,
            status: 'captured',
            method: 'upi',
        });
        await confirm();
        const second = await confirm();
        expect(second.paymentStatus).toBe('completed');
        expect(emitOrderEvent).toHaveBeenCalledTimes(1);
    });

    it('acknowledges a duplicate webhook without settling twice', async () => {
        addAttempt();
        await webhook({ eventId: 'evt_same' });
        const duplicate = await webhook({ eventId: 'evt_same' });
        expect(duplicate.duplicate).toBe(true);
        expect(memory.events).toHaveLength(1);
        expect(memory.events[0].status).toBe('processed');
        expect(emitOrderEvent).toHaveBeenCalledTimes(1);
    });

    it('lets a webhook and a confirm race settle the bill once', async () => {
        addAttempt();
        provider.fetchPayment.mockResolvedValue({
            id: 'pay_1',
            order_id: 'order_rzp_1',
            amount: 10000,
            status: 'captured',
            method: 'upi',
        });
        await Promise.all([confirm(), webhook({ eventId: 'evt_race' })]);
        expect(memory.bills[0].payment_status).toBe('completed');
        expect(memory.bills[0].transaction_id).toBe('pay_1');
        expect(emitOrderEvent).toHaveBeenCalledTimes(1);
    });

    it('keeps an uncertain order create instead of marking it failed or creating another order', async () => {
        provider.createIntent.mockRejectedValue(new AppError('Razorpay did not respond in time', 503, 'PAYMENT_OUTCOME_UNKNOWN'));
        await expect(checkout.createPayIntent({ customerId: CUSTOMER, orderId: ORDER })).rejects.toMatchObject({
            code: 'PAYMENT_OUTCOME_UNKNOWN',
        });
        expect(memory.attempts).toHaveLength(1);
        expect(memory.attempts[0].status).toBe('uncertain');
        const second = await checkout.createPayIntent({ customerId: CUSTOMER, orderId: ORDER });
        expect(second.verificationState).toBe('unknown');
        expect(provider.createIntent).toHaveBeenCalledTimes(1);
        expect(memory.bills[0].payment_status).toBe('pending');
    });

    it('records cash after the gateway confirms the online attempt failed', async () => {
        addAttempt({ status: 'failed' });
        memory.orders[0].order_status = 'out_for_delivery';
        memory.deliveries.push({ order_id: ORDER, delivery_type: 'drop', staff_id: 'staff-1' });
        provider.listOrderPayments.mockResolvedValue({
            items: [{ id: 'pay_1', order_id: 'order_rzp_1', status: 'failed', amount: 10000 }],
        });
        const result = await checkout.recordCash({ staffId: 'staff-1', orderId: ORDER });
        expect(result.paymentMethod).toBe('cash');
        expect(memory.bills[0].payment_method).toBe('cash');
        expect(memory.bills[0].payment_status).toBe('completed');
    });

    it('blocks cash and keeps the attempt for review when the gateway cannot be checked', async () => {
        addAttempt({ status: 'failed' });
        memory.orders[0].order_status = 'out_for_delivery';
        memory.deliveries.push({ order_id: ORDER, delivery_type: 'drop', staff_id: 'staff-1' });
        provider.listOrderPayments.mockRejectedValue(new AppError('Razorpay did not respond in time', 503, 'PAYMENT_OUTCOME_UNKNOWN'));
        await expect(checkout.recordCash({ staffId: 'staff-1', orderId: ORDER })).rejects.toMatchObject({
            code: 'PAYMENT_OUTCOME_UNKNOWN',
        });
        expect(memory.bills[0].payment_status).toBe('pending');
        expect(memory.attempts[0].status).toBe('uncertain');
        expect(memory.attempts[0].reconciliation_status).toBe('needs_review');
    });

    it('refunds a late capture after cash and does not replace the cash payment', async () => {
        addAttempt();
        memory.bills[0].payment_status = 'completed';
        memory.bills[0].payment_method = 'cash';
        provider.createRefund.mockResolvedValue({ id: 'rfnd_1', status: 'processed' });
        const result = await webhook({ eventId: 'evt_late', paymentId: 'pay_late' });
        expect(result.refundRequired).toBe(true);
        expect(memory.bills[0].payment_method).toBe('cash');
        expect(memory.bills[0].transaction_id).toBeNull();
        expect(provider.createRefund).toHaveBeenCalledTimes(1);
        expect(memory.refunds[0].razorpay_refund_id).toBe('rfnd_1');
        expect(memory.refunds[0].status).toBe('processed');
    });

    it('does not create a second refund for the same captured payment', async () => {
        addAttempt();
        memory.bills[0].payment_status = 'completed';
        memory.bills[0].payment_method = 'cash';
        provider.createRefund.mockResolvedValue({ id: 'rfnd_1', status: 'processed' });
        await webhook({ eventId: 'evt_late_1', paymentId: 'pay_late' });
        await webhook({ eventId: 'evt_late_2', paymentId: 'pay_late' });
        expect(provider.createRefund).toHaveBeenCalledTimes(1);
        expect(memory.refunds).toHaveLength(1);
    });

    it('does not complete the bill when an authorized webhook arrives', async () => {
        addAttempt();
        provider.verifyWebhook.mockReturnValue({
            ignored: false,
            kind: 'payment',
            eventName: 'payment.authorized',
            providerRef: 'order_rzp_1',
            paymentId: 'pay_1',
            amountPaise: 10000,
            paymentMethod: 'upi',
            status: 'authorized',
            failureReason: null,
        });
        const result = await checkout.applyWebhook({
            providerName: 'razorpay',
            headers: { 'x-razorpay-signature': 'ok', 'x-razorpay-event-id': 'evt_auth' },
            rawBody: '{"authorized":true}',
        });
        expect(result.awaitingCapture).toBe(true);
        expect(memory.bills[0].payment_status).toBe('pending');
        expect(memory.attempts[0].reconciliation_status).toBe('awaiting_capture');
    });

    it('does not complete the bill when Razorpay has only authorized the payment', async () => {
        addAttempt();
        provider.fetchPayment.mockResolvedValue({
            id: 'pay_1',
            order_id: 'order_rzp_1',
            amount: 10000,
            status: 'authorized',
            method: 'upi',
        });
        await expect(confirm()).rejects.toMatchObject({ code: 'PAYMENT_AWAITING_CAPTURE' });
        expect(memory.bills[0].payment_status).toBe('pending');
        expect(memory.attempts[0].reconciliation_status).toBe('awaiting_capture');
    });

    it('marks a refund processed from a refund webhook without refunding again', async () => {
        const attempt = addAttempt({ status: 'succeeded', razorpay_payment_id: 'pay_late' });
        memory.refunds.push({
            id: 'refund-existing',
            attempt_id: attempt.attempt_id,
            bill_id: BILL,
            razorpay_payment_id: 'pay_late',
            razorpay_refund_id: null,
            amount: '100.00',
            status: 'pending',
            reason: 'late',
            idempotency_key: 'refund:pay_late',
            created_by: 'system',
            created_at: new Date(),
            updated_at: new Date(),
        });
        provider.verifyWebhook.mockReturnValue({
            ignored: false,
            kind: 'refund',
            eventName: 'refund.processed',
            refundId: 'rfnd_1',
            paymentId: 'pay_late',
            amountPaise: 10000,
            status: 'refund_processed',
        });
        const result = await checkout.applyWebhook({
            providerName: 'razorpay',
            headers: { 'x-razorpay-signature': 'ok', 'x-razorpay-event-id': 'evt_refund' },
            rawBody: '{"refund":true}',
        });
        expect(result.status).toBe('processed');
        expect(memory.refunds[0].razorpay_refund_id).toBe('rfnd_1');
        expect(provider.createRefund).not.toHaveBeenCalled();
    });

    it('reconciles a pending attempt after the process starts again', async () => {
        addAttempt();
        provider.listOrderPayments.mockResolvedValue({
            items: [{ id: 'pay_1', order_id: 'order_rzp_1', amount: 10000, status: 'captured', method: 'upi' }],
        });
        await checkout.reconcilePendingPayments();
        expect(memory.bills[0].payment_status).toBe('completed');
        expect(memory.bills[0].transaction_id).toBe('pay_1');
        expect(provider.createIntent).not.toHaveBeenCalled();
        expect(provider.createRefund).not.toHaveBeenCalled();
    });
});
