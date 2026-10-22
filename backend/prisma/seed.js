const { PrismaClient } = require('@prisma/client')
const { CATALOG } = require('./catalog.seed')

const prisma = new PrismaClient()

// Idempotent seed — safe to re-run. Does not truncate existing data.

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

const SEED_EMAILS = {
    admin: 'admin@washbee.test',
    customer: 'customer@washbee.test',
    collectionManager: 'cm@washbee.test',
    distributionManager: 'dm@washbee.test',
}

const LAUNDRY_ORIGIN = { latitude: 12.9715987, longitude: 77.5945627 }

/** Offset origin by `km` due east (approx). */
function pointEastOfOrigin(km) {
    const lngPerKm = 1 / (111.32 * Math.cos((LAUNDRY_ORIGIN.latitude * Math.PI) / 180))
    return {
        latitude: LAUNDRY_ORIGIN.latitude,
        longitude: LAUNDRY_ORIGIN.longitude + km * lngPerKm,
    }
}

const PICKUP_STAFF = [
    { email: 'pickup-1km@washbee.test', km: 1, name: 'Pickup One Km' },
    { email: 'pickup-3km@washbee.test', km: 3, name: 'Pickup Three Km' },
    { email: 'pickup-6km@washbee.test', km: 6, name: 'Pickup Six Km' },
    { email: 'pickup-12km@washbee.test', km: 12, name: 'Pickup Twelve Km' },
]

function slug(value) {
    return String(value)
        .toLowerCase()
        .replace(/[^a-z0-9]+/g, '-')
        .replace(/^-|-$/g, '')
}

async function seedCatalogueIfEmpty() {
    const existing = await prisma.serviceCategory.count()
    if (existing > 0) {
        console.log(`Catalogue already present (${existing} categories) — skipping catalogue seed`)
        return { categoriesCreated: 0, servicesCreated: 0, clothesCreated: 0, skipped: true }
    }

    console.log('🌱 Seeding service catalog (empty database)...')
    let categoriesCreated = 0
    let servicesCreated = 0
    let clothesCreated = 0

    for (const categoryDef of CATALOG) {
        const category = await findOrCreateCategory(categoryDef)
        categoriesCreated++
        for (const serviceDef of categoryDef.services) {
            const service = await findOrCreateService(category.category_id, serviceDef)
            servicesCreated++
            clothesCreated += await seedClothesForService(service.service_id, serviceDef.clothes)
        }
    }

    console.log(`🧾 Categories created (${categoriesCreated})`)
    console.log(`🧺 Services created (${servicesCreated})`)
    console.log(`👕 Clothes items created (${clothesCreated})`)
    return { categoriesCreated, servicesCreated, clothesCreated, skipped: false }
}

async function seedLaundryConfig() {
    const existing = await prisma.laundryConfig.findFirst({ where: { is_active: true } })
    if (existing) {
        console.log('LaundryConfig already present — leaving it')
        return existing
    }
    const created = await prisma.laundryConfig.create({
        data: {
            business_name: 'WashBee Test Laundry',
            contact_email: 'laundry@washbee.test',
            contact_phone: '9999999999',
            address: 'MG Road, Bengaluru',
            latitude: LAUNDRY_ORIGIN.latitude,
            longitude: LAUNDRY_ORIGIN.longitude,
            service_radius_km: [{ from_km: 0, to_km: 15, fee: 0 }],
            is_active: true,
        },
    })
    console.log('LaundryConfig created')
    return created
}

async function seedAdmin() {
    const existing = await prisma.user.findUnique({ where: { email: SEED_EMAILS.admin } })
    if (existing) return existing
    const created = await prisma.user.create({
        data: {
            full_name: 'WashBee Admin',
            email: SEED_EMAILS.admin,
            phone: '9000000001',
            role: 'admin',
            is_active: true,
        },
    })
    console.log('Admin user created')
    return created
}

async function findOrCreateStaff({ role, email, full_name, service_id }) {
    const existing = await prisma.staff.findUnique({ where: { email } })
    if (existing) {
        if (service_id && !existing.service_id) {
            return prisma.staff.update({
                where: { staff_id: existing.staff_id },
                data: { service_id, role, is_active: true },
            })
        }
        return existing
    }
    return prisma.staff.create({
        data: {
            role,
            email,
            full_name,
            phone: null,
            is_active: true,
            service_id: service_id || null,
        },
    })
}

async function seedManagers() {
    await findOrCreateStaff({
        role: 'collection_manager',
        email: SEED_EMAILS.collectionManager,
        full_name: 'Collection Manager',
    })
    await findOrCreateStaff({
        role: 'distribution_manager',
        email: SEED_EMAILS.distributionManager,
        full_name: 'Distribution Manager',
    })
    console.log('Collection + distribution managers ensured')
}

async function seedServiceMen() {
    const services = await prisma.service.findMany({ orderBy: { service_name: 'asc' } })
    const missing = []
    let created = 0
    for (const service of services) {
        const existing = await prisma.staff.findFirst({
            where: { role: 'service_man', service_id: service.service_id },
        })
        if (existing) continue
        await findOrCreateStaff({
            role: 'service_man',
            email: `sm-${slug(service.service_name)}@washbee.test`,
            full_name: `Service Man ${service.service_name}`,
            service_id: service.service_id,
        })
        created++
        missing.push(service.service_name)
    }
    if (created === 0) {
        console.log(`Service men: every service already has one (${services.length})`)
    } else {
        console.log(`Service men created for: ${missing.join(', ')}`)
    }
    return { created, missing }
}

async function seedDeliveryStaff() {
    for (const def of PICKUP_STAFF) {
        const point = pointEastOfOrigin(def.km)
        let staff = await prisma.deliveryStaff.findUnique({ where: { email: def.email } })
        if (!staff) {
            staff = await prisma.deliveryStaff.create({
                data: {
                    full_name: def.name,
                    email: def.email,
                    phone: `980000000${def.km}`,
                    vehicle_type: 'bike',
                    vehicle_number: `KA01${String(def.km).padStart(4, '0')}`,
                    current_latitude: point.latitude,
                    current_longitude: point.longitude,
                    address: `${def.km} km east of laundry`,
                    verification_status: 'verified',
                    is_verified_by_admin: true,
                    is_active: true,
                },
            })
        } else {
            await prisma.deliveryStaff.update({
                where: { staff_id: staff.staff_id },
                data: {
                    current_latitude: point.latitude,
                    current_longitude: point.longitude,
                    is_verified_by_admin: true,
                    verification_status: 'verified',
                    is_active: true,
                },
            })
        }

        const activeShift = await prisma.deliveryStaffShift.findFirst({
            where: { staff_id: staff.staff_id, is_active: true },
        })
        if (!activeShift) {
            await prisma.deliveryStaffShift.create({
                data: {
                    staff_id: staff.staff_id,
                    is_active: true,
                    last_latitude: point.latitude,
                    last_longitude: point.longitude,
                    last_location_at: new Date(),
                },
            })
        }
    }
    console.log('Delivery staff (1/3/6/12 km) with active shifts ensured')
}

async function seedCustomer() {
    let customer = await prisma.customer.findUnique({ where: { email: SEED_EMAILS.customer } })
    if (!customer) {
        customer = await prisma.customer.create({
            data: {
                full_name: 'Test Customer',
                email: SEED_EMAILS.customer,
                phone: '9111111111',
                is_active: true,
            },
        })
        console.log('Customer created')
    }

    const home = pointEastOfOrigin(0.4)
    const work = pointEastOfOrigin(0.8)
    const labels = [
        {
            address_label: 'home',
            full_address: '12 Home Street, Bengaluru',
            latitude: home.latitude,
            longitude: home.longitude,
            is_default: true,
        },
        {
            address_label: 'work',
            full_address: '44 Work Avenue, Bengaluru',
            latitude: work.latitude,
            longitude: work.longitude,
            is_default: false,
        },
    ]
    for (const addr of labels) {
        const existing = await prisma.customerAddress.findFirst({
            where: { customer_id: customer.customer_id, address_label: addr.address_label },
        })
        if (!existing) {
            await prisma.customerAddress.create({
                data: { customer_id: customer.customer_id, ...addr },
            })
        }
    }
    return customer
}

async function seedCoupons() {
    const defs = [
        {
            code: 'WASH10',
            description: '10% off',
            discount_type: 'percentage',
            discount_value: 10,
            max_discount: 100,
            min_order_value: 0,
            usage_limit: 1000,
            usage_per_user: 5,
            valid_from: new Date('2020-01-01'),
            valid_till: new Date('2030-12-31'),
            is_active: true,
        },
        {
            code: 'FLAT50',
            description: 'Flat 50 off',
            discount_type: 'fixed',
            discount_value: 50,
            max_discount: 50,
            min_order_value: 100,
            usage_limit: 1000,
            usage_per_user: 5,
            valid_from: new Date('2020-01-01'),
            valid_till: new Date('2030-12-31'),
            is_active: true,
        },
        {
            code: 'EXPIRED',
            description: 'Expired coupon',
            discount_type: 'percentage',
            discount_value: 20,
            max_discount: 50,
            min_order_value: 0,
            usage_limit: 10,
            usage_per_user: 1,
            valid_from: new Date('2020-01-01'),
            valid_till: new Date('2020-12-31'),
            is_active: true,
        },
        {
            code: 'CAPPED',
            description: '50% off capped at 20',
            discount_type: 'percentage',
            discount_value: 50,
            max_discount: 20,
            min_order_value: 0,
            usage_limit: 100,
            usage_per_user: 1,
            valid_from: new Date('2020-01-01'),
            valid_till: new Date('2030-12-31'),
            is_active: true,
        },
    ]
    for (const def of defs) {
        const existing = await prisma.coupon.findFirst({ where: { code: def.code } })
        if (!existing) {
            await prisma.coupon.create({ data: def })
        }
    }
    console.log('Coupons ensured (WASH10, FLAT50, EXPIRED, CAPPED)')
}

async function main() {
    console.log('🌱 Seeding (idempotent, catalogue-safe)...')

    await seedCatalogueIfEmpty()
    await seedLaundryConfig()
    await seedAdmin()
    await seedManagers()
    await seedServiceMen()
    await seedDeliveryStaff()
    await seedCustomer()
    await seedCoupons()
    await seedAppConfig()

    console.log('🎉 Seeding complete')
}

async function seedAppConfig() {
    const { seedDefaults } = require('../src/services/config.service')
    await seedDefaults()
    console.log('AppConfig keys ensured')
}

main()
    .catch((e) => {
        console.error('❌ Seed failed:', e)
        process.exit(1)
    })
    .finally(async () => {
        await prisma.$disconnect()
    })
