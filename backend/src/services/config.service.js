const Joi = require('joi');
const prisma = require('../config/database');
const { ValidationError, NotFoundError } = require('../utils/errors');

const CACHE_TTL_MS = 30 * 1000;

const KEY_DEFS = {
    ASSIGNMENT_TIMEOUT_MINUTES: {
        default: 5,
        description: 'Pickup/drop offer window. Production allows 5, 10 or 20. Decimals allowed in tests.',
        publicName: 'assignmentTimeoutMinutes',
        public: true,
        schema: () => {
            const allowed = Joi.number().valid(5, 10, 20);
            if (process.env.NODE_ENV === 'test') {
                return Joi.alternatives()
                    .try(
                        allowed,
                        Joi.number()
                            .positive()
                            .custom((v, helpers) => {
                                if (Number.isInteger(v) && ![5, 10, 20].includes(v)) {
                                    return helpers.error('any.invalid');
                                }
                                return v;
                            })
                    )
                    .required();
            }
            return allowed.required();
        },
    },
    ASSIGNMENT_RANGE_SLICES: {
        default: 5,
        description: 'Number of expanding rings (1-10).',
        public: false,
        schema: () => Joi.number().integer().min(1).max(10).required(),
    },
    ASSIGNMENT_MAX_RANGE_KM: {
        default: 10,
        description: 'Outer radius of the last ring, in km.',
        public: false,
        schema: () => Joi.number().positive().required(),
    },
    PICKUP_DELIVERY_BUFFER_DAYS: {
        default: 2,
        description: 'Minimum calendar days between pickup date and delivery date (Asia/Kolkata).',
        publicName: 'pickupDeliveryBufferDays',
        public: true,
        schema: () => Joi.number().integer().min(0).max(14).required(),
    },
    DELIVERY_FEE: {
        default: 0,
        description: 'Flat delivery fee snapshotted onto the bill at pickup.',
        public: false,
        schema: () => Joi.number().min(0).required(),
    },
    EXPRESS_FEE: {
        default: 0,
        description: 'Flat Express fee snapshotted onto the bill at pickup.',
        public: false,
        schema: () => Joi.number().min(0).required(),
    },
    SERVICE_QUEUE_POLL_SECONDS: {
        default: 120,
        description: 'Service-man queue poll interval. 60 or 120.',
        publicName: 'serviceQueuePollSeconds',
        public: true,
        schema: () => Joi.number().valid(60, 120).required(),
    },
    DIRECTIONS_REFRESH_SECONDS: {
        default: 120,
        description: 'Client hint for Google Directions refresh. Backend never calls Directions.',
        publicName: 'directionsRefreshSeconds',
        public: true,
        schema: () => Joi.number().integer().min(10).max(600).required(),
    },
};

const KEY_NAMES = Object.keys(KEY_DEFS);

let cache = { at: 0, rows: null };

function clearCache() {
    cache = { at: 0, rows: null };
}

function parseEnvValue(raw) {
    if (raw === undefined || raw === null || String(raw).trim() === '') return undefined;
    const asNumber = Number(raw);
    if (!Number.isNaN(asNumber)) return asNumber;
    return raw;
}

function normalizeStored(value) {
    if (value !== null && typeof value === 'object' && !Array.isArray(value) && Object.prototype.hasOwnProperty.call(value, 'n')) {
        return value.n;
    }
    return value;
}

async function loadRows() {
    if (cache.rows && Date.now() - cache.at < CACHE_TTL_MS) {
        return cache.rows;
    }
    const rows = await prisma.appConfig.findMany();
    const map = new Map(rows.map((row) => [row.key, row]));
    cache = { at: Date.now(), rows: map };
    return map;
}

function resolveFrom(rows, key) {
    const def = KEY_DEFS[key];
    if (!def) {
        throw new NotFoundError(`Config key ${key}`);
    }
    const row = rows.get(key);
    if (row) {
        return { key, value: normalizeStored(row.value), source: 'db', description: def.description };
    }
    const envVal = parseEnvValue(process.env[key]);
    if (envVal !== undefined) {
        return { key, value: envVal, source: 'env', description: def.description };
    }
    return { key, value: def.default, source: 'default', description: def.description };
}

async function resolve(key) {
    const rows = await loadRows();
    return resolveFrom(rows, key);
}

async function getNumber(key) {
    const { value } = await resolve(key);
    return Number(value);
}

async function getInt(key) {
    return Math.trunc(await getNumber(key));
}

async function listAll() {
    const rows = await loadRows();
    return KEY_NAMES.map((key) => resolveFrom(rows, key));
}

async function getPublicClientConfig() {
    const all = await listAll();
    const data = {};
    for (const item of all) {
        const def = KEY_DEFS[item.key];
        if (def.public && def.publicName) {
            data[def.publicName] = item.value;
        }
    }
    return data;
}

function validateValue(key, value) {
    const def = KEY_DEFS[key];
    if (!def) {
        throw new NotFoundError(`Config key ${key}`);
    }
    const { error, value: coerced } = def.schema().validate(value);
    if (error) {
        throw new ValidationError(`Invalid value for ${key}`, [
            { field: 'value', message: error.message },
        ]);
    }
    return coerced;
}

async function setValue(key, value, updatedBy) {
    if (!KEY_DEFS[key]) {
        throw new NotFoundError(`Config key ${key}`);
    }
    const coerced = validateValue(key, value);
    await prisma.appConfig.upsert({
        where: { key },
        create: {
            key,
            value: coerced,
            description: KEY_DEFS[key].description,
            updated_by: updatedBy || null,
        },
        update: {
            value: coerced,
            description: KEY_DEFS[key].description,
            updated_by: updatedBy || null,
        },
    });
    clearCache();
    return resolve(key);
}

async function seedDefaults() {
    for (const key of KEY_NAMES) {
        const def = KEY_DEFS[key];
        const existing = await prisma.appConfig.findUnique({ where: { key } });
        if (!existing) {
            await prisma.appConfig.create({
                data: {
                    key,
                    value: def.default,
                    description: def.description,
                },
            });
        }
    }
    clearCache();
}

async function deleteKeyForTests(key) {
    if (process.env.NODE_ENV !== 'test') {
        throw new Error('deleteKeyForTests is test-only');
    }
    await prisma.appConfig.deleteMany({ where: { key } });
    clearCache();
}

module.exports = {
    KEY_DEFS,
    KEY_NAMES,
    CACHE_TTL_MS,
    clearCache,
    resolve,
    getNumber,
    getInt,
    listAll,
    getPublicClientConfig,
    validateValue,
    setValue,
    seedDefaults,
    deleteKeyForTests,
};
