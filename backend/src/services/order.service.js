const { Prisma } = require('@prisma/client');
const prisma = require('../config/database');
const { NotFoundError, ValidationError } = require('../utils/errors');

/**
 * Create an order from a customer's active cart.
 * Converts cart items to order items, handling both per_unit and per_kg pricing.
 * After order creation, marks the cart as inactive and deletes cart items.
 *
 * @param {string} customerId - Customer ID creating the order
 * @param {object} payload - Order creation payload
 * @param {string} payload.cart_id - Active cart ID to convert to order
 * @param {string} payload.pickup_address_id - UUID of pickup address
 * @param {string} payload.delivery_address_id - UUID of delivery address
 * @param {string} payload.order_type - Order type (pickup_only, drop_only, both, express_delivery)
 * @param {string} [payload.pickup_date] - Optional pickup date (ISO string)
 * @param {string} [payload.delivery_date] - Optional delivery date (ISO string)
 * @param {string} [payload.special_instructions] - Optional special instructions
 * @returns {Promise<object>} Created order details
 */
exports.createOrder = async (customerId, payload) => {
    const {
        cart_id,
        pickup_address_id,
        delivery_address_id,
        order_type,
        pickup_date,
        delivery_date,
        special_instructions,
    } = payload;

    return prisma.$transaction(async (tx) => {
        // Validate customer exists
        const customer = await tx.customer.findUnique({
            where: { customer_id: customerId },
            select: { customer_id: true },
        });

        if (!customer) {
            throw new NotFoundError('Customer');
        }

        // Validate addresses belong to customer
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

        // Fetch active cart with all items and selections
        const cart = await tx.cart.findFirst({
            where: {
                cart_id: cart_id,
                customer_id: customerId,
                is_active: true,
            },
            include: {
                cart_items: {
                    include: {
                        service: {
                            include: {
                                category: {
                                    select: {
                                        category_id: true,
                                    },
                                },
                            },
                        },
                        item_selections: {
                            include: {
                                cloth_item: {
                                    select: {
                                        cloth_id: true,
                                        per_unit_price: true,
                                        is_active: true,
                                    },
                                },
                            },
                        },
                    },
                },
            },
        });

        if (!cart) {
            throw new NotFoundError('Active cart not found');
        }

        if (!cart.cart_items || cart.cart_items.length === 0) {
            throw new ValidationError('Cart is empty. Add items to cart before creating an order');
        }

        // Validate all services are active
        const inactiveServices = cart.cart_items.filter(
            (item) => !item.service || !item.service.is_active
        );
        if (inactiveServices.length > 0) {
            throw new ValidationError('One or more services in cart are inactive');
        }

        // Determine pricing model from cart items
        // If all items are per_unit, pricing_model is per_unit
        // If all items are per_kg, pricing_model is per_kg
        // If mixed, we'll use per_unit as default (or throw error - depends on business logic)
        const pricingTypes = new Set(cart.cart_items.map((item) => item.pricing_type));
        let pricingModel;
        if (pricingTypes.size === 1) {
            pricingModel = Array.from(pricingTypes)[0];
        } else {
            // Mixed pricing - for now, we'll allow it and set to per_unit
            // You can change this to throw an error if mixed pricing is not allowed
            pricingModel = 'per_unit';
        }

        const Decimal = Prisma.Decimal;
        let totalAmount = new Decimal(0);
        const orderItemsToCreate = [];
        const orderItemSelectionsToCreate = [];

        // Process each cart item and convert to order item
        for (const cartItem of cart.cart_items) {
            const { service, pricing_type, weight_kg, item_selections } = cartItem;

            if (pricing_type === 'per_unit') {
                // Per-unit pricing: validate selections exist
                if (!item_selections || item_selections.length === 0) {
                    throw new ValidationError(
                        `Cart item ${cartItem.cart_item_id} has per_unit pricing but no selections`
                    );
                }

                // Validate all cloth items are active
                const inactiveClothItems = item_selections.filter(
                    (sel) => !sel.cloth_item || !sel.cloth_item.is_active
                );
                if (inactiveClothItems.length > 0) {
                    throw new ValidationError('One or more cloth items in cart are inactive');
                }

                // Calculate total quantity and subtotal for this cart item
                let cartItemQuantity = 0;
                let cartItemSubtotal = new Decimal(0);

                for (const selection of item_selections) {
                    const quantity = selection.quantity;
                    const unitPrice = new Decimal(selection.cloth_item.per_unit_price);
                    const selectionSubtotal = unitPrice.mul(quantity);

                    cartItemQuantity += quantity;
                    cartItemSubtotal = cartItemSubtotal.plus(selectionSubtotal);

                    // Store selection for later creation
                    orderItemSelectionsToCreate.push({
                        cloth_id: selection.cloth_id,
                        quantity: quantity,
                    });
                }

                // Use the first cloth item's price as unit_price (or calculate average)
                // For per_unit, we'll use the weighted average or first item's price
                const firstClothPrice = new Decimal(item_selections[0].cloth_item.per_unit_price);

                // Create order item for this cart item
                orderItemsToCreate.push({
                    service_id: service.service_id,
                    pricing_type: 'per_unit',
                    clothes_id: item_selections[0].cloth_id, // Reference to first cloth item
                    quantity: cartItemQuantity,
                    weight_kg: null,
                    unit_price: firstClothPrice, // Average or representative price
                    subtotal: cartItemSubtotal,
                });

                totalAmount = totalAmount.plus(cartItemSubtotal);
            } else if (pricing_type === 'per_kg') {
                // Per-kg pricing: validate weight exists
                if (!weight_kg || weight_kg <= 0) {
                    throw new ValidationError(
                        `Cart item ${cartItem.cart_item_id} has per_kg pricing but no valid weight`
                    );
                }

                // Validate service has per_kg_price
                if (!service.per_kg_price) {
                    throw new ValidationError(
                        `Service ${service.service_id} does not support per_kg pricing`
                    );
                }

                const weightDecimal = new Decimal(weight_kg);
                const pricePerKg = new Decimal(service.per_kg_price);
                const cartItemSubtotal = weightDecimal.mul(pricePerKg);

                // Create order item for this cart item
                orderItemsToCreate.push({
                    service_id: service.service_id,
                    pricing_type: 'per_kg',
                    clothes_id: null, // No specific cloth item for per_kg
                    quantity: null, // No quantity count for per_kg
                    weight_kg: weightDecimal,
                    unit_price: pricePerKg,
                    subtotal: cartItemSubtotal,
                });

                totalAmount = totalAmount.plus(cartItemSubtotal);
            } else {
                throw new ValidationError(`Invalid pricing_type: ${pricing_type}`);
            }
        }

        // Set dates
        const pickupDate = pickup_date ? new Date(pickup_date) : new Date();
        const deliveryDateValue = delivery_date ? new Date(delivery_date) : pickupDate;

        // Create order
        const order = await tx.order.create({
            data: {
                customer_id: customerId,
                order_status: 'placed',
                pricing_model: pricingModel,
                order_type: order_type,
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
                total_amount: true,
            },
        });

        // Create order items and collect their IDs for selections
        const createdOrderItems = [];
        for (let i = 0; i < orderItemsToCreate.length; i++) {
            const orderItemData = orderItemsToCreate[i];
            const orderItem = await tx.orderItem.create({
                data: {
                    ...orderItemData,
                    order_id: order.order_id,
                },
                select: {
                    item_id: true,
                    pricing_type: true,
                },
            });
            createdOrderItems.push(orderItem);

            // Create order item selections for per_unit items
            if (orderItem.pricing_type === 'per_unit') {
                // Find the corresponding selections for this cart item
                const cartItem = cart.cart_items[i];
                if (cartItem.item_selections && cartItem.item_selections.length > 0) {
                    await tx.orderItemSelection.createMany({
                        data: cartItem.item_selections.map((selection) => ({
                            order_item_id: orderItem.item_id,
                            cloth_id: selection.cloth_id,
                            quantity: selection.quantity,
                        })),
                    });
                }
            }
        }

        // Mark cart as inactive and delete cart items (cascade will delete selections)
        await tx.cart.update({
            where: { cart_id: cart.cart_id },
            data: { is_active: false },
        });

        // Delete cart items (selections will be cascade deleted)
        await tx.cartItem.deleteMany({
            where: { cart_id: cart.cart_id },
        });

        return {
            order_id: order.order_id,
            pickup_address_id: order.pickup_address_id,
            delivery_address_id: order.delivery_address_id,
            pricing_model: order.pricing_model,
            order_type: order.order_type,
            total_amount: order.total_amount.toString(),
            items_count: createdOrderItems.length,
        };
    });
};

module.exports = exports;
