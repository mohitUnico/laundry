const memory = {
    orders: [],
    bills: [],
    attempts: [],
    events: [],
    refunds: [],
    deliveries: [],
    seq: 1,
};

function reset() {
    memory.orders = [];
    memory.bills = [];
    memory.attempts = [];
    memory.events = [];
    memory.refunds = [];
    memory.deliveries = [];
    memory.seq = 1;
}

function matches(row, where) {
    if (!where) return true;
    return Object.entries(where).every(([key, expected]) => {
        if (key === 'OR') return expected.some((branch) => matches(row, branch));
        if (key === 'AND') return expected.every((branch) => matches(row, branch));
        if (expected && typeof expected === 'object' && !(expected instanceof Date)) {
            if (Object.prototype.hasOwnProperty.call(expected, 'in')) return expected.in.includes(row[key]);
            if (Object.prototype.hasOwnProperty.call(expected, 'lt')) {
                if (row[key] == null) return false;
                if (expected.lt instanceof Date || row[key] instanceof Date) {
                    return new Date(row[key]).getTime() < new Date(expected.lt).getTime();
                }
                return row[key] < expected.lt;
            }
            return false;
        }
        return row[key] === expected;
    });
}

function sortRows(rows, orderBy) {
    if (!orderBy) return rows;
    const [key, direction] = Object.entries(orderBy)[0];
    return [...rows].sort((left, right) => {
        const a = left[key] instanceof Date ? left[key].getTime() : left[key] || 0;
        const b = right[key] instanceof Date ? right[key].getTime() : right[key] || 0;
        return direction === 'desc' ? b - a : a - b;
    });
}

function uniqueError() {
    const error = new Error('Unique constraint');
    error.code = 'P2002';
    return error;
}

function apply(row, data) {
    Object.entries(data).forEach(([key, value]) => {
        if (value && typeof value === 'object' && !Array.isArray(value) && !(value instanceof Date) && value.increment) {
            row[key] = (row[key] || 0) + value.increment;
            return;
        }
        row[key] = value;
    });
    row.updated_at = new Date();
    return row;
}

function billFor(billId) {
    return memory.bills.find((bill) => bill.bill_id === billId) || null;
}

function attach(row, include) {
    if (include?.bill && row) row.bill = billFor(row.bill_id);
    return row;
}

let transactionChain = Promise.resolve();

const prisma = {
    order: {
        async findFirst({ where, include }) {
            const row = memory.orders.find((order) => matches(order, where));
            if (!row) return null;
            if (include?.bill) return { ...row, bill: memory.bills.find((bill) => bill.order_id === row.order_id) || null };
            return row;
        },
        async findUnique({ where, include }) {
            const row = memory.orders.find((order) => order.order_id === where.order_id);
            if (!row) return null;
            if (include?.bill) return { ...row, bill: memory.bills.find((bill) => bill.order_id === row.order_id) || null };
            return row;
        },
    },
    bill: {
        async findUnique({ where }) {
            return memory.bills.find((bill) => bill.bill_id === where.bill_id) || null;
        },
        async updateMany({ where, data }) {
            const rows = memory.bills.filter((bill) => matches(bill, where));
            rows.forEach((bill) => apply(bill, data));
            return { count: rows.length };
        },
    },
    paymentAttempt: {
        async findFirst({ where, orderBy, include }) {
            const rows = sortRows(memory.attempts.filter((row) => matches(row, where)), orderBy);
            return attach(rows[0] || null, include);
        },
        async findUnique({ where }) {
            return memory.attempts.find((row) => row.attempt_id === where.attempt_id) || null;
        },
        async findMany({ where, orderBy, include, take }) {
            let rows = sortRows(memory.attempts.filter((row) => matches(row, where)), orderBy);
            if (take) rows = rows.slice(0, take);
            return rows.map((row) => attach(row, include));
        },
        async count({ where }) {
            return memory.attempts.filter((row) => matches(row, where)).length;
        },
        async create({ data }) {
            if (memory.attempts.some((row) => row.idempotency_key === data.idempotency_key)) throw uniqueError();
            const live = ['initiated', 'pending', 'uncertain'];
            if (live.includes(data.status) && memory.attempts.some((row) => row.order_id === data.order_id && live.includes(row.status))) {
                throw uniqueError();
            }
            const row = {
                attempt_id: memory.seq++,
                razorpay_payment_id: null,
                failure_reason: null,
                last_checked_at: null,
                check_count: 0,
                reconciliation_status: null,
                intent_payload: null,
                provider_ref: null,
                created_at: new Date(),
                updated_at: new Date(),
                ...data,
            };
            memory.attempts.push(row);
            return row;
        },
        async update({ where, data }) {
            const row = memory.attempts.find((item) => item.attempt_id === where.attempt_id);
            if (data.razorpay_payment_id && memory.attempts.some((item) => item !== row && item.razorpay_payment_id === data.razorpay_payment_id)) {
                throw uniqueError();
            }
            return apply(row, data);
        },
    },
    paymentWebhookEvent: {
        async findUnique({ where }) {
            return memory.events.find((row) => row.event_id === where.event_id) || null;
        },
        async findMany({ where, take }) {
            const rows = memory.events.filter((row) => matches(row, where));
            return take ? rows.slice(0, take) : rows;
        },
        async create({ data }) {
            if (memory.events.some((row) => row.event_id === data.event_id)) throw uniqueError();
            const row = { id: `event-${memory.seq++}`, error: null, processed_at: null, created_at: new Date(), ...data };
            memory.events.push(row);
            return row;
        },
        async update({ where, data }) {
            const row = memory.events.find((item) => item.id === where.id);
            return apply(row, data);
        },
    },
    paymentRefund: {
        async findUnique({ where }) {
            return memory.refunds.find((row) => row.idempotency_key === where.idempotency_key) || null;
        },
        async findFirst({ where, orderBy }) {
            const rows = sortRows(memory.refunds.filter((row) => matches(row, where)), orderBy);
            return rows[0] || null;
        },
        async findMany({ where, orderBy, take }) {
            let rows = sortRows(memory.refunds.filter((row) => matches(row, where)), orderBy);
            if (take) rows = rows.slice(0, take);
            return rows;
        },
        async create({ data }) {
            if (memory.refunds.some((row) => row.idempotency_key === data.idempotency_key)) throw uniqueError();
            const row = {
                id: `refund-${memory.seq++}`,
                razorpay_refund_id: null,
                created_at: new Date(),
                updated_at: new Date(),
                ...data,
            };
            memory.refunds.push(row);
            return row;
        },
        async update({ where, data }) {
            const row = memory.refunds.find((item) => item.id === where.id);
            return apply(row, data);
        },
    },
    delivery: {
        async findFirst({ where, include }) {
            const row = memory.deliveries.find((item) => matches(item, where));
            if (!row) return null;
            if (!include?.order) return row;
            const order = memory.orders.find((item) => item.order_id === row.order_id);
            const bill = memory.bills.find((item) => item.order_id === row.order_id) || null;
            return { ...row, order: { ...order, bill } };
        },
    },
    $transaction(fn) {
        const run = transactionChain.then(() => fn(prisma));
        transactionChain = run.then(() => undefined, () => undefined);
        return run;
    },
};

module.exports = { memory, prisma, reset };
