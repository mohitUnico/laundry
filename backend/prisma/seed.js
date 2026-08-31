const { PrismaClient } = require('@prisma/client')

const prisma = new PrismaClient()

// Idempotent seed — safe to re-run. Does not truncate existing data.

const icon = (seed) =>
    `https://picsum.photos/seed/${encodeURIComponent(seed)}/200/200`

/** Standard per-piece clothing (Regular Wash, Pro Clean, Delicate Wash, Dry Cleaning) */
const STANDARD_CLOTHES = [
    { item_name: 'Top Wear', per_unit_price: 45, icon_url: icon('top-wear'), display_order: 1 },
    { item_name: 'Bottom Wear', per_unit_price: 50, icon_url: icon('bottom-wear'), display_order: 2 },
    { item_name: 'Kurti/Kurta', per_unit_price: 55, icon_url: icon('kurta'), display_order: 3 },
    { item_name: 'Saree', per_unit_price: 65, icon_url: icon('saree'), display_order: 4 },
    { item_name: 'Lingerie', per_unit_price: 35, icon_url: icon('lingerie'), display_order: 5 },
]

/** Luxury Care — no Lingerie per flow diagram */
const LUXURY_CLOTHES = STANDARD_CLOTHES.filter((i) => i.item_name !== 'Lingerie')

const STAIN_CLOTHES = [
    { item_name: 'Heavy Stained', per_unit_price: 120, icon_url: icon('heavy-stained'), display_order: 1 },
    { item_name: 'Light Stained', per_unit_price: 80, icon_url: icon('light-stained'), display_order: 2 },
]

const SHOE_CLOTHES = [
    { item_name: 'Sneakers', per_unit_price: 150, icon_url: icon('sneakers'), display_order: 1 },
    { item_name: 'Formal shoes', per_unit_price: 180, icon_url: icon('formal-shoes'), display_order: 2 },
    { item_name: 'Sports shoes', per_unit_price: 160, icon_url: icon('sports-shoes'), display_order: 3 },
    { item_name: 'Loafers', per_unit_price: 170, icon_url: icon('loafers'), display_order: 4 },
]

const WINTER_CLOTHES = [
    { item_name: 'Woolens', per_unit_price: 90, icon_url: icon('woolens'), display_order: 1 },
    { item_name: 'Blazers', per_unit_price: 200, icon_url: icon('blazers'), display_order: 2 },
    { item_name: 'Jackets', per_unit_price: 180, icon_url: icon('jackets'), display_order: 3 },
    { item_name: 'Cashmere Sweater', per_unit_price: 250, icon_url: icon('cashmere-sweater'), display_order: 4 },
    { item_name: 'Accessories', per_unit_price: 75, icon_url: icon('winter-accessories'), display_order: 5 },
]

const HOME_LINEN_CLOTHES = [
    { item_name: 'Carpet', per_unit_price: 300, icon_url: icon('carpet'), display_order: 1 },
    { item_name: 'Curtains', per_unit_price: 120, icon_url: icon('curtains'), display_order: 2 },
    { item_name: 'Blanket', per_unit_price: 150, icon_url: icon('blanket'), display_order: 3 },
    { item_name: 'Table Clothes', per_unit_price: 80, icon_url: icon('table-clothes'), display_order: 4 },
    { item_name: 'Napkins', per_unit_price: 40, icon_url: icon('napkins'), display_order: 5 },
    { item_name: 'Bedsheets', per_unit_price: 100, icon_url: icon('bedsheets'), display_order: 6 },
]

/**
 * Full catalog extracted from the service flow diagram.
 * Regular Wash supports per-piece + per-kg (per_kg_price set on each service).
 */
const CATALOG = [
    {
        category_name: 'Regular Wash',
        description: 'Fast & Fresh Laundry',
        icon_url: icon('regular-wash'),
        display_order: 1,
        services: [
            {
                service_name: 'Wash & Fold',
                description: 'Professional washing and folding',
                base_price: 0,
                per_kg_price: 80,
                estimated_hours: 24,
                icon_url: icon('wash-fold'),
                display_order: 1,
                clothes: STANDARD_CLOTHES,
            },
            {
                service_name: 'Wash & Iron',
                description: 'Professional washing and ironing',
                base_price: 0,
                per_kg_price: 95,
                estimated_hours: 48,
                icon_url: icon('wash-iron'),
                display_order: 2,
                clothes: STANDARD_CLOTHES,
            },
            {
                service_name: 'Hand Wash',
                description: 'Gentle hand wash for delicate everyday wear',
                base_price: 0,
                per_kg_price: 110,
                estimated_hours: 48,
                icon_url: icon('hand-wash'),
                display_order: 3,
                clothes: STANDARD_CLOTHES,
            },
            {
                service_name: 'Iron only',
                description: 'Press and iron only — no washing',
                base_price: 0,
                per_kg_price: 60,
                estimated_hours: 24,
                icon_url: icon('iron-only'),
                display_order: 4,
                clothes: STANDARD_CLOTHES,
            },
        ],
    },
    {
        category_name: 'Pro Clean',
        description: 'Expert dry cleaning and specialty care',
        icon_url: icon('pro-clean'),
        display_order: 2,
        services: [
            {
                service_name: 'Dry Cleaning',
                description: 'Deep cleaning for garments that need dry clean',
                base_price: 0,
                per_kg_price: null,
                estimated_hours: 72,
                icon_url: icon('dry-cleaning'),
                display_order: 1,
                clothes: STANDARD_CLOTHES,
            },
            {
                service_name: 'Stain Removal',
                description: 'Pre-treatment and removal of stains',
                base_price: 0,
                per_kg_price: null,
                estimated_hours: 48,
                icon_url: icon('stain-removal'),
                display_order: 2,
                clothes: STAIN_CLOTHES,
            },
            {
                service_name: 'Shoe Cleaning',
                description: 'Fresh and spotless shoe care',
                base_price: 0,
                per_kg_price: null,
                estimated_hours: 48,
                icon_url: icon('shoe-cleaning'),
                display_order: 3,
                clothes: SHOE_CLOTHES,
            },
            {
                service_name: 'Winter Wear',
                description: 'Specialized cleaning for woolens and winter garments',
                base_price: 0,
                per_kg_price: null,
                estimated_hours: 72,
                icon_url: icon('winter-wear'),
                display_order: 4,
                clothes: WINTER_CLOTHES,
            },
            {
                service_name: 'Delicate Wash',
                description: 'Gentle wash for wool, silk, and delicate fabrics',
                base_price: 0,
                per_kg_price: null,
                estimated_hours: 48,
                icon_url: icon('delicate-wash'),
                display_order: 5,
                clothes: STANDARD_CLOTHES,
            },
        ],
    },
    {
        category_name: 'Home Linens',
        description: 'Household linen and upholstery items',
        icon_url: icon('home-linens'),
        display_order: 3,
        services: [
            {
                service_name: 'Home Linens',
                description: 'Carpets, curtains, bedding, and table linen',
                base_price: 0,
                per_kg_price: null,
                estimated_hours: 72,
                icon_url: icon('home-linens-service'),
                display_order: 1,
                clothes: HOME_LINEN_CLOTHES,
            },
        ],
    },
    {
        category_name: 'Luxury Care',
        description: 'Delicate fabric treatment and designer wear',
        icon_url: icon('luxury-care'),
        display_order: 4,
        services: [
            {
                service_name: 'Steam Press',
                description: 'Steam press for non iron-friendly clothes',
                base_price: 0,
                per_kg_price: null,
                estimated_hours: 24,
                icon_url: icon('steam-press'),
                display_order: 1,
                clothes: LUXURY_CLOTHES,
            },
            {
                service_name: 'Designer Wear',
                description: 'Premium care for designer and festive wear',
                base_price: 0,
                per_kg_price: null,
                estimated_hours: 72,
                icon_url: icon('designer-wear'),
                display_order: 2,
                clothes: LUXURY_CLOTHES,
            },
        ],
    },
]

async function findOrCreateCategory(categoryDef) {
    const existing = await prisma.serviceCategory.findFirst({
        where: { category_name: categoryDef.category_name },
    })
    if (existing) return existing

    return prisma.serviceCategory.create({
        data: {
            category_name: categoryDef.category_name,
            description: categoryDef.description,
            icon_url: categoryDef.icon_url,
            display_order: categoryDef.display_order,
            is_active: true,
        },
    })
}

async function findOrCreateService(categoryId, serviceDef) {
    const existing = await prisma.service.findFirst({
        where: {
            category_id: categoryId,
            service_name: serviceDef.service_name,
        },
    })
    if (existing) return existing

    return prisma.service.create({
        data: {
            category_id: categoryId,
            service_name: serviceDef.service_name,
            description: serviceDef.description,
            base_price: serviceDef.base_price,
            per_kg_price: serviceDef.per_kg_price,
            estimated_hours: serviceDef.estimated_hours,
            icon_url: serviceDef.icon_url,
            display_order: serviceDef.display_order,
            is_active: true,
        },
    })
}

async function seedClothesForService(serviceId, clothesDefs) {
    const now = new Date()
    const data = clothesDefs.map((item) => ({
        service_id: serviceId,
        item_name: item.item_name,
        per_unit_price: item.per_unit_price,
        icon_url: item.icon_url,
        is_active: true,
        display_order: item.display_order,
        created_at: now,
        updated_at: now,
    }))

    const result = await prisma.clothesItem.createMany({
        data,
        skipDuplicates: true,
    })
    return result.count
}

async function main() {
    console.log('🌱 Seeding service catalog (idempotent)...')

    let categoriesCreated = 0
    let servicesCreated = 0
    let clothesCreated = 0

    for (const categoryDef of CATALOG) {
        const beforeCat = await prisma.serviceCategory.count({
            where: { category_name: categoryDef.category_name },
        })
        const category = await findOrCreateCategory(categoryDef)
        if (beforeCat === 0) categoriesCreated++

        for (const serviceDef of categoryDef.services) {
            const beforeSvc = await prisma.service.count({
                where: {
                    category_id: category.category_id,
                    service_name: serviceDef.service_name,
                },
            })
            const service = await findOrCreateService(category.category_id, serviceDef)
            if (beforeSvc === 0) servicesCreated++

            const created = await seedClothesForService(service.service_id, serviceDef.clothes)
            clothesCreated += created
        }
    }

    console.log(`🧾 Categories ensured (${categoriesCreated} new)`)
    console.log(`🧺 Services ensured (${servicesCreated} new)`)
    console.log(`👕 Clothes items created (${clothesCreated} new, skipped existing)`)
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
