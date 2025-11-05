/**
 * Find User by Email
 * Usage: node find-user.js <email>
 */

const { PrismaClient } = require('@prisma/client');
const prisma = new PrismaClient();

const email = process.argv[2];

if (!email) {
  console.error('❌ Please provide an email address');
  console.error('Usage: node find-user.js <email>');
  process.exit(1);
}

async function findUser() {
  try {
    const user = await prisma.user.findUnique({
      where: { email },
      include: {
        mart: {
          select: {
            mart_id: true,
            mart_name: true,
            contact_email: true,
          },
        },
      },
    });

    if (!user) {
      console.log(`\n❌ No user found with email: ${email}\n`);
    } else {
      console.log('\n✅ User found!\n');
      console.log('='.repeat(80));
      console.log(`Full Name: ${user.full_name}`);
      console.log(`Email: ${user.email}`);
      console.log(`Phone: ${user.phone}`);
      console.log(`Role: ${user.role}`);
      console.log(`Active: ${user.is_active}`);
      console.log(`User ID: ${user.user_id}`);
      console.log(`Mart ID: ${user.mart_id}`);
      console.log(`Mart Name: ${user.mart?.mart_name || 'N/A'}`);
      console.log(`Created: ${user.created_at}`);
      console.log(`Updated: ${user.updated_at}`);
      console.log('='.repeat(80));
      console.log();
    }

    await prisma.$disconnect();
  } catch (error) {
    console.error('❌ Error:', error.message);
    await prisma.$disconnect();
    process.exit(1);
  }
}

findUser();

