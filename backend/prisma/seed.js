import { PrismaClient } from '@prisma/client'
import bcrypt from 'bcrypt'

const prisma = new PrismaClient()

async function main() {
    console.log('🌱 Starting database seed...')

    // Create a sample laundry mart
    const mart = await prisma.laundryMart.create({
        data: {
            mart_name: 'Downtown Laundry',
            contact_email: 'downtown@laundryapp.com',
            contact_phone: '+1234567890',
            address: '123 Main St, Downtown, City',
            latitude: 40.7128,
            longitude: -74.006,
            service_radius_km: {
                '0-5': { price_per_km: 20 },
                '5-10': { price_per_km: 40 },
                '10-15': { price_per_km: 60 },
            },
            is_active: true,
        },
    })
    console.log('✅ Created mart:', mart.mart_name)

    // Create admin user
    const hashedPassword = await bcrypt.hash('admin123', 10)
    const user = await prisma.user.create({
        data: {
            mart_id: mart.mart_id,
            full_name: 'Admin User',
            email: 'admin@laundryapp.com',
            phone: '+1234567891',
            password: hashedPassword,
            role: 'admin',
            is_active: true,
        },
    })
    console.log('✅ Created user:', user.email)

    // Create service categories
    const regularWash = await prisma.serviceCategory.create({
        data: {
            category_name: 'Regular Wash',
            description: 'Standard laundry services',
            display_order: 1,
            is_active: true,
        },
    })

    const proClean = await prisma.serviceCategory.create({
        data: {
            category_name: 'Pro Clean',
            description: 'Professional cleaning services',
            display_order: 2,
            is_active: true,
        },
    })
    console.log('✅ Created service categories')

    // Create services
    await prisma.service.createMany({
        data: [
            {
                category_id: regularWash.category_id,
                mart_id: mart.mart_id,
                service_name: 'Wash & Fold',
                description: 'Basic washing and folding service',
                base_price: 100,
                per_kg_price: 50,
                estimated_hours: 24,
                is_active: true,
                display_order: 1,
            },
            {
                category_id: regularWash.category_id,
                mart_id: mart.mart_id,
                service_name: 'Wash & Iron',
                description: 'Washing with ironing service',
                base_price: 150,
                per_kg_price: 75,
                estimated_hours: 48,
                is_active: true,
                display_order: 2,
            },
            {
                category_id: proClean.category_id,
                mart_id: mart.mart_id,
                service_name: 'Dry Clean',
                description: 'Professional dry cleaning',
                base_price: 200,
                estimated_hours: 72,
                is_active: true,
                display_order: 1,
            },
        ],
    })
    console.log('✅ Created services')

    // Create clothes items
    await prisma.clothesItem.createMany({
        data: [
            { item_name: 'Shirt', per_unit_price: 40, display_order: 1 },
            { item_name: 'Pants', per_unit_price: 50, display_order: 2 },
            { item_name: 'T-Shirt', per_unit_price: 30, display_order: 3 },
            { item_name: 'Dress', per_unit_price: 80, display_order: 4 },
            { item_name: 'Jacket', per_unit_price: 100, display_order: 5 },
            { item_name: 'Bed Sheet', per_unit_price: 60, display_order: 6 },
        ],
    })
    console.log('✅ Created clothes items')

    // Create sample customer
    const customer = await prisma.customer.create({
        data: {
            full_name: 'John Doe',
            email: 'john@example.com',
            phone: '+1234567892',
            password: await bcrypt.hash('customer123', 10),
            is_active: true,
        },
    })
    console.log('✅ Created customer:', customer.full_name)

    // Create customer address
    await prisma.customerAddress.create({
        data: {
            customer_id: customer.customer_id,
            address_label: 'home',
            full_address: '456 Oak Avenue, Suburb, City',
            latitude: 40.7589,
            longitude: -73.9851,
            is_default: true,
        },
    })
    console.log('✅ Created customer address')

    // Create delivery staff
    await prisma.deliveryStaff.create({
        data: {
            mart_id: mart.mart_id,
            full_name: 'Delivery Partner',
            phone: '+1234567893',
            email: 'delivery@laundryapp.com',
            password: await bcrypt.hash('delivery123', 10),
            vehicle_type: 'bike',
            vehicle_number: 'ABC-1234',
            license_number: 'DL-123456',
            verification_status: 'approved',
            is_active: true,
        },
    })
    console.log('✅ Created delivery staff')

    console.log('🎉 Seed completed successfully!')
}

main()
    .catch((e) => {
        console.error('❌ Seed failed:', e)
        process.exit(1)
    })
    .finally(async () => {
        await prisma.$disconnect()
    })

