/**
 * Check Users in Database
 */

const { PrismaClient } = require('@prisma/client');
const prisma = new PrismaClient();

async function checkUsers() {
  try {
    console.log('\n📊 Checking users in database...\n');

    const users = await prisma.user.findMany({
      select: {
        user_id: true,
        full_name: true,
        email: true,
        role: true,
        is_active: true,
        mart_id: true,
        created_at: true,
      },
      orderBy: {
        created_at: 'desc',
      },
    });

    if (users.length === 0) {
      console.log('❌ No users found in the database!\n');
    } else {
      console.log(`✅ Found ${users.length} user(s):\n`);
      console.log('='.repeat(100));
      users.forEach((user, index) => {
        console.log(`${index + 1}. ${user.full_name} (${user.role})`);
        console.log(`   Email: ${user.email}`);
        console.log(`   User ID: ${user.user_id}`);
        console.log(`   Mart ID: ${user.mart_id}`);
        console.log(`   Active: ${user.is_active}`);
        console.log(`   Created: ${user.created_at}`);
        console.log('='.repeat(100));
      });
    }

    await prisma.$disconnect();
  } catch (error) {
    console.error('❌ Error:', error.message);
    await prisma.$disconnect();
    process.exit(1);
  }
}

checkUsers();

