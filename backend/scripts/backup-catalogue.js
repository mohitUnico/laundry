/**
 * Export ServiceCategory, Service, ClothesItem and linked service-man Staff.
 * Also attempts a pg_dump of the whole database (skipped if pg_dump is missing).
 *
 * Usage: node scripts/backup-catalogue.js
 */
require('../src/config/env');
const prisma = require('../src/config/database');
const { backupCatalogue, tryPgDump, defaultBackupPath, defaultDumpPath } = require('../src/utils/catalogue-io');

async function main() {
    const json = await backupCatalogue(prisma);
    console.log('Catalogue JSON backup written');
    console.log(`  path:     ${json.path || defaultBackupPath()}`);
    console.log(`  counts:   ${JSON.stringify(json.counts)}`);
    console.log(`  checksum: ${json.checksum}`);

    const dump = tryPgDump();
    if (dump.ok) {
        console.log(`pg_dump written: ${dump.path || defaultDumpPath()}`);
    } else {
        console.warn(`pg_dump skipped: ${dump.reason}`);
    }
}

main()
    .catch((err) => {
        console.error('backup-catalogue failed:', err);
        process.exit(1);
    })
    .finally(async () => {
        await prisma.$disconnect();
    });
