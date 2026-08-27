const { Prisma, OrderStatus, PaymentStatus } = require('@prisma/client');
const prisma = require('../config/database');
const { NotFoundError, ValidationError } = require('../utils/errors');
const { notifyOrderStatusChange } = require('./fcm.service');
const { schedulePickupAssignment, cancelPickupAssignment } = require('../queues/pickup-assignment.queue');

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
        pickup_time_from,
        pickup_time_to,
        delivery_time_from,
        delivery_time_to,
        // Backward-compatible aliases (some clients send these)
        preferred_pickup_slot_from,
        preferred_pickup_slot_to,
        preferred_delivery_slot_from,
        preferred_delivery_slot_to,
        special_instructions,
    } = payload;

    // Interactive transaction default timeout can be too low for complex order creation (P2028).
    // Increase timeout to avoid Prisma closing the transaction mid-operation.
    const result = await prisma.$transaction(
        async (tx) => {
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
            // First try to find cart with provided cart_id, then fall back to customer's active cart
            let cart = await tx.cart.findFirst({
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

            // If cart with provided cart_id not found, try to find customer's active cart
            if (!cart) {
                cart = await tx.cart.findFirst({
                    where: {
                        customer_id: customerId,
                        is_active: true,
                    },
                    orderBy: { updated_at: 'desc' }, // Get most recently updated active cart
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
            }

            if (!cart) {
                throw new NotFoundError('Active cart not found. Please add items to cart before creating an order');
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

            // Set dates / preferred time windows (optional; can be updated later)
            // Parse ISO 8601 date strings (from frontend) and ensure they're stored correctly
            // The frontend sends UTC ISO strings, which we parse and store as-is
            let pickupDate = null;
            let deliveryDateValue = null;
            let pickupTimeFrom = null;
            let pickupTimeTo = null;
            let deliveryTimeFrom = null;
            let deliveryTimeTo = null;

            if (pickup_date) {
                const parsed = new Date(pickup_date);
                // Validate the date is valid
                if (isNaN(parsed.getTime())) {
                    throw new ValidationError('Invalid pickup_date format. Must be a valid ISO 8601 date string');
                }
                pickupDate = parsed;
            }

            if (delivery_date) {
                const parsed = new Date(delivery_date);
                // Validate the date is valid
                if (isNaN(parsed.getTime())) {
                    throw new ValidationError('Invalid delivery_date format. Must be a valid ISO 8601 date string');
                }
                deliveryDateValue = parsed;
            }

            const parseOptionalDate = (label, v) => {
                if (!v) return null;
                const parsed = new Date(v);
                if (isNaN(parsed.getTime())) {
                    throw new ValidationError(`Invalid ${label} format. Must be a valid ISO 8601 date string`);
                }
                return parsed;
            };

            pickupTimeFrom = parseOptionalDate('pickup_time_from', pickup_time_from);
            pickupTimeTo = parseOptionalDate('pickup_time_to', pickup_time_to);
            deliveryTimeFrom = parseOptionalDate('delivery_time_from', delivery_time_from);
            deliveryTimeTo = parseOptionalDate('delivery_time_to', delivery_time_to);

            // Alias fallback (defensive; middleware also normalizes)
            if (!pickupTimeFrom && preferred_pickup_slot_from) {
                pickupTimeFrom = parseOptionalDate('preferred_pickup_slot_from', preferred_pickup_slot_from);
            }
            if (!pickupTimeTo && preferred_pickup_slot_to) {
                pickupTimeTo = parseOptionalDate('preferred_pickup_slot_to', preferred_pickup_slot_to);
            }
            if (!deliveryTimeFrom && preferred_delivery_slot_from) {
                deliveryTimeFrom = parseOptionalDate('preferred_delivery_slot_from', preferred_delivery_slot_from);
            }
            if (!deliveryTimeTo && preferred_delivery_slot_to) {
                deliveryTimeTo = parseOptionalDate('preferred_delivery_slot_to', preferred_delivery_slot_to);
            }

            if (pickupTimeFrom && pickupTimeTo && pickupTimeFrom > pickupTimeTo) {
                throw new ValidationError('pickup_time_from must be <= pickup_time_to');
            }
            if (deliveryTimeFrom && deliveryTimeTo && deliveryTimeFrom > deliveryTimeTo) {
                throw new ValidationError('delivery_time_from must be <= delivery_time_to');
            }

            // Backward-compat: if only old fields are provided, treat them as the window "from"
            if (!pickupTimeFrom && pickupDate) pickupTimeFrom = pickupDate;
            if (!deliveryTimeFrom && deliveryDateValue) deliveryTimeFrom = deliveryDateValue;

            // Create order directly as placed (draft/confirm flow removed)
            const order = await tx.order.create({
                data: {
                    customer_id: customerId,
                    cart_id: cart.cart_id,
                    order_status: OrderStatus.placed,
                    pricing_model: pricingModel,
                    order_type: order_type,
                    pickup_address_id,
                    delivery_address_id,
                    pickup_date: pickupDate,
                    delivery_date: deliveryDateValue,
                    pickup_time_from: pickupTimeFrom,
                    pickup_time_to: pickupTimeTo,
                    delivery_time_from: deliveryTimeFrom,
                    delivery_time_to: deliveryTimeTo,
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
                    pickup_time_from: true,
                    pickup_time_to: true,
                    delivery_time_from: true,
                    delivery_time_to: true,
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

                // Create order item selections for both per_unit and per_kg items
                // Both can have selections (cloth items) that need to be preserved
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
                        // Payment method and status will be updated when payment is processed
                        payment_method: 'pending',
                        payment_status: PaymentStatus.pending, // Use Prisma enum value
                    },
                    select: { bill_id: true },
                });
            }

            // Create delivery legs immediately after order is placed.
            // Delivery leg structure:
            // - pickupForDelivery stores pickup coordinates only
            // - dropForDelivery stores drop coordinates only
            const laundry = await tx.laundryConfig.findFirst({
                where: { is_active: true },
                orderBy: { created_at: 'desc' },
                select: { address: true, latitude: true, longitude: true },
            });
            if (!laundry) throw new NotFoundError('LaundryConfig');

            const [pickupAddress, deliveryAddress] = await tx.customerAddress.findMany({
                where: { address_id: { in: [pickup_address_id, delivery_address_id] } },
                select: { address_id: true, full_address: true, latitude: true, longitude: true },
            }).then((rows) => {
                const pickup = rows.find((r) => r.address_id === pickup_address_id);
                const drop = rows.find((r) => r.address_id === delivery_address_id);
                return [pickup, drop];
            });

            if (!pickupAddress || !deliveryAddress) {
                throw new ValidationError('Invalid pickup or delivery address');
            }

            const needsWeightMachine = pricingModel === 'per_kg';

            const preferredPickupFrom = order.pickup_time_from || pickupDate || null;
            const preferredPickupTo = order.pickup_time_to || null;
            const preferredDropFrom = order.delivery_time_from || deliveryDateValue || null;
            const preferredDropTo = order.delivery_time_to || null;

            const createDeliveryWithLegs = async ({ deliveryType, pickup, drop }) => {
                // Idempotency: if create_order is retried, don't create duplicate deliveries for the same leg.
                let createdDelivery = await tx.delivery.findFirst({
                    where: { order_id: order.order_id, delivery_type: deliveryType },
                    orderBy: { created_at: 'desc' },
                    select: { delivery_id: true },
                });

                if (!createdDelivery) {
                    createdDelivery = await tx.delivery.create({
                        data: {
                            order_id: order.order_id,
                            staff_id: null,
                            delivery_type: deliveryType,
                            delivery_status: 'unassigned',
                            delivery_fee: new Decimal(0),
                            needs_weight_machine: needsWeightMachine,
                        },
                        select: { delivery_id: true },
                    });
                }

                await tx.pickupForDelivery.upsert({
                    where: { delivery_id: createdDelivery.delivery_id },
                    create: {
                        delivery_id: createdDelivery.delivery_id,
                        pickup_address: pickup.address,
                        pickup_lat: pickup.latitude,
                        pickup_lng: pickup.longitude,
                        pickup_status: 'unassigned',
                        preferred_pickup_from: preferredPickupFrom,
                        preferred_pickup_to: preferredPickupTo,
                    },
                    update: {
                        pickup_address: pickup.address,
                        pickup_lat: pickup.latitude,
                        pickup_lng: pickup.longitude,
                        preferred_pickup_from: preferredPickupFrom,
                        preferred_pickup_to: preferredPickupTo,
                    },
                });

                await tx.dropForDelivery.upsert({
                    where: { delivery_id: createdDelivery.delivery_id },
                    create: {
                        delivery_id: createdDelivery.delivery_id,
                        drop_address: drop.address,
                        drop_lat: drop.latitude,
                        drop_lng: drop.longitude,
                        drop_status: 'unassigned',
                        preferred_drop_from: preferredDropFrom,
                        preferred_drop_to: preferredDropTo,
                    },
                    update: {
                        drop_address: drop.address,
                        drop_lat: drop.latitude,
                        drop_lng: drop.longitude,
                        preferred_drop_from: preferredDropFrom,
                        preferred_drop_to: preferredDropTo,
                    },
                });
            };

            if (order_type === 'pickup_only') {
                // pickup-only: pickup = customer, drop = laundry
                await createDeliveryWithLegs({
                    deliveryType: 'pickup',
                    pickup: {
                        address: pickupAddress.full_address,
                        latitude: pickupAddress.latitude,
                        longitude: pickupAddress.longitude,
                    },
                    drop: {
                        address: laundry.address,
                        latitude: laundry.latitude,
                        longitude: laundry.longitude,
                    },
                });
            } else if (order_type === 'drop_only') {
                // drop-only: pickup = laundry, drop = customer
                await createDeliveryWithLegs({
                    deliveryType: 'drop',
                    pickup: {
                        address: laundry.address,
                        latitude: laundry.latitude,
                        longitude: laundry.longitude,
                    },
                    drop: {
                        address: deliveryAddress.full_address,
                        latitude: deliveryAddress.latitude,
                        longitude: deliveryAddress.longitude,
                    },
                });
            } else {
                // both / express_delivery: create both legs
                // pickup leg: customer -> laundry
                await createDeliveryWithLegs({
                    deliveryType: 'pickup',
                    pickup: {
                        address: pickupAddress.full_address,
                        latitude: pickupAddress.latitude,
                        longitude: pickupAddress.longitude,
                    },
                    drop: {
                        address: laundry.address,
                        latitude: laundry.latitude,
                        longitude: laundry.longitude,
                    },
                });
                // drop leg: laundry -> customer
                await createDeliveryWithLegs({
                    deliveryType: 'drop',
                    pickup: {
                        address: laundry.address,
                        latitude: laundry.latitude,
                        longitude: laundry.longitude,
                    },
                    drop: {
                        address: deliveryAddress.full_address,
                        latitude: deliveryAddress.latitude,
                        longitude: deliveryAddress.longitude,
                    },
                });
            }

            // Delete the cart associated with this order. Cart items/selections cascade delete.
            if (order.cart_id) {
                await tx.cart.delete({ where: { cart_id: order.cart_id } });
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
        },
        { maxWait: 10000, timeout: 60000 } // Increase timeout to 60 seconds for complex order creation
    );

    // Schedule pickup assignment job if queue-based assignment is enabled
    // Only schedule if order requires pickup and has pickup_time_from set
    if (process.env.PICKUP_ASSIGNMENT_USE_QUEUE === 'true') {
        const createdOrder = await prisma.order.findUnique({
            where: { order_id: result.order_id },
            select: {
                order_id: true,
                order_status: true,
                order_type: true,
                pickup_time_from: true,
            },
        });

        if (
            createdOrder &&
            createdOrder.order_status === 'placed' &&
            createdOrder.pickup_time_from &&
            (createdOrder.order_type === 'pickup_only' || createdOrder.order_type === 'both')
        ) {
            try {
                await schedulePickupAssignment(createdOrder.order_id, createdOrder.pickup_time_from);
            } catch (error) {
                // Log error but don't fail order creation
                const logger = require('../utils/logger');
                logger.error('Failed to schedule pickup assignment job after order creation', {
                    component: 'order-service',
                    orderId: createdOrder.order_id,
                    error: error.message,
                });
            }
        }
    }

    return result;
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

    const result = await prisma.$transaction(async (tx) => {
        const order = await tx.order.findFirst({
            where: {
                order_id: orderId,
                customer_id: customerId,
            },
            select: {
                order_id: true,
                cart_id: true,
                order_status: true,
                pricing_model: true,
                billing_status: true,
                total_amount: true,
                order_type: true,
                pickup_date: true,
                delivery_date: true,
                pickup_time_from: true,
                pickup_time_to: true,
                delivery_time_from: true,
                delivery_time_to: true,
                pickup_address: {
                    select: { full_address: true, latitude: true, longitude: true },
                },
                delivery_address: {
                    select: { full_address: true, latitude: true, longitude: true },
                },
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

        // Create delivery legs immediately after order is placed.
        // This ensures downstream delivery-ops endpoints can rely on delivery + pickup/drop rows existing.
        const laundry = await tx.laundryConfig.findFirst({
            where: { is_active: true },
            orderBy: { created_at: 'desc' },
            select: { address: true, latitude: true, longitude: true },
        });
        if (!laundry) {
            throw new NotFoundError('LaundryConfig');
        }

        const billFee = await tx.bill.findUnique({
            where: { order_id: order.order_id },
            select: { delivery_fee: true },
        });

        const needsWeightMachine = !!(await tx.orderItem.findFirst({
            where: { order_id: order.order_id, pricing_type: 'per_kg' },
            select: { item_id: true },
        }));

        const existingDeliveries = await tx.delivery.findMany({
            where: { order_id: order.order_id },
            select: { delivery_id: true, delivery_type: true },
        });
        const hasPickup = existingDeliveries.some((d) => d.delivery_type === 'pickup');
        const hasDrop = existingDeliveries.some((d) => d.delivery_type === 'drop');

        const preferredPickupFrom = order.pickup_time_from || order.pickup_date || null;
        const preferredPickupTo = order.pickup_time_to || null;
        const preferredDropFrom = order.delivery_time_from || order.delivery_date || null;
        const preferredDropTo = order.delivery_time_to || null;

        const createPickupLeg = async () => {
            const delivery = await tx.delivery.create({
                data: {
                    order_id: order.order_id,
                    staff_id: null,
                    delivery_type: 'pickup',
                    delivery_status: 'unassigned',
                    delivery_fee: (billFee?.delivery_fee != null) ? billFee.delivery_fee : new Prisma.Decimal(0),
                    needs_weight_machine: needsWeightMachine,
                },
                select: { delivery_id: true },
            });

            await tx.pickupForDelivery.create({
                data: {
                    delivery_id: delivery.delivery_id,
                    pickup_address: order.pickup_address.full_address,
                    pickup_lat: order.pickup_address.latitude,
                    pickup_lng: order.pickup_address.longitude,
                    pickup_status: 'unassigned',
                    preferred_pickup_from: preferredPickupFrom,
                    preferred_pickup_to: preferredPickupTo,
                },
                select: { pickup_id: true },
            });

            // Store drop details in drop_for_delivery (not in pickup_for_delivery)
            await tx.dropForDelivery.create({
                data: {
                    delivery_id: delivery.delivery_id,
                    drop_address: laundry.address,
                    drop_lat: laundry.latitude,
                    drop_lng: laundry.longitude,
                    drop_status: 'unassigned',
                    preferred_drop_from: preferredDropFrom,
                    preferred_drop_to: preferredDropTo,
                },
                select: { drop_id: true },
            });
        };

        const createDropLeg = async () => {
            const delivery = await tx.delivery.create({
                data: {
                    order_id: order.order_id,
                    staff_id: null,
                    delivery_type: 'drop',
                    delivery_status: 'unassigned',
                    delivery_fee: (billFee?.delivery_fee != null) ? billFee.delivery_fee : new Prisma.Decimal(0),
                    needs_weight_machine: needsWeightMachine,
                },
                select: { delivery_id: true },
            });

            // Store pickup details in pickup_for_delivery (not in drop_for_delivery)
            await tx.pickupForDelivery.create({
                data: {
                    delivery_id: delivery.delivery_id,
                    pickup_address: laundry.address,
                    pickup_lat: laundry.latitude,
                    pickup_lng: laundry.longitude,
                    pickup_status: 'unassigned',
                    preferred_pickup_from: preferredPickupFrom,
                    preferred_pickup_to: preferredPickupTo,
                },
                select: { pickup_id: true },
            });

            await tx.dropForDelivery.create({
                data: {
                    delivery_id: delivery.delivery_id,
                    drop_address: order.delivery_address.full_address,
                    drop_lat: order.delivery_address.latitude,
                    drop_lng: order.delivery_address.longitude,
                    drop_status: 'unassigned',
                    preferred_drop_from: preferredDropFrom,
                    preferred_drop_to: preferredDropTo,
                },
                select: { drop_id: true },
            });
        };

        if (order.order_type === 'pickup_only') {
            if (!hasPickup) await createPickupLeg();
        } else if (order.order_type === 'drop_only') {
            if (!hasDrop) await createDropLeg();
        } else {
            // both / express_delivery
            if (!hasPickup) await createPickupLeg();
            if (!hasDrop) await createDropLeg();
        }

        // Delete the cart associated with this order. Cart items/selections cascade delete.
        if (order.cart_id) {
            await tx.cart.delete({ where: { cart_id: order.cart_id } });
        }

        return {
            order_id: updated.order_id,
            order_status: updated.order_status,
            pricing_model: updated.pricing_model,
            billing_status: updated.billing_status,
            total_amount: updated.total_amount.toString(),
        };
    });

    // Notify customer via FCM and WhatsApp (fire-and-forget)
    notifyOrderStatusChange({ orderId: result.order_id, status: result.order_status }).catch(() => {});
    // Schedule pickup assignment job if queue-based assignment is enabled
    // Only schedule if order requires pickup and has pickup_time_from set
    if (process.env.PICKUP_ASSIGNMENT_USE_QUEUE === 'true') {
        const confirmedOrder = await prisma.order.findUnique({
            where: { order_id: result.order_id },
            select: {
                order_id: true,
                order_status: true,
                order_type: true,
                pickup_time_from: true,
            },
        });

        if (
            confirmedOrder &&
            confirmedOrder.order_status === 'placed' &&
            confirmedOrder.pickup_time_from &&
            (confirmedOrder.order_type === 'pickup_only' || confirmedOrder.order_type === 'both')
        ) {
            try {
                await schedulePickupAssignment(confirmedOrder.order_id, confirmedOrder.pickup_time_from);
            } catch (error) {
                // Log error but don't fail order confirmation
                const logger = require('../utils/logger');
                logger.error('Failed to schedule pickup assignment job after order confirmation', {
                    component: 'order-service',
                    orderId: confirmedOrder.order_id,
                    error: error.message,
                });
            }
        }
    }

    return result;
};

/**
 * Get orders for a customer with pagination and status filter
 * @param {string} customerId - Customer ID
 * @param {object} query - Query parameters
 * @param {number} query.page - Page number (default: 1)
 * @param {number} query.limit - Items per page (default: 10)
 * @param {string} query.status - Order status filter (optional)
 * @returns {Promise<object>} Orders list with pagination
 */
exports.getCustomerOrders = async (customerId, query = {}) => {
    const { page = 1, limit = 10, status } = query;

    const safePage = Number.isInteger(page) ? page : parseInt(page);
    const safeLimit = Number.isInteger(limit) ? limit : parseInt(limit);

    if (!Number.isInteger(safePage) || safePage < 1) {
        throw new ValidationError('page must be >= 1');
    }
    if (!Number.isInteger(safeLimit) || safeLimit < 1 || safeLimit > 100) {
        throw new ValidationError('limit must be between 1 and 100');
    }

    const skip = (safePage - 1) * safeLimit;

    // Handle special status filters
    let where;
    if (status === 'active') {
        // Active orders: all orders except delivered, closed, cancelled, and draft
        // These are the statuses that should NOT appear in active orders
        where = {
            customer_id: customerId,
            order_status: {
                notIn: ['delivered', 'closed', 'cancelled', 'draft'],
            },
        };
    } else if (status === 'completed') {
        // Completed orders: delivered or closed (cancelled orders are not considered completed)
        where = {
            customer_id: customerId,
            order_status: {
                in: ['delivered', 'closed'],
            },
        };
    } else {
        // Specific status or all orders
        where = {
            customer_id: customerId,
            ...(status ? { order_status: status } : {}),
        };
    }

    const [total, orders] = await Promise.all([
        prisma.order.count({ where }),
        prisma.order.findMany({
            where,
            skip,
            take: safeLimit,
            orderBy: { created_at: 'desc' },
            select: {
                order_id: true,
                order_status: true,
                pricing_model: true,
                order_type: true,
                total_amount: true,
                billing_status: true,
                pickup_time_from: true,
                pickup_time_to: true,
                delivery_time_from: true,
                delivery_time_to: true,
                pickup_address: {
                    select: {
                        address_id: true,
                        full_address: true,
                        latitude: true,
                        longitude: true,
                    },
                },
                pickup_date: true,
                delivery_date: true,
                created_at: true,
                updated_at: true,
                order_items: {
                    select: {
                        item_id: true,
                        pricing_type: true,
                        quantity: true,
                        weight_kg: true,
                        service: {
                            select: {
                                service_id: true,
                                service_name: true,
                                category: {
                                    select: {
                                        category_id: true,
                                        category_name: true,
                                    },
                                },
                            },
                        },
                        item_selections: {
                            select: {
                                selection_id: true,
                                quantity: true,
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
                bill: {
                    select: {
                        bill_id: true,
                        final_amount: true,
                        payment_method: true,
                        payment_status: true,
                    },
                },
            },
        }),
    ]);

    const totalPages = Math.ceil(total / safeLimit);

    return {
        orders: orders.map((order) => ({
            order_id: order.order_id,
            order_status: order.order_status,
            pricing_model: order.pricing_model,
            order_type: order.order_type,
            total_amount: order.total_amount.toString(),
            billing_status: order.billing_status,
            pickup_address: order.pickup_address
                ? {
                    address_id: order.pickup_address.address_id,
                    full_address: order.pickup_address.full_address,
                    latitude: order.pickup_address.latitude,
                    longitude: order.pickup_address.longitude,
                }
                : null,
            pickup_time_from: order.pickup_time_from,
            pickup_time_to: order.pickup_time_to,
            delivery_time_from: order.delivery_time_from,
            delivery_time_to: order.delivery_time_to,
            pickup_date: order.pickup_date,
            delivery_date: order.delivery_date,
            created_at: order.created_at,
            updated_at: order.updated_at,
            items_count: order.order_items.length,
            items: order.order_items.map((item) => {
                // Get service info from order_item.service (fallback) or from first selection
                const serviceFromItem = item.service;
                const serviceNameFromItem = serviceFromItem?.service_name || '';
                const categoryNameFromItem = serviceFromItem?.category?.category_name || '';

                // Map selections, using service info from item as fallback
                const selections = (item.item_selections || []).map((sel) => ({
                    selection_id: sel.selection_id,
                    quantity: sel.quantity,
                    cloth_name: sel.cloth_item?.item_name || '',
                    service_name: sel.cloth_item?.service?.service_name || serviceNameFromItem,
                    category_name: sel.cloth_item?.service?.category?.category_name || categoryNameFromItem,
                    per_unit_price: sel.cloth_item?.per_unit_price
                        ? sel.cloth_item.per_unit_price.toString()
                        : null,
                }));

                return {
                    item_id: item.item_id,
                    pricing_type: item.pricing_type,
                    quantity: item.quantity,
                    weight_kg: item.weight_kg?.toString() || null,
                    service_name: serviceNameFromItem, // Include service name at item level
                    category_name: categoryNameFromItem, // Include category name at item level
                    selections: selections,
                };
            }),
            bill: order.bill ? {
                bill_id: order.bill.bill_id,
                final_amount: order.bill.final_amount.toString(),
                payment_method: order.bill.payment_method,
                payment_status: order.bill.payment_status,
            } : null,
        })),
        pagination: {
            page: safePage,
            limit: safeLimit,
            total,
            total_pages: totalPages,
            has_next: safePage < totalPages,
            has_prev: safePage > 1,
        },
    };
};

exports.getOrderTrackingForCustomer = async ({ customerId, orderId }) => {
    if (!customerId) throw new ValidationError('customerId is required');
    if (!orderId) throw new ValidationError('orderId is required');

    const order = await prisma.order.findFirst({
        where: { order_id: orderId, customer_id: customerId },
        select: {
            order_id: true,
            order_status: true,
            order_type: true,
            pickup_address: {
                select: { full_address: true, latitude: true, longitude: true },
            },
            delivery_address: {
                select: { full_address: true, latitude: true, longitude: true },
            },
        },
    });

    if (!order) throw new NotFoundError('Order');

    const laundry = await prisma.laundryConfig.findFirst({
        where: { is_active: true },
        orderBy: { created_at: 'desc' },
        select: {
            config_id: true,
            business_name: true,
            address: true,
            latitude: true,
            longitude: true,
        },
    });

    if (!laundry) throw new NotFoundError('LaundryConfig');

    const deliveries = await prisma.delivery.findMany({
        where: { order_id: orderId },
        orderBy: { created_at: 'desc' },
        select: {
            delivery_id: true,
            delivery_type: true,
            delivery_status: true,
            staff_id: true,
            staff: {
                select: {
                    staff_id: true,
                    full_name: true,
                    current_latitude: true,
                    current_longitude: true,
                },
            },
        },
    });

    const pickupDelivery = deliveries.find((d) => d.delivery_type === 'pickup') || null;
    const dropDelivery = deliveries.find((d) => d.delivery_type === 'drop') || null;

    const mapDelivery = (d) => {
        if (!d) return null;
        return {
            deliveryId: d.delivery_id,
            deliveryType: d.delivery_type,
            deliveryStatus: d.delivery_status,
            staffId: d.staff_id || null,
            staff: d.staff
                ? {
                    staffId: d.staff.staff_id,
                    fullName: d.staff.full_name,
                    latitude: d.staff.current_latitude,
                    longitude: d.staff.current_longitude,
                }
                : null,
        };
    };

    return {
        orderId: order.order_id,
        orderStatus: order.order_status,
        orderType: order.order_type,
        shop: {
            name: laundry.business_name,
            address: laundry.address,
            latitude: laundry.latitude,
            longitude: laundry.longitude,
        },
        pickup: order.pickup_address
            ? {
                address: order.pickup_address.full_address,
                latitude: order.pickup_address.latitude,
                longitude: order.pickup_address.longitude,
            }
            : null,
        delivery: order.delivery_address
            ? {
                address: order.delivery_address.full_address,
                latitude: order.delivery_address.latitude,
                longitude: order.delivery_address.longitude,
            }
            : null,
        deliveries: {
            pickup: mapDelivery(pickupDelivery),
            drop: mapDelivery(dropDelivery),
        },
    };
};

module.exports = exports;
