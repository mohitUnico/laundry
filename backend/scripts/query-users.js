/**
 * Query Users Table with Filters
 * Usage: 
 *   node query-users.js                    # All users
 *   node query-users.js --role=manager     # Filter by role
 *   node query-users.js --active=true      # Filter by active status
 *   node query-users.js --mart=<mart_id>   # Filter by mart
 */

const { PrismaClient } = require('@prisma/client');
const prisma = new PrismaClient();

async function queryUsers() {
  try {
    const args = process.argv.slice(2);
    const filters = {};

    // Parse command line arguments
    args.forEach(arg => {
      if (arg.startsWith('--role=')) {
        filters.role = arg.split('=')[1];
      }
      if (arg.startsWith('--active=')) {
        filters.is_active = arg.split('=')[1] === 'true';
      }
      if (arg.startsWith('--mart=')) {
        filters.mart_id = arg.split('=')[1];
      }
    });

    console.log('\n🔍 Querying users table...');
    if (Object.keys(filters).length > 0) {
      console.log('Filters:', JSON.stringify(filters, null, 2));
    }
    console.log();

    const users = await prisma.user.findMany({
      where: filters,
      include: {
        mart: {
          select: {
            mart_id: true,
            mart_name: true,
            contact_email: true,
          },
        },
      },
      orderBy: {
        created_at: 'desc',
      },
    });

    if (users.length === 0) {
      console.log('❌ No users found matching criteria.\n');
    } else {
      console.log(`✅ Found ${users.length} user(s):\n`);
      console.log('='.repeat(100));
      users.forEach((user, index) => {
        console.log(`\n${index + 1}. ${user.full_name} (${user.role})`);
        console.log(`   📧 Email: ${user.email}`);
        console.log(`   📱 Phone: ${user.phone}`);
        console.log(`   🆔 User ID: ${user.user_id}`);
        console.log(`   🏢 Mart: ${user.mart?.mart_name || 'N/A'} (${user.mart_id})`);
        console.log(`   ${user.is_active ? '✅' : '❌'} Active: ${user.is_active}`);
        console.log(`   📅 Created: ${user.created_at}`);
        console.log(`   🔄 Updated: ${user.updated_at}`);
      });
      console.log('\n' + '='.repeat(100));
      console.log();
    }

    // Summary
    const summary = await prisma.user.groupBy({
      by: ['role'],
      _count: true,
      where: filters.mart_id ? { mart_id: filters.mart_id } : undefined,
    });

    console.log('\n📊 Summary by Role:');
    summary.forEach(item => {
      console.log(`   ${item.role}: ${item._count} user(s)`);
    });
    console.log();

    await prisma.$disconnect();
  } catch (error) {
    console.error('❌ Error:', error.message);
    await prisma.$disconnect();
    process.exit(1);
  }
}

queryUsers();

