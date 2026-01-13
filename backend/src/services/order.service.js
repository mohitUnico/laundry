const { Prisma } = require('@prisma/client');
const prisma = require('../config/database');
const { NotFoundError, ValidationError } = require('../utils/errors');

/**
 * Create a draft order from a customer's active cart.
 * Converts cart items to order items, handling both per_unit and per_kg pricing.
 * Sets billing_status based on pricing types:
 * - If any item is per_kg: billing_status = pending
 * - If all items are per_unit: generates bill and sets billing_status = generated
 * After order creation, marks the cart as inactive and deletes cart items.
 * Order status is set to 'draft' until confirmed via confirmOrder endpoint.
 *
 * @param {string} customerId - Customer ID creating the order
 * @param {object} payload - Order creation payload
 * @param {string} payload.cart_id - Active cart ID to convert to order
 * @param {string} payload.pickup_address_id - UUID of pickup address
 * @param {string} payload.delivery_address_id - UUID of delivery address
 * @param {string} payload.order_type - Order type (pickup_only, drop_only, both, express_delivery)
 * @param {string} payload.preferred_pickup_slot_from - Preferred pickup slot start date and time (ISO 8601 format)
 * @param {string} payload.preferred_pickup_slot_to - Preferred pickup slot end date and time (ISO 8601 format)
 * @param {string} payload.preferred_delivery_slot_from - Preferred delivery slot start date and time (ISO 8601 format)
 * @param {string} payload.preferred_delivery_slot_to - Preferred delivery slot end date and time (ISO 8601 format)
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
        preferred_pickup_slot_from,
        preferred_pickup_slot_to,
        preferred_delivery_slot_from,
        preferred_delivery_slot_to,
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
        // Rule: if ANY item is per_kg => pricing_model = per_kg
        // Otherwise (all per_unit) => pricing_model = per_unit
        const hasPerKgCartItem = cart.cart_items.some((item) => item.pricing_type === 'per_kg');
        const pricingModel = hasPerKgCartItem ? 'per_kg' : 'per_unit';

        const Decimal = Prisma.Decimal;
        // Only calculate totals up-front when ALL items are per_unit.
        // If the order contains any per_kg item, amounts are unknown at this stage.
        let totalAmount = hasPerKgCartItem ? null : new Decimal(0);
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

                // Calculate total quantity (and subtotal only when all items are per_unit)
                let cartItemQuantity = 0;
                let cartItemSubtotal = hasPerKgCartItem ? null : new Decimal(0);

                for (const selection of item_selections) {
                    const quantity = selection.quantity;
                    const unitPrice = hasPerKgCartItem
                        ? null
                        : new Decimal(selection.cloth_item.per_unit_price);
                    const selectionSubtotal = unitPrice ? unitPrice.mul(quantity) : null;

                    cartItemQuantity += quantity;
                    if (cartItemSubtotal && selectionSubtotal) {
                        cartItemSubtotal = cartItemSubtotal.plus(selectionSubtotal);
                    }

                    // Store selection for later creation
                    orderItemSelectionsToCreate.push({
                        cloth_id: selection.cloth_id,
                        quantity: quantity,
                    });
                }

                // Use the first cloth item's price as unit_price (or calculate average)
                // For per_unit, we'll use the weighted average or first item's price
                const firstClothPrice = hasPerKgCartItem
                    ? null
                    : new Decimal(item_selections[0].cloth_item.per_unit_price);

                // Create order item for this cart item
                orderItemsToCreate.push({
                    service_id: service.service_id,
                    pricing_type: 'per_unit',
                    clothes_id: item_selections[0].cloth_id, // Reference to first cloth item
                    quantity: cartItemQuantity,
                    weight_kg: null,
                    unit_price: firstClothPrice, // Nullable when order contains any per_kg item
                    subtotal: cartItemSubtotal, // Nullable when order contains any per_kg item
                });

                if (totalAmount && cartItemSubtotal) {
                    totalAmount = totalAmount.plus(cartItemSubtotal);
                }
            } else if (pricing_type === 'per_kg') {
                // Validate service has per_kg_price
                if (!service.per_kg_price) {
                    throw new ValidationError(
                        `Service ${service.service_id} does not support per_kg pricing`
                    );
                }

                // For per_kg items at order creation time:
                // - Weight is not known yet (confirmed at pickup)
                // - Do NOT store any monetary amounts
                // - Keep weight_kg as null (even if cart provided a tentative value)
                const weightDecimal = null;
                const pricePerKg = null;
                const cartItemSubtotal = null;

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
            } else {
                throw new ValidationError(`Invalid pricing_type: ${pricing_type}`);
            }
        }

        // Set dates
        const pickupDate = pickup_date ? new Date(pickup_date) : new Date();
        const deliveryDateValue = delivery_date ? new Date(delivery_date) : pickupDate;

        // Parse preferred slot ranges as DateTime
        const preferredPickupSlotFrom = preferred_pickup_slot_from
            ? new Date(preferred_pickup_slot_from)
            : null;
        const preferredPickupSlotTo = preferred_pickup_slot_to
            ? new Date(preferred_pickup_slot_to)
            : null;
        const preferredDeliverySlotFrom = preferred_delivery_slot_from
            ? new Date(preferred_delivery_slot_from)
            : null;
        const preferredDeliverySlotTo = preferred_delivery_slot_to
            ? new Date(preferred_delivery_slot_to)
            : null;

        // Determine billing status based on pricing types
        // If any item is per_kg, billing_status = pending (bill generated after weighing)
        // If all items are per_unit, generate bill and set billing_status = generated
        const hasPerKgItems = orderItemsToCreate.some((item) => item.pricing_type === 'per_kg');
        let billingStatus = 'pending';
        let billData = null;

        if (!hasPerKgItems) {
            // All items are per_unit - generate bill immediately
            billingStatus = 'generated';

            // Calculate bill components (subtotal already calculated, add delivery fee, tax, etc.)
            const subtotal = totalAmount;
            const deliveryFee = new Decimal(0); // TODO: Calculate based on distance
            const taxAmount = new Decimal(0); // TODO: Calculate tax (e.g., 5% of subtotal)
            const discount = new Decimal(0); // TODO: Apply any discounts
            const finalAmount = subtotal.plus(deliveryFee).plus(taxAmount).minus(discount);

            billData = {
                subtotal: subtotal,
                delivery_fee: deliveryFee,
                tax_amount: taxAmount,
                discount: discount,
                final_amount: finalAmount,
                payment_method: 'pending', // Will be set during payment
                payment_status: 'pending',
            };
        }

        // Create order with draft status
        const order = await tx.order.create({
            data: {
                customer_id: customerId,
                source_cart_id: cart.cart_id,
                order_status: 'draft', // Draft status until confirmed
                pricing_model: pricingModel,
                order_type: order_type,
                pickup_address_id,
                delivery_address_id,
                pickup_date: pickupDate,
                delivery_date: deliveryDateValue,
                preferred_pickup_slot_from: preferredPickupSlotFrom,
                preferred_pickup_slot_to: preferredPickupSlotTo,
                preferred_delivery_slot_from: preferredDeliverySlotFrom,
                preferred_delivery_slot_to: preferredDeliverySlotTo,
                special_instructions: special_instructions || null,
                total_amount: totalAmount,
                billing_status: billingStatus,
            },
            select: {
                order_id: true,
                pickup_address_id: true,
                delivery_address_id: true,
                pricing_model: true,
                order_type: true,
                total_amount: true,
                billing_status: true,
                order_status: true,
            },
        });

        // Create bill if all items are per_unit
        if (billData) {
            await tx.bill.create({
                data: {
                    order_id: order.order_id,
                    ...billData,
                },
            });
        }

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

        // Mark cart as inactive so it can't be reused/modified for checkout again.
        // Cart + cart_items will be deleted ONLY when the order is confirmed.
        await tx.cart.update({
            where: { cart_id: cart.cart_id },
            data: { is_active: false },
        });

        return {
            order_id: order.order_id,
            pickup_address_id: order.pickup_address_id,
            delivery_address_id: order.delivery_address_id,
            pricing_model: order.pricing_model,
            order_type: order.order_type,
            total_amount: order.total_amount ? order.total_amount.toString() : null,
            billing_status: order.billing_status,
            order_status: order.order_status,
            items_count: createdOrderItems.length,
        };
    });
};

/**
 * Confirm a draft order, setting its status to 'placed'.
 * This endpoint finalizes the order and makes it ready for processing.
 *
 * @param {string} customerId - Customer ID confirming the order
 * @param {string} orderId - Order ID to confirm
 * @returns {Promise<object>} Confirmed order details
 */
exports.confirmOrder = async (customerId, orderId) => {
    return prisma.$transaction(async (tx) => {
        // Verify order exists and belongs to customer
        const order = await tx.order.findFirst({
            where: {
                order_id: orderId,
                customer_id: customerId,
            },
            select: {
                order_id: true,
                source_cart_id: true,
                order_status: true,
                billing_status: true,
            },
        });

        if (!order) {
            throw new NotFoundError('Order');
        }

        // Validate order is in draft status
        if (order.order_status !== 'draft') {
            throw new ValidationError(
                `Order cannot be confirmed. Current status: ${order.order_status}. Only draft orders can be confirmed.`
            );
        }

        // Update order status to 'placed'
        const confirmedOrder = await tx.order.update({
            where: { order_id: orderId },
            data: { order_status: 'placed' },
            select: {
                order_id: true,
                order_status: true,
                billing_status: true,
                total_amount: true,
                order_type: true,
            },
        });

        // After confirmation, delete the cart + cart_items + selections used for this order.
        // We use deleteMany to avoid throwing if the cart was already removed for some reason.
        if (order.source_cart_id) {
            await tx.cart.deleteMany({
                where: {
                    cart_id: order.source_cart_id,
                    customer_id: customerId,
                },
            });
        }

        return {
            order_id: confirmedOrder.order_id,
            order_status: confirmedOrder.order_status,
            billing_status: confirmedOrder.billing_status,
            total_amount: confirmedOrder.total_amount ? confirmedOrder.total_amount.toString() : null,
            order_type: confirmedOrder.order_type,
            message: 'Order confirmed successfully',
        };
    });
};

/**
 * List orders for a customer with optional status filter and pagination.
 *
 * @param {string} customerId
 * @param {object} options
 * @param {number} [options.page=1]
 * @param {number} [options.limit=10]
 * @param {string} [options.status] - OrderStatus filter
 * @returns {Promise<{orders: Array, pagination: object}>}
 */
exports.listOrders = async (customerId, options = {}) => {
    const page = Number.isFinite(Number(options.page)) ? Math.max(1, Number(options.page)) : 1;
    const limit = Number.isFinite(Number(options.limit)) ? Math.min(50, Math.max(1, Number(options.limit))) : 10;
    const skip = (page - 1) * limit;
    const status = options.status ? String(options.status) : null;

    const where = {
        customer_id: customerId,
        ...(status ? { order_status: status } : {}),
    };

    const [orders, total] = await Promise.all([
        prisma.order.findMany({
            where,
            orderBy: { created_at: 'desc' },
            skip,
            take: limit,
            select: {
                order_id: true,
                order_status: true,
                billing_status: true,
                pricing_model: true,
                order_type: true,
                total_amount: true,
                created_at: true,
                updated_at: true,
            },
        }),
        prisma.order.count({ where }),
    ]);

    return {
        orders: orders.map((o) => ({
            ...o,
            total_amount: o.total_amount ? o.total_amount.toString() : null,
        })),
        pagination: {
            page,
            limit,
            total,
            totalPages: Math.ceil(total / limit),
            hasNext: page * limit < total,
            hasPrev: page > 1,
        },
    };
};

/**
 * Get a single order by ID for a customer (includes items + selections).
 *
 * @param {string} customerId
 * @param {string} orderId
 * @returns {Promise<object>}
 */
exports.getOrderById = async (customerId, orderId) => {
    const order = await prisma.order.findFirst({
        where: {
            order_id: orderId,
            customer_id: customerId,
        },
        include: {
            bill: true,
            order_items: {
                include: {
                    service: {
                        select: {
                            service_id: true,
                            service_name: true,
                            per_kg_price: true,
                            base_price: true,
                        },
                    },
                    clothes: {
                        select: {
                            cloth_id: true,
                            item_name: true,
                            per_unit_price: true,
                        },
                    },
                    item_selections: {
                        include: {
                            cloth_item: {
                                select: {
                                    cloth_id: true,
                                    item_name: true,
                                    per_unit_price: true,
                                },
                            },
                        },
                    },
                },
            },
        },
    });

    if (!order) {
        throw new NotFoundError('Order');
    }

    return {
        ...order,
        total_amount: order.total_amount ? order.total_amount.toString() : null,
        order_items: order.order_items.map((item) => ({
            ...item,
            unit_price: item.unit_price ? item.unit_price.toString() : null,
            subtotal: item.subtotal ? item.subtotal.toString() : null,
            weight_kg: item.weight_kg ? item.weight_kg.toString() : null,
        })),
        bill: order.bill
            ? {
                ...order.bill,
                subtotal: order.bill.subtotal?.toString?.() ?? null,
                delivery_fee: order.bill.delivery_fee?.toString?.() ?? null,
                tax_amount: order.bill.tax_amount?.toString?.() ?? null,
                discount: order.bill.discount?.toString?.() ?? null,
                final_amount: order.bill.final_amount?.toString?.() ?? null,
            }
            : null,
    };
};

module.exports = exports;
