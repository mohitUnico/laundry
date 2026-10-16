/**
 * Print catalogue row counts and a checksum. Run before and after migrations
 * and compare the two outputs.
 *
 * Usage: node scripts/verify-catalogue.js
 */
require('../src/config/env');
const prisma = require('../src/config/database');
const { snapshotCatalogue } = require('../src/utils/catalogue-io');

async function main() {
    const snap = await snapshotCatalogue(prisma);
    console.log('Catalogue verification');
    console.log(`  categories:  ${snap.counts.categories}`);
    console.log(`  services:    ${snap.counts.services}`);
    console.log(`  clothes:     ${snap.counts.clothes}`);
    console.log(`  service men: ${snap.counts.serviceMen}`);
    console.log(`  checksum:    ${snap.checksum}`);
}

main()
    .catch((err) => {
        console.error('verify-catalogue failed:', err);
        process.exit(1);
    })
    .finally(async () => {
        await prisma.$disconnect();
    });
