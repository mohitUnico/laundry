const configService = require('./config.service');

const PERIODS = [
    { period: 'morning', from: 8, to: 12 },
    { period: 'afternoon', from: 12, to: 17 },
    { period: 'evening', from: 17, to: 21 },
];

function pad(value) {
    return String(value).padStart(2, '0');
}

function slotId(index) {
    return `66666666-6666-4666-8666-${String(index).padStart(12, '0')}`;
}

function buildSlots() {
    const slots = [];
    let index = 1;
    for (const band of PERIODS) {
        for (let hour = band.from; hour < band.to; hour += 1) {
            for (const minute of [0, 30]) {
                const endHour = minute === 30 ? hour + 1 : hour;
                const endMinute = minute === 30 ? 0 : 30;
                if (endHour > band.to || (endHour === band.to && endMinute > 0)) continue;
                slots.push({
                    slot_id: slotId(index),
                    label: `${pad(hour)}:${pad(minute)}-${pad(endHour)}:${pad(endMinute)}`,
                    period: band.period,
                    start_time: `${pad(hour)}:${pad(minute)}`,
                    end_time: `${pad(endHour)}:${pad(endMinute)}`,
                    status: 'open',
                    sort_order: index,
                });
                index += 1;
            }
        }
    }
    return slots;
}

const SLOTS = buildSlots();

async function listSlots() {
    const horizon = await configService.getInt('BOOKING_HORIZON_DAYS');
    return {
        server_time: new Date().toISOString(),
        timezone: 'Asia/Kolkata',
        booking_horizon_days: horizon,
        slots: SLOTS,
    };
}

module.exports = { listSlots, SLOTS };
