const {
    ORDER_STATUS,
    LIVE_STATUSES,
    TRANSITIONS,
    isAllowedTransition,
    assertTransition,
} = require('../../src/constants/order-flow');
const { ConflictError } = require('../../src/utils/errors');

describe('order-flow transition table (diagram 5.1)', () => {
    const removed = ['draft', 'dispatch_assigned', 'closed', 'payment_pending'];

    it('lists exactly the 11 live statuses', () => {
        expect(LIVE_STATUSES).toHaveLength(11);
        expect(new Set(LIVE_STATUSES).size).toBe(11);
    });

    it('allows every transition drawn on the state diagram', () => {
        const expected = [
            ['placed', 'cancelled'],
            ['placed', 'placed'],
            ['placed', 'pickup_assigned'],
            ['pickup_assigned', 'picked_up'],
            ['picked_up', 'submitted_to_cm'],
            ['submitted_to_cm', 'received_by_collection'],
            ['received_by_collection', 'submitted_to_services'],
            ['submitted_to_services', 'services_in_progress'],
            ['services_in_progress', 'services_in_progress'],
            ['services_in_progress', 'services_completed'],
            ['services_completed', 'out_for_delivery'],
            ['out_for_delivery', 'delivered'],
        ];
        for (const [from, to] of expected) {
            expect(isAllowedTransition(from, to)).toBe(true);
            expect(() => assertTransition(from, to)).not.toThrow();
        }
    });

    it('rejects every other pair of live statuses', () => {
        const allowed = new Set();
        for (const [from, tos] of Object.entries(TRANSITIONS)) {
            for (const to of tos) allowed.add(`${from}->${to}`);
        }
        for (const from of LIVE_STATUSES) {
            for (const to of LIVE_STATUSES) {
                const key = `${from}->${to}`;
                if (allowed.has(key)) continue;
                expect(isAllowedTransition(from, to)).toBe(false);
                expect(() => assertTransition(from, to)).toThrow(ConflictError);
                try {
                    assertTransition(from, to);
                } catch (err) {
                    expect(err.code).toBe('INVALID_STATUS_TRANSITION');
                    expect(err.statusCode).toBe(409);
                }
            }
        }
    });

    it('rejects removed statuses as from or to', () => {
        for (const dead of removed) {
            expect(LIVE_STATUSES).not.toContain(dead);
            expect(TRANSITIONS[dead]).toBeUndefined();
            for (const live of LIVE_STATUSES) {
                expect(isAllowedTransition(dead, live)).toBe(false);
                expect(isAllowedTransition(live, dead)).toBe(false);
                expect(() => assertTransition(dead, live)).toThrow(ConflictError);
                expect(() => assertTransition(live, dead)).toThrow(ConflictError);
            }
        }
    });

    it('rejects unknown status strings', () => {
        expect(() => assertTransition('placed', 'nope')).toThrow(ConflictError);
        expect(() => assertTransition('nope', 'placed')).toThrow(ConflictError);
        expect(LIVE_STATUSES).not.toEqual(expect.arrayContaining(removed));
    });

    it('exposes ORDER_STATUS values that match the live list', () => {
        expect(Object.values(ORDER_STATUS).sort()).toEqual([...LIVE_STATUSES].sort());
    });
});
