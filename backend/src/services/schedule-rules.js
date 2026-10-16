const { ValidationError } = require('../utils/errors');
const configService = require('./config.service');

const IST = 'Asia/Kolkata';
const PAST_GRACE_MS = 2 * 60 * 1000;

function calendarDateIST(date) {
    const fmt = new Intl.DateTimeFormat('en-CA', {
        timeZone: IST,
        year: 'numeric',
        month: '2-digit',
        day: '2-digit',
    });
    return fmt.format(date);
}

function addDaysYmd(ymd, days) {
    const [y, m, d] = ymd.split('-').map(Number);
    const utc = new Date(Date.UTC(y, m - 1, d + days));
    const yyyy = utc.getUTCFullYear();
    const mm = String(utc.getUTCMonth() + 1).padStart(2, '0');
    const dd = String(utc.getUTCDate()).padStart(2, '0');
    return `${yyyy}-${mm}-${dd}`;
}

function parseDate(value, field) {
    if (!value) return null;
    const date = value instanceof Date ? value : new Date(value);
    if (Number.isNaN(date.getTime())) {
        throw new ValidationError(`${field} is not a valid date`);
    }
    return date;
}

/**
 * Validate and normalise pickup/delivery modes and windows.
 *
 * Instant delivery is treated as "as soon as allowed": its calendar date is
 * pickupDate + buffer (not "today"), so ordinary instant+instant is legal.
 * Express skips the buffer and forbids any time fields.
 */
async function validateSchedule(input, { now = new Date() } = {}) {
    const isExpress = Boolean(input.is_express);
    const forbiddenLegacy = ['order_type', 'pickup_date', 'delivery_date'];
    for (const key of forbiddenLegacy) {
        if (input[key] !== undefined) {
            throw new ValidationError(`${key} is not accepted on v2 orders`);
        }
    }

    if (isExpress) {
        const timeFields = [
            'pickup_time_from',
            'pickup_time_to',
            'delivery_time_from',
            'delivery_time_to',
        ];
        const sent = timeFields.filter((k) => input[k] != null && input[k] !== '');
        if (sent.length > 0) {
            throw new ValidationError('Express orders cannot include schedule times');
        }
        return {
            is_express: true,
            pickup_mode: 'instant',
            delivery_mode: 'instant',
            pickup_time_from: null,
            pickup_time_to: null,
            delivery_time_from: null,
            delivery_time_to: null,
        };
    }

    const pickup_mode = input.pickup_mode || 'instant';
    const delivery_mode = input.delivery_mode || 'instant';
    if (!['instant', 'scheduled'].includes(pickup_mode)) {
        throw new ValidationError('pickup_mode must be instant or scheduled');
    }
    if (!['instant', 'scheduled'].includes(delivery_mode)) {
        throw new ValidationError('delivery_mode must be instant or scheduled');
    }

    const pickup_time_from = parseDate(input.pickup_time_from, 'pickup_time_from');
    const pickup_time_to = parseDate(input.pickup_time_to, 'pickup_time_to');
    const delivery_time_from = parseDate(input.delivery_time_from, 'delivery_time_from');
    const delivery_time_to = parseDate(input.delivery_time_to, 'delivery_time_to');

    const checkWindow = (mode, from, to, prefix) => {
        if (mode === 'scheduled') {
            if (!from) throw new ValidationError(`${prefix}_time_from is required when ${prefix}_mode is scheduled`);
            if (to && to < from) {
                throw new ValidationError(`${prefix}_time_to must be on or after ${prefix}_time_from`);
            }
            if (from.getTime() < now.getTime() - PAST_GRACE_MS) {
                throw new ValidationError(`${prefix}_time_from is in the past`);
            }
        }
    };
    checkWindow(pickup_mode, pickup_time_from, pickup_time_to, 'pickup');
    checkWindow(delivery_mode, delivery_time_from, delivery_time_to, 'delivery');

    const bufferDays = await configService.getInt('PICKUP_DELIVERY_BUFFER_DAYS');
    const today = calendarDateIST(now);
    const pickupDate = pickup_mode === 'scheduled' ? calendarDateIST(pickup_time_from) : today;
    const earliestDelivery = addDaysYmd(pickupDate, bufferDays);
    const deliveryDate =
        delivery_mode === 'scheduled' ? calendarDateIST(delivery_time_from) : earliestDelivery;

    if (deliveryDate < earliestDelivery) {
        throw new ValidationError(
            `Delivery date must be on or after pickup date + ${bufferDays} day(s)`
        );
    }

    return {
        is_express: false,
        pickup_mode,
        delivery_mode,
        pickup_time_from: pickup_mode === 'scheduled' ? pickup_time_from : null,
        pickup_time_to: pickup_mode === 'scheduled' ? pickup_time_to : null,
        delivery_time_from: delivery_mode === 'scheduled' ? delivery_time_from : null,
        delivery_time_to: delivery_mode === 'scheduled' ? delivery_time_to : null,
    };
}

module.exports = {
    IST,
    calendarDateIST,
    addDaysYmd,
    validateSchedule,
};
