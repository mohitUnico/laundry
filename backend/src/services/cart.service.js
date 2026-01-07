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
    return prisma.$transaction(async (tx) => {
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

        const createdCartItemIds = [];

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

            // per_unit requires selections (counts). per_kg can optionally include selections to keep counts.
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

            const cartItem = await tx.cartItem.create({
                data: {
                    cart_id: cart.cart_id,
                    service_id: item.service_id,
                    pricing_type: item.pricing_type,
                    weight_kg: item.pricing_type === 'per_kg' ? item.weight_kg ?? null : null,
                },
                select: { cart_item_id: true },
            });

            createdCartItemIds.push(cartItem.cart_item_id);

            if (selections.length > 0) {
                await tx.cartItemSelection.createMany({
                    data: selections.map((s) => ({
                        cart_item_id: cartItem.cart_item_id,
                        cloth_id: s.cloth_id,
                        quantity: s.quantity,
                    })),
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
            added_cart_item_ids: createdCartItemIds,
        };
    });
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

module.exports = exports;


