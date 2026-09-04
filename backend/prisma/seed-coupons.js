const { PrismaClient } = require('@prisma/client')

const prisma = new PrismaClient()

const DAY_MS = 24 * 60 * 60 * 1000

const coupons = [
    {
        code: 'WELCOME20',
        description: '20% off for new customers',
        discount_type: 'percentage',
        discount_value: 20,
        max_discount: 150,
        min_order_value: 299,
        usage_limit: 1000,
        usage_per_user: 1,
        valid_for_days: 90,
        is_active: true,
    },
    {
        code: 'FLAT100',
        description: 'Flat ₹100 off on orders above ₹499',
        discount_type: 'fixed',
        discount_value: 100,
        max_discount: 100,
        min_order_value: 499,
        usage_limit: 500,
        usage_per_user: 2,
        valid_for_days: 60,
        is_active: true,
    },
    {
        code: 'WASH15',
        description: '15% off on your laundry order',
        discount_type: 'percentage',
        discount_value: 15,
        max_discount: 200,
        min_order_value: 399,
        usage_limit: 750,
        usage_per_user: 3,
        valid_for_days: 45,
        is_active: true,
    },
    {
        code: 'FREESHIP',
        description: 'Flat ₹50 discount toward delivery charges',
        discount_type: 'fixed',
        discount_value: 50,
        max_discount: 50,
        min_order_value: 249,
        usage_limit: 300,
        usage_per_user: 1,
        valid_for_days: 30,
        is_active: true,
    },
    {
        code: 'LUXURY25',
        description: '25% off on premium laundry orders',
        discount_type: 'percentage',
        discount_value: 25,
        max_discount: 300,
        min_order_value: 799,
        usage_limit: 250,
        usage_per_user: 1,
        valid_for_days: 60,
        is_active: true,
    },
    {
        code: 'EXPIRED10',
        description: 'Expired sample promotion for testing',
        discount_type: 'percentage',
        discount_value: 10,
        max_discount: 100,
        min_order_value: 199,
        usage_limit: 100,
        usage_per_user: 1,
        valid_for_days: -1,
        is_active: false,
    },
]

async function seedCoupons() {
    const now = new Date()
    let created = 0
    let updated = 0

    for (const { valid_for_days: validForDays, ...coupon } of coupons) {
        const existing = await prisma.coupon.findFirst({
            where: { code: coupon.code },
            select: { id: true },
        })

        const validTill = new Date(now.getTime() + validForDays * DAY_MS)
        const data = {
            ...coupon,
            valid_from: validForDays < 0
                ? new Date(now.getTime() - 30 * DAY_MS)
                : now,
            valid_till: validTill,
        }

        if (existing) {
            await prisma.coupon.update({
                where: { id: existing.id },
                data,
            })
            updated++
        } else {
            await prisma.coupon.create({ data })
            created++
        }
    }

    console.log(`🎟️ Coupons seeded (${created} created, ${updated} updated)`)
}

seedCoupons()
    .catch((error) => {
        console.error('❌ Coupon seed failed:', error)
        process.exitCode = 1
    })
    .finally(async () => {
        await prisma.$disconnect()
    })
