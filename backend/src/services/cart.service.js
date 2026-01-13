const prisma = require('../config/database');
const { NotFoundError, ValidationError } = require('../utils/errors');

/**
 * Add cart items into the customer's active cart.
 * If no active cart exists, create a new one and then add items.
 *
 * Payload shape (validated by Joi in route):
 * items: [
 *   {
 *     service_id: string(uuid),
 *     pricing_type: 'per_unit' | 'per_kg',
 *     selections?: [{ cloth_id: string(uuid), quantity: number }],
 *     weight_kg?: number
 *   }
 * ]
 */
exports.addItemsToActiveCart = async (customerId, { items }) => {
    return prisma.$transaction(
        async (tx) => {
            if (!Array.isArray(items) || items.length === 0) {
                throw new ValidationError('Cart items are required');
            }

            const customer = await tx.customer.findUnique({
                where: { customer_id: customerId },
                select: { customer_id: true },
            });

            if (!customer) {
                throw new NotFoundError('Customer');
            }

            let cart = await tx.cart.findFirst({
                where: { customer_id: customerId, is_active: true },
                orderBy: { updated_at: 'desc' },
                select: { cart_id: true },
            });

            if (!cart) {
                cart = await tx.cart.create({
                    data: {
                        customer_id: customerId,
                        is_active: true,
                    },
                    select: { cart_id: true },
                });
            }

            const uniqueServiceIds = Array.from(new Set(items.map((i) => i.service_id)));
            const serviceRecords = await tx.service.findMany({
                where: {
                    service_id: { in: uniqueServiceIds },
                    is_active: true,
                },
                select: { service_id: true },
            });

            if (serviceRecords.length !== uniqueServiceIds.length) {
                throw new ValidationError('One or more services are invalid or inactive');
            }

            const allowedServiceIds = new Set(serviceRecords.map((s) => s.service_id));

            // Preload existing cart items for this cart so we can merge instead of creating duplicates.
            // Keyed by `${service_id}:${pricing_type}`.
            const existingCartItems = await tx.cartItem.findMany({
                where: {
                    cart_id: cart.cart_id,
                    service_id: { in: uniqueServiceIds },
                },
                select: {
                    cart_item_id: true,
                    service_id: true,
                    pricing_type: true,
                    weight_kg: true,
                },
            });

            const cartItemByKey = new Map(
                existingCartItems.map((ci) => [`${ci.service_id}:${ci.pricing_type}`, ci])
            );

            // Return cart_item_ids that were created or updated by this call.
            const affectedCartItemIds = [];

            for (const item of items) {
                if (!item || typeof item !== 'object') {
                    throw new ValidationError('Invalid cart item payload');
                }

                if (!item.service_id) {
                    throw new ValidationError('service_id is required for each cart item');
                }

                if (!item.pricing_type || !['per_unit', 'per_kg'].includes(item.pricing_type)) {
                    throw new ValidationError('pricing_type must be per_unit or per_kg');
                }

                if (!allowedServiceIds.has(item.service_id)) {
                    throw new ValidationError(`Service ${item.service_id} is invalid or inactive`);
                }

                const selections = Array.isArray(item.selections) ? item.selections : [];

                // per_unit requires selections (counts). per_kg requires weight_kg.
                if (item.pricing_type === 'per_unit' && selections.length === 0) {
                    throw new ValidationError('selections are required when pricing_type is per_unit');
                }

                if (selections.length > 0) {
                    // Validate selection shape early
                    for (const selection of selections) {
                        if (!selection || typeof selection !== 'object') {
                            throw new ValidationError('Invalid selection payload');
                        }
                        if (!selection.cloth_id) {
                            throw new ValidationError('cloth_id is required for each selection');
                        }
                        if (!Number.isInteger(selection.quantity) || selection.quantity < 1) {
                            throw new ValidationError('quantity must be an integer >= 1 for each selection');
                        }
                    }

                    const uniqueClothIds = Array.from(new Set(selections.map((s) => s.cloth_id)));
                    const clothRecords = await tx.clothesItem.findMany({
                        where: {
                            cloth_id: { in: uniqueClothIds },
                            service_id: item.service_id,
                            is_active: true,
                        },
                        select: { cloth_id: true },
                    });

                    if (clothRecords.length !== uniqueClothIds.length) {
                        throw new ValidationError(
                            'One or more clothes items are invalid, inactive, or not part of the selected service'
                        );
                    }
                }

                const key = `${item.service_id}:${item.pricing_type}`;
                let cartItem = cartItemByKey.get(key);

                // Create cart item if it doesn't exist yet (merge behavior)
                if (!cartItem) {
                    cartItem = await tx.cartItem.create({
                        data: {
                            cart_id: cart.cart_id,
                            service_id: item.service_id,
                            pricing_type: item.pricing_type,
                            weight_kg: item.pricing_type === 'per_kg' ? item.weight_kg ?? null : null,
                        },
                        select: {
                            cart_item_id: true,
                            service_id: true,
                            pricing_type: true,
                            weight_kg: true,
                        },
                    });
                    cartItemByKey.set(key, cartItem);
                } else if (item.pricing_type === 'per_kg') {
                    // For per_kg, keep a single cart_item row and accumulate weight.
                    const existingWeight = cartItem.weight_kg ?? null;
                    const incomingWeight = item.weight_kg ?? null;

                    // Validator enforces weight_kg for per_kg, but keep this defensive.
                    if (incomingWeight !== null) {
                        const nextWeight =
                            existingWeight === null ? incomingWeight : Number(existingWeight) + Number(incomingWeight);

                        cartItem = await tx.cartItem.update({
                            where: { cart_item_id: cartItem.cart_item_id },
                            data: { weight_kg: nextWeight },
                            select: {
                                cart_item_id: true,
                                service_id: true,
                                pricing_type: true,
                                weight_kg: true,
                            },
                        });
                        cartItemByKey.set(key, cartItem);
                    }
                }

                affectedCartItemIds.push(cartItem.cart_item_id);

                // Merge selections into the same cart_item for per_unit (and any case where selections are provided)
                if (selections.length > 0) {
                    // Merge duplicates in the incoming payload itself (same cloth_id repeated)
                    const incomingQtyByClothId = new Map();
                    for (const s of selections) {
                        const prev = incomingQtyByClothId.get(s.cloth_id) ?? 0;
                        incomingQtyByClothId.set(s.cloth_id, prev + s.quantity);
                    }

                    const clothIds = Array.from(incomingQtyByClothId.keys());
                    const existingSelections = await tx.cartItemSelection.findMany({
                        where: {
                            cart_item_id: cartItem.cart_item_id,
                            cloth_id: { in: clothIds },
                        },
                        select: {
                            selection_id: true,
                            cloth_id: true,
                            quantity: true,
                        },
                    });

                    const existingByClothId = new Map(
                        existingSelections.map((s) => [s.cloth_id, { selection_id: s.selection_id, quantity: s.quantity }])
                    );

                    for (const [clothId, incQty] of incomingQtyByClothId.entries()) {
                        const existing = existingByClothId.get(clothId);
                        if (existing) {
                            await tx.cartItemSelection.update({
                                where: { selection_id: existing.selection_id },
                                data: { quantity: existing.quantity + incQty },
                            });
                        } else {
                            await tx.cartItemSelection.create({
                                data: {
                                    cart_item_id: cartItem.cart_item_id,
                                    cloth_id: clothId,
                                    quantity: incQty,
                                },
                            });
                        }
                    }

                    // Touch cart item updated_at for per_unit changes so clients can rely on ordering/sync.
                    await tx.cartItem.update({
                        where: { cart_item_id: cartItem.cart_item_id },
                        data: { updated_at: new Date() },
                        select: { cart_item_id: true },
                    });
                }
            }

            // Touch cart timestamp so clients can rely on updated_at for sync logic.
            await tx.cart.update({
                where: { cart_id: cart.cart_id },
                data: { updated_at: new Date() },
                select: { cart_id: true },
            });

            return {
                cart_id: cart.cart_id,
                added_cart_item_ids: affectedCartItemIds,
            };
        },
        {
            // Increase interactive transaction timeout to avoid P2028 for larger payloads / slower DB.
            timeout: 15000,
        }
    );
};

exports.getCustomerCarts = async (customerId) => {
    const customer = await prisma.customer.findUnique({
        where: { customer_id: customerId },
        select: { customer_id: true },
    });

    if (!customer) {
        throw new NotFoundError('Customer');
    }

    const carts = await prisma.cart.findMany({
        where: { customer_id: customerId },
        orderBy: { created_at: 'desc' },
        include: {
            cart_items: {
                orderBy: { created_at: 'desc' },
                include: {
                    service: {
                        select: {
                            service_id: true,
                            service_name: true,
                            base_price: true,
                            per_kg_price: true,
                            icon_url: true,
                            is_active: true,
                        },
                    },
                    item_selections: {
                        include: {
                            cloth_item: {
                                select: {
                                    cloth_id: true,
                                    item_name: true,
                                    per_unit_price: true,
                                    icon_url: true,
                                    is_active: true,
                                },
                            },
                        },
                    },
                },
            },
        },
    });

    return carts;
};

exports.updateSelectionQuantity = async (customerId, cartItemId, selectionId, delta) => {
    if (!cartItemId || !selectionId) {
        throw new ValidationError('cartItemId and selectionId are required');
    }

    if (![1, -1].includes(delta)) {
        throw new ValidationError('delta must be +1 or -1');
    }

    return prisma.$transaction(
        async (tx) => {
            // Ensure selection belongs to the given cartItem AND to the authenticated customer
            const selection = await tx.cartItemSelection.findFirst({
                where: {
                    selection_id: selectionId,
                    cart_item_id: cartItemId,
                    cart_item: {
                        cart: {
                            customer_id: customerId,
                        },
                    },
                },
                select: {
                    selection_id: true,
                    quantity: true,
                    cart_item_id: true,
                    cart_item: { select: { cart_id: true } },
                },
            });

            if (!selection) {
                throw new NotFoundError('Cart item selection');
            }

            const nextQuantity = selection.quantity + delta;

            if (nextQuantity < 1) {
                await tx.cartItemSelection.delete({
                    where: { selection_id: selection.selection_id },
                });
            } else {
                await tx.cartItemSelection.update({
                    where: { selection_id: selection.selection_id },
                    data: { quantity: nextQuantity },
                });
            }

            await tx.cart.update({
                where: { cart_id: selection.cart_item.cart_id },
                data: { updated_at: new Date() },
                select: { cart_id: true },
            });

            return {
                cart_item_id: selection.cart_item_id,
                selection_id: selection.selection_id,
                quantity: Math.max(nextQuantity, 0),
                deleted: nextQuantity < 1,
            };
        },
        {
            timeout: 15000,
        }
    );
};

exports.removeCartItem = async (customerId, cartItemId) => {
    if (!cartItemId) {
        throw new ValidationError('cartItemId is required');
    }

    return prisma.$transaction(
        async (tx) => {
            const cartItem = await tx.cartItem.findFirst({
                where: {
                    cart_item_id: cartItemId,
                    cart: { customer_id: customerId },
                },
                select: { cart_item_id: true, cart_id: true },
            });

            if (!cartItem) {
                throw new NotFoundError('Cart item');
            }

            await tx.cartItem.delete({
                where: { cart_item_id: cartItem.cart_item_id },
            });

            await tx.cart.update({
                where: { cart_id: cartItem.cart_id },
                data: { updated_at: new Date() },
                select: { cart_id: true },
            });

            return {
                cart_item_id: cartItem.cart_item_id,
                deleted: true,
            };
        },
        {
            timeout: 15000,
        }
    );
};

module.exports = exports;


