const { addDaysYmd, calendarDateIST } = require('../../src/services/schedule-rules');

describe('schedule-rules helpers', () => {
    it('adds calendar days across month boundaries', () => {
        expect(addDaysYmd('2026-01-30', 2)).toBe('2026-02-01');
        expect(addDaysYmd('2026-10-16', 0)).toBe('2026-10-16');
    });

    it('formats an IST calendar date', () => {
        const lateUtc = new Date('2026-10-16T20:30:00.000Z'); // 02:00 IST on the 17th
        expect(calendarDateIST(lateUtc)).toBe('2026-10-17');
    });
});
