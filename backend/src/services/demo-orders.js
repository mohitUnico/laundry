const prisma = require('../config/database')

async function seedDemoOrders(customer) {
    const marker = await prisma.order.findFirst({
        where: {
            customer_id: customer.customer_id,
            special_instructions: { startsWith: 'seed-demo:' },
        },
    })
    if (marker) {
        console.log('Demo orders already present')
        return
    }

    let home = await prisma.customerAddress.findFirst({
        where: { customer_id: customer.customer_id },
        orderBy: [{ is_default: 'desc' }, { created_at: 'asc' }],
    })
    if (!home) {
        const sample = await prisma.customerAddress.findFirst({ orderBy: { created_at: 'asc' } })
        if (!sample) {
            console.log('Demo orders skipped: no address to copy')
            return
        }
        home = await prisma.customerAddress.create({
            data: {
                customer_id: customer.customer_id,
                address_label: 'home',
                full_address: sample.full_address,
                latitude: sample.latitude,
                longitude: sample.longitude,
                is_default: true,
            },
        })
    }

    const services = await prisma.service.findMany({
        where: { is_active: true },
        include: {
            clothes_items: {
                where: { is_active: true },
                orderBy: { display_order: 'asc' },
                take: 3,
            },
        },
        orderBy: { display_order: 'asc' },
    })
    const withClothes = services.filter((service) => service.clothes_items.length > 0)
    const primary = withClothes[0]
    const secondary = withClothes.find((service) => service.service_id !== primary?.service_id)
    const perKg = services.find(
        (service) => service.per_kg_price != null && service.service_id !== primary?.service_id
    )

    const now = new Date()
    const inHours = (hours) => new Date(now.getTime() + hours * 60 * 60 * 1000)

    async function createBare(def) {
        return prisma.order.create({
            data: {
                customer_id: customer.customer_id,
                order_status: def.status,
                is_express: Boolean(def.express),
                pickup_mode: def.pickupMode,
                delivery_mode: def.deliveryMode || 'scheduled',
                pickup_address_id: home.address_id,
                delivery_address_id: home.address_id,
                pickup_time_from: def.from || null,
                pickup_time_to: def.to || null,
                delivery_time_from: def.deliveryFrom || null,
                delivery_time_to: def.deliveryTo || null,
                special_instructions: def.note,
                cancel_reason: def.cancelReason || null,
                cancelled_at: def.status === 'cancelled' ? now : null,
                total_amount: 0,
                items_confirmed_at: def.confirmed ? now : null,
            },
        })
    }

    async function addPerUnit(orderId, service, lines) {
        let subtotal = 0
        const selections = lines.map((line) => {
            const price = Number(line.cloth.per_unit_price)
            subtotal += price * line.qty
            return { cloth: line.cloth, qty: line.qty, price }
        })
        const item = await prisma.orderItem.create({
            data: {
                order_id: orderId,
                service_id: service.service_id,
                pricing_type: 'per_unit',
                clothes_id: selections[0].cloth.cloth_id,
                quantity: selections.reduce((sum, row) => sum + row.qty, 0),
                unit_price: selections[0].price,
                subtotal,
            },
        })
        await prisma.orderItemSelection.createMany({
            data: selections.map((row) => ({
                order_item_id: item.item_id,
                cloth_id: row.cloth.cloth_id,
                quantity: row.qty,
                unit_price: row.price,
            })),
        })
        return subtotal
    }

    async function addBill(orderId, subtotal, { paid = false, express = 0 } = {}) {
        const delivery = 40
        const tax = Math.round(subtotal * 0.05)
        const finalAmount = subtotal + delivery + tax + express
        await prisma.bill.create({
            data: {
                order_id: orderId,
                subtotal,
                delivery_fee: delivery,
                tax_amount: tax,
                express_fee: express,
                discount: 0,
                final_amount: finalAmount,
                payment_status: paid ? 'completed' : 'pending',
                payment_method: paid ? 'upi' : null,
                paid_at: paid ? now : null,
            },
        })
        await prisma.order.update({
            where: { order_id: orderId },
            data: { total_amount: finalAmount },
        })
    }

    await createBare({
        status: 'placed',
        pickupMode: 'instant',
        deliveryMode: 'instant',
        note: 'seed-demo:instant-placed',
    })
    await createBare({
        status: 'placed',
        pickupMode: 'scheduled',
        from: inHours(26),
        to: inHours(27.5),
        deliveryFrom: inHours(74),
        deliveryTo: inHours(75.5),
        note: 'seed-demo:scheduled-placed',
    })
    await createBare({
        status: 'pickup_assigned',
        pickupMode: 'scheduled',
        from: inHours(18),
        to: inHours(19.5),
        deliveryFrom: inHours(66),
        deliveryTo: inHours(67.5),
        note: 'seed-demo:pickup-assigned',
    })

    if (primary) {
        const picked = await createBare({
            status: 'picked_up',
            pickupMode: 'scheduled',
            from: inHours(-3),
            to: inHours(-2),
            deliveryFrom: inHours(45),
            deliveryTo: inHours(46.5),
            note: 'seed-demo:picked-up',
            confirmed: true,
        })
        const pickedSub = await addPerUnit(picked.order_id, primary, [
            { cloth: primary.clothes_items[0], qty: 2 },
            { cloth: primary.clothes_items[1] || primary.clothes_items[0], qty: 1 },
        ])
        await addBill(picked.order_id, pickedSub)

        const progress = await createBare({
            status: 'services_in_progress',
            express: true,
            pickupMode: 'scheduled',
            from: inHours(-20),
            to: inHours(-19),
            deliveryFrom: inHours(28),
            deliveryTo: inHours(29.5),
            note: 'seed-demo:in-progress',
            confirmed: true,
        })
        let progressSub = await addPerUnit(progress.order_id, primary, [
            { cloth: primary.clothes_items[0], qty: 3 },
        ])
        if (secondary) {
            progressSub += await addPerUnit(progress.order_id, secondary, [
                { cloth: secondary.clothes_items[0], qty: 2 },
            ])
        }
        if (perKg && perKg.service_id !== secondary?.service_id) {
            const weight = 2.5
            const price = Number(perKg.per_kg_price)
            const kgSub = Math.round(weight * price)
            await prisma.orderItem.create({
                data: {
                    order_id: progress.order_id,
                    service_id: perKg.service_id,
                    pricing_type: 'per_kg',
                    weight_kg: weight,
                    unit_price: price,
                    subtotal: kgSub,
                },
            })
            progressSub += kgSub
        }
        await addBill(progress.order_id, progressSub, { express: 49 })

        const delivered = await createBare({
            status: 'delivered',
            pickupMode: 'scheduled',
            from: inHours(-96),
            to: inHours(-95),
            deliveryFrom: inHours(-50),
            deliveryTo: inHours(-49),
            note: 'seed-demo:delivered',
            confirmed: true,
        })
        const deliveredSub = await addPerUnit(delivered.order_id, primary, [
            { cloth: primary.clothes_items[0], qty: 4 },
        ])
        await addBill(delivered.order_id, deliveredSub, { paid: true })
    }

    await createBare({
        status: 'cancelled',
        pickupMode: 'instant',
        deliveryMode: 'instant',
        note: 'seed-demo:cancelled',
        cancelReason: 'Change of plans',
    })

    console.log(`Demo orders created for ${customer.email}`)
}


module.exports = { seedDemoOrders }
