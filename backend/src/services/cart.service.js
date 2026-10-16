const prisma = require('../config/database');
const { NotFoundError, ValidationError } = require('../utils/errors');
const { isServiceBookable, assertBookable } = require('./catalogue-rules');

function mapCartItem(item, check) {
    return {
        cart_item_id: item.cart_item_id,
        service_id: item.service_id,
        pricing_type: item.pricing_type,
        available: check ? check.bookable : true,
        unavailableReason: check && !check.bookable ? check.reasons : [],
        service: item.service
            ? {
                  service_id: item.service.service_id,
                  service_name: item.service.service_name,
                  per_kg_price: item.service.per_kg_price != null ? String(item.service.per_kg_price) : null,
                  category: item.service.category
                      ? {
                            category_id: item.service.category.category_id,
                            category_name: item.service.category.category_name,
                        }
                      : null,
              }
            : null,
    };
}

const cartItemInclude = {
    service: {
        include: {
            category: { select: { category_id: true, category_name: true, is_active: true } },
        },
    },
};

async function getOrCreateActiveCart(tx, customerId) {
    const customer = await tx.customer.findUnique({
        where: { customer_id: customerId },
        select: { customer_id: true },
    });
    if (!customer) throw new NotFoundError('Customer');

    let cart = await tx.cart.findFirst({
        where: { customer_id: customerId, is_active: true },
        orderBy: { updated_at: 'desc' },
        select: { cart_id: true },
    });
    if (!cart) {
        cart = await tx.cart.create({
            data: { customer_id: customerId, is_active: true },
            select: { cart_id: true },
        });
    }
    return cart;
}

exports.addItemsToActiveCart = async (customerId, { items }) => {
    if (!Array.isArray(items) || items.length === 0) {
        throw new ValidationError('Cart items are required');
    }

    return prisma.$transaction(async (tx) => {
        const cart = await getOrCreateActiveCart(tx, customerId);
        const processed = [];

        for (const item of items) {
            if (!item?.service_id || !['per_unit', 'per_kg'].includes(item.pricing_type)) {
                throw new ValidationError('Each item needs service_id and pricing_type (per_unit|per_kg)');
            }
            const check = await isServiceBookable(item.service_id, item.pricing_type, { tx });
            assertBookable(check, item.service_id);

            const line = await tx.cartItem.upsert({
                where: {
                    cart_id_service_id: {
                        cart_id: cart.cart_id,
                        service_id: item.service_id,
                    },
                },
                create: {
                    cart_id: cart.cart_id,
                    service_id: item.service_id,
                    pricing_type: item.pricing_type,
                },
                update: {
                    pricing_type: item.pricing_type,
                },
            });
            processed.push(line.cart_item_id);
        }

        const full = await tx.cart.findUnique({
            where: { cart_id: cart.cart_id },
            include: { cart_items: { include: cartItemInclude } },
        });

        return {
            cart_id: cart.cart_id,
            processed_cart_item_ids: processed,
            cart_items: (full.cart_items || []).map(mapCartItem),
        };
    });
};

exports.updateCartItemPricingType = async (customerId, cartItemId, pricingType) => {
    if (!['per_unit', 'per_kg'].includes(pricingType)) {
        throw new ValidationError('pricing_type must be per_unit or per_kg');
    }
    const item = await prisma.cartItem.findFirst({
        where: { cart_item_id: cartItemId, cart: { customer_id: customerId, is_active: true } },
    });
    if (!item) throw new NotFoundError('Cart item');

    const check = await isServiceBookable(item.service_id, pricingType);
    assertBookable(check, item.service_id);

    const updated = await prisma.cartItem.update({
        where: { cart_item_id: cartItemId },
        data: { pricing_type: pricingType },
        include: cartItemInclude,
    });
    return mapCartItem(updated);
};

exports.getCustomerCarts = async (customerId) => {
    const carts = await prisma.cart.findMany({
        where: { customer_id: customerId },
        orderBy: { updated_at: 'desc' },
        include: { cart_items: { include: cartItemInclude } },
    });
    return Promise.all(
        carts.map(async (cart) => ({
            cart_id: cart.cart_id,
            is_active: cart.is_active,
            created_at: cart.created_at,
            updated_at: cart.updated_at,
            items: await Promise.all(
                (cart.cart_items || []).map(async (item) =>
                    mapCartItem(item, await isServiceBookable(item.service_id, item.pricing_type))
                )
            ),
        }))
    );
};

exports.removeCartItem = async (customerId, cartItemId) => {
    const item = await prisma.cartItem.findFirst({
        where: { cart_item_id: cartItemId, cart: { customer_id: customerId } },
    });
    if (!item) throw new NotFoundError('Cart item');
    await prisma.cartItem.delete({ where: { cart_item_id: cartItemId } });
    return { deleted: true, cart_item_id: cartItemId };
};
