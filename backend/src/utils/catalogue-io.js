const path = require('path');
const fs = require('fs');
const { execFileSync } = require('child_process');
const { checksumCatalogue } = require('./catalogue-checksum');

const CATALOGUE_KEEP_TABLES = [
    'laundry_config',
    'users',
    'staff',
    'service_categories',
    'services',
    'clothes_items',
    'coupons',
    'delivery_staffs',
    'delivery_staff_shifts',
    'delivery_staff_locations',
    '_prisma_migrations',
];

const TRANSACTIONAL_TABLES = [
    'cart_items',
    'carts',
    'order_item_selections',
    'service_queue',
    'order_items',
    'pickup_for_delivery',
    'drop_for_delivery',
    'delivery_assignment_recipients',
    'delivery_assignment_requests',
    'delivery_staff_notifications',
    'delivery',
    'bills',
    'orders',
    'customer_addresses',
    'customers',
    'daily_metrics',
    'otp_verifications',
    'otp_sessions',
    'refresh_tokens',
];

function defaultBackupPath() {
    return path.resolve(__dirname, '../../../.tmp/catalogue-backup.json');
}

function defaultDumpPath() {
    return path.resolve(__dirname, '../../../.tmp/laundry-db.dump');
}

async function loadCatalogue(prisma) {
    const [categories, services, clothes, serviceMen] = await Promise.all([
        prisma.serviceCategory.findMany({ orderBy: { category_id: 'asc' } }),
        prisma.service.findMany({ orderBy: { service_id: 'asc' } }),
        prisma.clothesItem.findMany({ orderBy: { cloth_id: 'asc' } }),
        prisma.staff.findMany({
            where: { role: 'service_man', service_id: { not: null } },
            orderBy: { staff_id: 'asc' },
        }),
    ]);
    return { categories, services, clothes, serviceMen };
}

async function snapshotCatalogue(prisma) {
    const data = await loadCatalogue(prisma);
    return {
        counts: {
            categories: data.categories.length,
            services: data.services.length,
            clothes: data.clothes.length,
            serviceMen: data.serviceMen.length,
        },
        checksum: checksumCatalogue(data),
        data,
    };
}

async function countRows(prisma, tables) {
    const counts = {};
    for (const table of tables) {
        try {
            const rows = await prisma.$queryRawUnsafe(`SELECT COUNT(*)::int AS n FROM "${table}"`);
            counts[table] = rows[0]?.n ?? 0;
        } catch (err) {
            if (String(err.message || '').includes('does not exist')) {
                counts[table] = 0;
                continue;
            }
            throw err;
        }
    }
    return counts;
}

async function backupCatalogue(prisma, destPath = defaultBackupPath()) {
    const snap = await snapshotCatalogue(prisma);
    fs.mkdirSync(path.dirname(destPath), { recursive: true });
    fs.writeFileSync(
        destPath,
        JSON.stringify(
            {
                exported_at: new Date().toISOString(),
                counts: snap.counts,
                checksum: snap.checksum,
                categories: snap.data.categories,
                services: snap.data.services,
                clothes: snap.data.clothes,
                serviceMen: snap.data.serviceMen,
            },
            null,
            2
        )
    );
    return { path: destPath, counts: snap.counts, checksum: snap.checksum };
}

function tryPgDump(dumpPath = defaultDumpPath()) {
    const databaseUrl = process.env.DATABASE_URL || process.env.DIRECT_URL;
    if (!databaseUrl) {
        return { ok: false, reason: 'DATABASE_URL not set' };
    }
    fs.mkdirSync(path.dirname(dumpPath), { recursive: true });
    try {
        execFileSync('pg_dump', ['--format=custom', `--file=${dumpPath}`, databaseUrl], {
            stdio: 'ignore',
        });
        return { ok: true, path: dumpPath };
    } catch (err) {
        return { ok: false, reason: err.message };
    }
}

async function clearTransactionalData(prisma, { confirm = false } = {}) {
    const before = await countRows(prisma, TRANSACTIONAL_TABLES);
    if (!confirm) {
        return { cleared: false, before, after: before };
    }
    const quoted = TRANSACTIONAL_TABLES.map((t) => `"${t}"`).join(', ');
    await prisma.$executeRawUnsafe(`TRUNCATE TABLE ${quoted} RESTART IDENTITY CASCADE`);
    const after = await countRows(prisma, TRANSACTIONAL_TABLES);
    return { cleared: true, before, after };
}

module.exports = {
    CATALOGUE_KEEP_TABLES,
    TRANSACTIONAL_TABLES,
    defaultBackupPath,
    defaultDumpPath,
    loadCatalogue,
    snapshotCatalogue,
    countRows,
    backupCatalogue,
    tryPgDump,
    clearTransactionalData,
};
