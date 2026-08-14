const { PrismaClient } = require('@prisma/client')

const prisma = new PrismaClient()

// Note: We no longer clear the database on seed. This script is idempotent.

async function seedServiceCategories() {
    const now = new Date()
    const categories = [
        {
            category_name: 'Regular Wash',
            description: 'Fast & Fresh Laundry',
            icon_url: 'https://picsum.photos/seed/regular-wash/200/200',
            display_order: 1,
            is_active: true,
            created_at: now,
            updated_at: now,
        },
        {
            category_name: 'Pro Clean',
            description: 'Expert dry cleaning',
            icon_url: 'https://picsum.photos/seed/pro-clean/200/200',
            display_order: 2,
            is_active: true,
            created_at: now,
            updated_at: now,
        },
        {
            category_name: 'Home Linens',
            description: 'Household items',
            icon_url: 'https://picsum.photos/seed/home-linens/200/200',
            display_order: 3,
            is_active: true,
            created_at: now,
            updated_at: now,
        },
        {
            category_name: 'Luxury Care',
            description: 'Delicate fabric treatment',
            icon_url: 'https://picsum.photos/seed/luxury-care/200/200',
            display_order: 4,
            is_active: true,
            created_at: now,
            updated_at: now,
        },
        {
            category_name: 'Add-On Services',
            description: 'Additional premium services',
            icon_url: 'https://picsum.photos/seed/add-on-services/200/200',
            display_order: 5,
            is_active: true,
            created_at: now,
            updated_at: now,
        },
    ]

    await prisma.serviceCategory.createMany({
        data: categories,
        skipDuplicates: true,
    })
    console.log('🧾 Seeded service categories')
}

async function seedClothesItemsForServices() {
    const services = await prisma.service.findMany({
        select: { service_id: true, service_name: true },
    })

    let totalCreated = 0
    for (const svc of services) {
        // Check if this service already has clothes items
        const existingCount = await prisma.clothesItem.count({
            where: { service_id: svc.service_id },
        })
        if (existingCount > 0) continue

        const now = new Date()
        // Basic defaults based on service_name; simple generic items
        const defaults = [
            {
                service_id: svc.service_id,
                item_name: `${svc.service_name} - Shirt`,
                per_unit_price: 40.0,
                icon_url: 'https://picsum.photos/seed/shirt/200/200',
                is_active: true,
                display_order: 1,
                created_at: now,
                updated_at: now,
            },
            {
                service_id: svc.service_id,
                item_name: `${svc.service_name} - Pants`,
                per_unit_price: 50.0,
                icon_url: 'https://picsum.photos/seed/pants/200/200',
                is_active: true,
                display_order: 2,
                created_at: now,
                updated_at: now,
            },
            {
                service_id: svc.service_id,
                item_name: `${svc.service_name} - Jacket`,
                per_unit_price: 120.0,
                icon_url: 'https://picsum.photos/seed/jacket/200/200',
                is_active: true,
                display_order: 3,
                created_at: now,
                updated_at: now,
            },
        ]

        const result = await prisma.clothesItem.createMany({
            data: defaults,
            skipDuplicates: true,
        })
        totalCreated += result.count
    }

    console.log(`👕 Seeded clothes items for services (created: ${totalCreated})`)
}

async function main() {
    console.log('🌱 Seeding data (idempotent)...')
    await seedServiceCategories()
    await seedClothesItemsForServices()
    console.log('🎉 Seeding complete')
}

main()
    .catch((e) => {
        console.error('❌ Seed failed:', e)
        process.exit(1)
    })
    .finally(async () => {
        await prisma.$disconnect()
    })

