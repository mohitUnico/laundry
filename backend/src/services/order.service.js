const { Prisma } = require('@prisma/client');
const prisma = require('../config/database');
const { NotFoundError, ValidationError } = require('../utils/errors');

exports.createOrder = async (customerId, payload) => {
    const {
        items,
        pickup_address_id,
        delivery_address_id,
        pricing_model,
        order_type,
        pickup_date,
        delivery_date,
        special_instructions,
    } = payload;

    return prisma.$transaction(async (tx) => {
        const customer = await tx.customer.findUnique({
            where: { customer_id: customerId },
            select: { customer_id: true },
        });

        if (!customer) {
            throw new NotFoundError('Customer');
        }

        const uniqueAddressIds = Array.from(new Set([pickup_address_id, delivery_address_id]));
        const addressRecords = await tx.customerAddress.findMany({
            where: {
                customer_id: customerId,
                address_id: { in: uniqueAddressIds },
            },
            select: { address_id: true },
        });

        if (addressRecords.length !== uniqueAddressIds.length) {
            throw new ValidationError('Invalid pickup or delivery address');
        }

        const clothIds = items.map((item) => item.cloth_id);
        const clothRecords = await tx.clothesItem.findMany({
            where: { cloth_id: { in: clothIds } },
            include: {
                service: { select: { mart_id: true } },
            },
        });

        if (clothRecords.length !== clothIds.length) {
            throw new ValidationError('One or more cloth items are invalid or inactive');
        }

        const martId = clothRecords[0].service.mart_id;
        const inconsistentMart = clothRecords.some((record) => record.service.mart_id !== martId);
        if (inconsistentMart) {
            throw new ValidationError('All cloth items must belong to the same mart');
        }

        const clothMap = new Map(clothRecords.map((record) => [record.cloth_id, record]));
        const Decimal = Prisma.Decimal;
        let totalAmount = new Decimal(0);

        const orderItemsData = items.map((item) => {
            const cloth = clothMap.get(item.cloth_id);
            if (!cloth) {
                throw new ValidationError(`Cloth item ${item.cloth_id} is not associated with this mart`);
            }

            const quantityDecimal = new Decimal(item.quantity);
            const unitPrice = cloth.per_unit_price;
            const subtotal = unitPrice.mul(quantityDecimal);
            totalAmount = totalAmount.plus(subtotal);

            return {
                clothes_id: cloth.cloth_id,
                quantity: item.quantity,
                unit_price: unitPrice,
                subtotal,
            };
        });

        const pickupDate = pickup_date ? new Date(pickup_date) : new Date();
        const deliveryDateValue = delivery_date ? new Date(delivery_date) : pickupDate;

        const order = await tx.order.create({
            data: {
                customer_id: customerId,
                mart_id: martId,
                order_status: 'pending',
                pricing_model,
                order_type,
                pickup_address_id,
                delivery_address_id,
                pickup_date: pickupDate,
                delivery_date: deliveryDateValue,
                special_instructions: special_instructions || null,
                total_amount: totalAmount,
            },
            select: {
                order_id: true,
                pickup_address_id: true,
                delivery_address_id: true,
                pricing_model: true,
                order_type: true,
            },
        });

        await tx.orderItem.createMany({
            data: orderItemsData.map((item) => ({
                ...item,
                order_id: order.order_id,
            })),
        });

        const itemsList = orderItemsData.map((item) => ({
            cloth_id: item.clothes_id,
            order_id: order.order_id,
            quantity: item.quantity,
        }));

        return {
            items_list: itemsList,
            pickup_address_id: order.pickup_address_id,
            delivery_address_id: order.delivery_address_id,
            pricing_model: order.pricing_model,
            order_type: order.order_type,
        };
    });
};

module.exports = exports;
