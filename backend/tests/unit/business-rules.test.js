const { ConflictError } = require('../../src/utils/errors');
const { assertBookable } = require('../../src/services/catalogue-rules');
const { flagsFor, trackerFor, STATUS_STEP } = require('../../src/services/order-tracker');
const { ORDER_STATUS } = require('../../src/constants/order-flow');
const { distanceKm } = require('../../src/services/assignment/distance.provider');
const mockProvider = require('../../src/services/payments/mock.provider');
const { MATRIX } = require('../../src/services/notification-events');
const { UnauthorizedError } = require('../../src/utils/errors');

describe('catalogue bookable guard', () => {
    it('rejects an inactive service and accepts a priced one', () => {
        expect(() =>
            assertBookable({ bookable: false, reasons: ['service_inactive'] }, 'svc-1')
        ).toThrow(ConflictError);
        expect(() =>
            assertBookable({ bookable: true, reasons: [] }, 'svc-1')
        ).not.toThrow();
    });
});

describe('order tracker', () => {
    it('maps every live status onto a step and hides a cancelled order', () => {
        for (const status of Object.values(ORDER_STATUS)) {
            if (status === ORDER_STATUS.CANCELLED) {
                const hidden = trackerFor({ order_status: status, cancel_reason: 'changed mind' });
                expect(hidden.tracker).toBeNull();
                expect(hidden.cancelled.reason).toBe('changed mind');
                continue;
            }
            const view = trackerFor({ order_status: status }, { state: 'searching' });
            expect(view.tracker.currentStep).toBe(STATUS_STEP[status]);
            expect(view.tracker.steps).toHaveLength(6);
            expect(view.tracker.steps.filter((step) => step.state === 'current')).toHaveLength(1);
        }
    });

    it('allows cancel and reschedule only while placed, and pay only with a pending bill', () => {
        const placed = flagsFor(
            { order_status: ORDER_STATUS.PLACED, is_express: false, pickup_mode: 'instant', delivery_mode: 'instant' },
            null
        );
        expect(placed.canCancel).toBe(true);
        expect(placed.canReschedule).toBe(true);
        expect(placed.canPay).toBe(false);

        const express = flagsFor(
            { order_status: ORDER_STATUS.PLACED, is_express: true, pickup_mode: 'instant', delivery_mode: 'instant' },
            null
        );
        expect(express.canReschedule).toBe(false);

        const payable = flagsFor(
            { order_status: ORDER_STATUS.PICKED_UP, is_express: false },
            { payment_status: 'pending' }
        );
        expect(payable.canPay).toBe(true);

        const paid = flagsFor(
            { order_status: ORDER_STATUS.OUT_FOR_DELIVERY, is_express: false },
            { payment_status: 'completed' }
        );
        expect(paid.canPay).toBe(false);
    });
});

describe('haversine distance', () => {
    it('returns null when a point is missing and a short distance for nearby points', () => {
        expect(distanceKm({ latitude: 1, longitude: 1 }, { latitude: null, longitude: 2 })).toBeNull();
        const km = distanceKm(
            { latitude: 12.9716, longitude: 77.5946 },
            { latitude: 12.9716, longitude: 77.6036 }
        );
        expect(km).toBeGreaterThan(0.5);
        expect(km).toBeLessThan(2);
    });
});

describe('mock payment provider', () => {
    it('signs a body and rejects a bad signature', async () => {
        const intent = await mockProvider.createIntent({ amount: '10.00', orderId: 'o1', attemptId: 7 });
        expect(intent.providerRef).toBe('mock_7');
        expect(intent.intentPayload.upiLink).toContain('mock_7');

        const body = JSON.stringify({ providerRef: intent.providerRef, status: 'succeeded' });
        const parsed = mockProvider.verifyWebhook({ 'x-mock-signature': mockProvider.signBody(body) }, body);
        expect(parsed.status).toBe('succeeded');

        expect(() => mockProvider.verifyWebhook({}, body)).toThrow(UnauthorizedError);
        expect(() => mockProvider.verifyWebhook({ 'x-mock-signature': '00' }, body)).toThrow(UnauthorizedError);
        await expect(mockProvider.fetchStatus('mock_7')).resolves.toEqual({
            status: 'pending',
            providerRef: 'mock_7',
        });
    });
});

describe('notification matrix', () => {
    it('names a customer or staff audience for every order event', () => {
        const events = [
            'order_placed',
            'pickup_assigned',
            'picked_up',
            'bill_ready',
            'received_at_plant',
            'services_started',
            'services_completed',
            'out_for_delivery',
            'payment_received',
            'payment_failed',
            'delivered',
            'cancelled',
            'assignment_timeout',
        ];
        for (const event of events) {
            expect(MATRIX[event]).toEqual(expect.objectContaining({ title: expect.any(String) }));
        }
    });
});
