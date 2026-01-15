const { Prisma, OrderStatus } = require('@prisma/client');
const prisma = require('../config/database');
const { NotFoundError, ValidationError } = require('../utils/errors');

/**
 * Create an order from a customer's active cart.
 * Converts cart items to order items, handling both per_unit and per_kg pricing.
 * After order creation, marks the cart as inactive and deletes cart items.
 *
 * Pricing rules:
 * - If ANY cart item is per_kg, the whole order pricing_model is per_kg.
 * - For per_kg orders, weight can be uploaded later (pickup-time), so weight_kg is optional at creation.
 * - For per_unit orders, bill is generated immediately at order creation.
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
        // If ANY item is per_kg, the overall order pricing_model is per_kg.
        // Otherwise it's per_unit.
        const hasPerKgItem = cart.cart_items.some((item) => item.pricing_type === 'per_kg');
        const pricingModel = hasPerKgItem ? 'per_kg' : 'per_unit';

        const Decimal = Prisma.Decimal;
        let totalAmount = new Decimal(0);
        const orderItemsToCreate = [];

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
                }

                // Use the first cloth item's price as unit_price (or calculate average)
                // For per_unit, we'll use the weighted average or first item's price
                const firstClothPrice = new Decimal(item_selections[0].cloth_item.per_unit_price);

                // Create order item for this cart item
                // If order pricing_model is per_kg, we intentionally keep monetary totals at 0
                // until bill generation (after pickup weight upload).
                const effectiveSubtotal =
                    pricingModel === 'per_kg' ? new Decimal(0) : cartItemSubtotal;

                orderItemsToCreate.push({
                    service_id: service.service_id,
                    pricing_type: 'per_unit',
                    clothes_id: item_selections[0].cloth_id, // Reference to first cloth item
                    quantity: cartItemQuantity,
                    weight_kg: null,
                    unit_price: firstClothPrice, // Average or representative price
                    subtotal: effectiveSubtotal,
                });

                totalAmount = totalAmount.plus(effectiveSubtotal);
            } else if (pricing_type === 'per_kg') {
                // Per-kg pricing:
                // - weight is OPTIONAL at creation (will be filled by pickup staff later)
                // - service must support per_kg pricing
                if (!service.per_kg_price) {
                    throw new ValidationError(
                        `Service ${service.service_id} does not support per_kg pricing`
                    );
                }

                const pricePerKg = new Decimal(service.per_kg_price);
                const weightDecimal =
                    weight_kg && Number(weight_kg) > 0 ? new Decimal(weight_kg) : null;
                const computedSubtotal = weightDecimal ? weightDecimal.mul(pricePerKg) : new Decimal(0);
                const effectiveSubtotal =
                    pricingModel === 'per_kg' ? new Decimal(0) : computedSubtotal;

                // Create order item for this cart item
                orderItemsToCreate.push({
                    service_id: service.service_id,
                    pricing_type: 'per_kg',
                    clothes_id: null, // No specific cloth item for per_kg
                    quantity: null, // No quantity count for per_kg
                    weight_kg: weightDecimal,
                    unit_price: pricePerKg,
                    subtotal: effectiveSubtotal,
                });

                totalAmount = totalAmount.plus(effectiveSubtotal);
            } else {
                throw new ValidationError(`Invalid pricing_type: ${pricing_type}`);
            }
        }

        // Set dates (optional; can be updated later)
        const pickupDate = pickup_date ? new Date(pickup_date) : null;
        const deliveryDateValue = delivery_date ? new Date(delivery_date) : null;

        // Create order draft
        const order = await tx.order.create({
            data: {
                customer_id: customerId,
                order_status: OrderStatus.draft,
                pricing_model: pricingModel,
                order_type: order_type,
                pickup_address_id,
                delivery_address_id,
                pickup_date: pickupDate,
                delivery_date: deliveryDateValue,
                special_instructions: special_instructions || null,
                // For per_kg orders, total_amount must be filled only after bill creation.
                total_amount: pricingModel === 'per_kg' ? new Decimal(0) : totalAmount,
                billing_status: pricingModel === 'per_unit' ? 'generated' : 'pending',
            },
            select: {
                order_id: true,
                pickup_address_id: true,
                delivery_address_id: true,
                pricing_model: true,
                order_type: true,
                total_amount: true,
                billing_status: true,
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

        // Generate bill immediately only for per_unit orders.
        // For per_kg orders, bill is generated later once weight is updated by pickup staff.
        if (pricingModel === 'per_unit') {
            await tx.bill.create({
                data: {
                    order_id: order.order_id,
                    subtotal: totalAmount,
                    delivery_fee: new Decimal(0),
                    tax_amount: new Decimal(0),
                    discount: new Decimal(0),
                    final_amount: totalAmount,
                    // No payment method is selected at this stage in current API payload.
                    // Using a placeholder value keeps the schema satisfied; it can be updated later.
                    payment_method: 'pending',
                },
                select: { bill_id: true },
            });
        }

        return {
            order_id: order.order_id,
            pickup_address_id: order.pickup_address_id,
            delivery_address_id: order.delivery_address_id,
            pricing_model: order.pricing_model,
            order_type: order.order_type,
            total_amount: order.total_amount.toString(),
            billing_status: order.billing_status,
            items_count: createdOrderItems.length,
        };
    });
};

/**
 * Confirm an order draft.
 * After confirmation:
 * - order_status becomes 'placed'
 * - customer's active cart (and items) are deleted
 *
 * Note:
 * - per_unit orders must already have a generated bill
 * - per_kg orders can be confirmed without a bill
 */
exports.confirmOrder = async (customerId, orderId) => {
    if (!orderId) {
        throw new ValidationError('orderId is required');
    }

    return prisma.$transaction(async (tx) => {
        const order = await tx.order.findFirst({
            where: {
                order_id: orderId,
                customer_id: customerId,
            },
            select: {
                order_id: true,
                order_status: true,
                pricing_model: true,
                billing_status: true,
                total_amount: true,
            },
        });

        if (!order) {
            throw new NotFoundError('Order');
        }

        if (order.order_status !== OrderStatus.draft) {
            throw new ValidationError(`Only draft orders can be confirmed. Current status: ${order.order_status}`);
        }

        if (order.pricing_model === 'per_unit') {
            if (order.billing_status !== 'generated') {
                throw new ValidationError('Bill must be generated before confirming a per_unit order');
            }

            const bill = await tx.bill.findUnique({
                where: { order_id: order.order_id },
                select: { final_amount: true },
            });

            if (!bill) {
                throw new ValidationError('Bill must be generated before confirming a per_unit order');
            }

            // Ensure order.total_amount reflects bill final_amount
            await tx.order.update({
                where: { order_id: order.order_id },
                data: { total_amount: bill.final_amount },
                select: { order_id: true },
            });
        }

        const updated = await tx.order.update({
            where: { order_id: order.order_id },
            data: { order_status: OrderStatus.placed },
            select: {
                order_id: true,
                order_status: true,
                pricing_model: true,
                billing_status: true,
                total_amount: true,
            },
        });

        // Delete the customer's active cart (latest). Cart items/selections cascade delete.
        const activeCart = await tx.cart.findFirst({
            where: { customer_id: customerId, is_active: true },
            orderBy: { updated_at: 'desc' },
            select: { cart_id: true },
        });

        if (activeCart) {
            await tx.cart.delete({ where: { cart_id: activeCart.cart_id } });
        }

        return {
            order_id: updated.order_id,
            order_status: updated.order_status,
            pricing_model: updated.pricing_model,
            billing_status: updated.billing_status,
            total_amount: updated.total_amount.toString(),
        };
    });
};

module.exports = exports;
