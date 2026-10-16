/**
 * Delete only transactional tables (orders, carts, deliveries, bills, queues,
 * assignments, notifications, customers). Never touches the catalogue,
 * LaundryConfig, Coupon, admin, or staff accounts.
 *
 * Refuses to run unless --confirm is passed.
 *
 * Usage:
 *   node scripts/clear-transactional-data.js           # dry-run, prints counts
 *   node scripts/clear-transactional-data.js --confirm # actually delete
 */
require('../src/config/env');
const prisma = require('../src/config/database');
const { clearTransactionalData, snapshotCatalogue } = require('../src/utils/catalogue-io');

async function main() {
    const confirm = process.argv.includes('--confirm');
    const beforeCat = await snapshotCatalogue(prisma);
    console.log('Catalogue before:');
    console.log(`  counts:   ${JSON.stringify(beforeCat.counts)}`);
    console.log(`  checksum: ${beforeCat.checksum}`);

    const result = await clearTransactionalData(prisma, { confirm });
    console.log(confirm ? 'Transactional tables truncated.' : 'Dry-run (pass --confirm to delete).');
    console.log('Row counts before:', result.before);
    console.log('Row counts after: ', result.after);

    const afterCat = await snapshotCatalogue(prisma);
    console.log('Catalogue after:');
    console.log(`  counts:   ${JSON.stringify(afterCat.counts)}`);
    console.log(`  checksum: ${afterCat.checksum}`);

    if (beforeCat.checksum !== afterCat.checksum) {
        console.error('ERROR: catalogue checksum changed. Aborting with exit 1.');
        process.exit(1);
    }
}

main()
    .catch((err) => {
        console.error('clear-transactional-data failed:', err);
        process.exit(1);
    })
    .finally(async () => {
        await prisma.$disconnect();
    });
