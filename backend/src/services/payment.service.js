const { Prisma, PaymentStatus } = require('@prisma/client');
const prisma = require('../config/database');
const { NotFoundError, ValidationError } = require('../utils/errors');

/**
 * Process payment for an order by updating the bill.
 * Updates payment_method, transaction_id, payment_status, and paid_at.
 *
 * @param {string} customerId - Customer ID
 * @param {string} orderId - Order ID
 * @param {object} paymentData - Payment details
 * @param {string} paymentData.payment_method - Payment method (card, cod, upi, wallet)
 * @param {string} [paymentData.transaction_id] - Transaction ID from payment gateway
 * @param {string} [paymentData.payment_status] - Payment status (pending, completed, failed)
 * @returns {Promise<object>} Updated bill details
 */
exports.processPayment = async (customerId, orderId, paymentData) => {
    const { payment_method, transaction_id, payment_status = 'completed' } = paymentData;

    if (!payment_method) {
        throw new ValidationError('Payment method is required');
    }

    // Validate payment method
    const validPaymentMethods = ['card', 'cod', 'upi', 'wallet', 'pending'];
    if (!validPaymentMethods.includes(payment_method)) {
        throw new ValidationError(`Invalid payment method. Must be one of: ${validPaymentMethods.join(', ')}`);
    }

    // Validate payment status
    const validStatuses = ['pending', 'completed', 'failed', 'refunded'];
    if (!validStatuses.includes(payment_status)) {
        throw new ValidationError(`Invalid payment status. Must be one of: ${validStatuses.join(', ')}`);
    }

    return prisma.$transaction(async (tx) => {
        // Verify order belongs to customer
        const order = await tx.order.findFirst({
            where: {
                order_id: orderId,
                customer_id: customerId,
            },
            select: {
                order_id: true,
                pricing_model: true,
            },
        });

        if (!order) {
            throw new NotFoundError('Order');
        }

        // Find or create bill
        let bill = await tx.bill.findUnique({
            where: { order_id: orderId },
        });

        if (!bill) {
            // For per_kg orders, bill might not exist yet
            // Create a placeholder bill with pending status
            bill = await tx.bill.create({
                data: {
                    order_id: orderId,
                    subtotal: new Prisma.Decimal(0),
                    delivery_fee: new Prisma.Decimal(0),
                    tax_amount: new Prisma.Decimal(0),
                    discount: new Prisma.Decimal(0),
                    final_amount: new Prisma.Decimal(0),
                    payment_method: payment_method,
                    payment_status: PaymentStatus.pending,
                },
            });
        }

        // Update bill with payment details
        const updateData = {
            payment_method: payment_method,
            payment_status: PaymentStatus[payment_status],
        };

        if (transaction_id) {
            updateData.transaction_id = transaction_id;
        }

        // Set paid_at timestamp if payment is completed
        if (payment_status === 'completed') {
            updateData.paid_at = new Date();
        } else if (payment_status === 'pending' || payment_status === 'failed') {
            // Clear paid_at if payment is pending or failed
            updateData.paid_at = null;
        }

        const updatedBill = await tx.bill.update({
            where: { bill_id: bill.bill_id },
            data: updateData,
            select: {
                bill_id: true,
                order_id: true,
                subtotal: true,
                delivery_fee: true,
                tax_amount: true,
                discount: true,
                final_amount: true,
                payment_method: true,
                payment_status: true,
                transaction_id: true,
                paid_at: true,
                created_at: true,
                updated_at: true,
            },
        });

        return {
            bill_id: updatedBill.bill_id,
            order_id: updatedBill.order_id,
            subtotal: updatedBill.subtotal.toString(),
            delivery_fee: updatedBill.delivery_fee.toString(),
            tax_amount: updatedBill.tax_amount.toString(),
            discount: updatedBill.discount.toString(),
            final_amount: updatedBill.final_amount.toString(),
            payment_method: updatedBill.payment_method,
            payment_status: updatedBill.payment_status,
            transaction_id: updatedBill.transaction_id,
            paid_at: updatedBill.paid_at?.toISOString() || null,
            created_at: updatedBill.created_at.toISOString(),
            updated_at: updatedBill.updated_at.toISOString(),
        };
    });
};

/**
 * Get bill/payment details for an order.
 *
 * @param {string} customerId - Customer ID
 * @param {string} orderId - Order ID
 * @returns {Promise<object|null>} Bill details or null if not found
 */
exports.getBillByOrderId = async (customerId, orderId) => {
    // Verify order belongs to customer
    const order = await prisma.order.findFirst({
        where: {
            order_id: orderId,
            customer_id: customerId,
        },
        select: {
            order_id: true,
        },
    });

    if (!order) {
        throw new NotFoundError('Order');
    }

    const bill = await prisma.bill.findUnique({
        where: { order_id: orderId },
        select: {
            bill_id: true,
            order_id: true,
            subtotal: true,
            delivery_fee: true,
            tax_amount: true,
            discount: true,
            final_amount: true,
            payment_method: true,
            payment_status: true,
            transaction_id: true,
            paid_at: true,
            created_at: true,
            updated_at: true,
        },
    });

    if (!bill) {
        return null;
    }

    return {
        bill_id: bill.bill_id,
        order_id: bill.order_id,
        subtotal: bill.subtotal.toString(),
        delivery_fee: bill.delivery_fee.toString(),
        tax_amount: bill.tax_amount.toString(),
        discount: bill.discount.toString(),
        final_amount: bill.final_amount.toString(),
        payment_method: bill.payment_method,
        payment_status: bill.payment_status,
        transaction_id: bill.transaction_id,
        paid_at: bill.paid_at?.toISOString() || null,
        created_at: bill.created_at.toISOString(),
        updated_at: bill.updated_at.toISOString(),
    };
};

/**
 * Get invoice details (bill + item-wise breakdown) for an order.
 * Returns null if invoice not generated yet.
 *
 * @param {string} customerId
 * @param {string} orderId
 */
exports.getInvoiceByOrderId = async (customerId, orderId) => {
    // Verify order belongs to customer and invoice exists
    const order = await prisma.order.findFirst({
        where: {
            order_id: orderId,
            customer_id: customerId,
        },
        select: {
            order_id: true,
            billing_status: true,
            order_status: true,
            pricing_model: true,
            order_type: true,
            bill: {
                select: {
                    bill_id: true,
                    subtotal: true,
                    delivery_fee: true,
                    tax_amount: true,
                    discount: true,
                    final_amount: true,
                    payment_method: true,
                    payment_status: true,
                    transaction_id: true,
                    paid_at: true,
                    created_at: true,
                    updated_at: true,
                },
            },
            order_items: {
                orderBy: { created_at: 'asc' },
                select: {
                    item_id: true,
                    pricing_type: true,
                    quantity: true,
                    weight_kg: true,
                    unit_price: true,
                    subtotal: true,
                    service: {
                        select: {
                            service_id: true,
                            service_name: true,
                            category: { select: { category_id: true, category_name: true } },
                        },
                    },
                    item_selections: {
                        orderBy: { created_at: 'asc' },
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
        },
    });

    if (!order) {
        throw new NotFoundError('Order');
    }

    if (order.billing_status !== 'generated' || !order.bill) {
        return null;
    }

    const items = (order.order_items || []).map((it) => {
        const serviceName = it.service?.service_name || 'Service';
        const categoryName = it.service?.category?.category_name || 'Category';

        if (it.pricing_type === 'per_unit') {
            const lines = (it.item_selections || [])
                .map((s) => {
                    const qty = s.quantity || 0;
                    const unit = s.cloth_item?.per_unit_price;
                    const lineSubtotal = unit != null ? new Prisma.Decimal(unit).mul(qty) : new Prisma.Decimal(0);
                    return {
                        selectionId: s.selection_id,
                        clothId: s.cloth_item?.cloth_id || null,
                        clothName: s.cloth_item?.item_name || '',
                        quantity: qty,
                        unitPrice: unit != null ? unit.toString() : null,
                        subtotal: lineSubtotal.toString(),
                    };
                })
                .filter((x) => x.quantity > 0);

            return {
                orderItemId: it.item_id,
                pricingType: 'per_unit',
                categoryName,
                serviceName,
                quantity: it.quantity,
                unitPrice: it.unit_price.toString(),
                subtotal: it.subtotal.toString(),
                selections: lines,
            };
        }

        // per_kg
        return {
            orderItemId: it.item_id,
            pricingType: 'per_kg',
            categoryName,
            serviceName,
            weightKg: it.weight_kg ? it.weight_kg.toString() : null,
            unitPrice: it.unit_price.toString(),
            subtotal: it.subtotal.toString(),
            selections: [],
        };
    });

    return {
        orderId: order.order_id,
        orderStatus: order.order_status,
        orderType: order.order_type,
        pricingModel: order.pricing_model,
        billingStatus: order.billing_status,
        bill: {
            billId: order.bill.bill_id,
            subtotal: order.bill.subtotal.toString(),
            deliveryFee: order.bill.delivery_fee.toString(),
            taxAmount: order.bill.tax_amount.toString(),
            discount: order.bill.discount.toString(),
            finalAmount: order.bill.final_amount.toString(),
            paymentMethod: order.bill.payment_method,
            paymentStatus: order.bill.payment_status,
            transactionId: order.bill.transaction_id,
            paidAt: order.bill.paid_at ? order.bill.paid_at.toISOString() : null,
            createdAt: order.bill.created_at.toISOString(),
            updatedAt: order.bill.updated_at.toISOString(),
        },
        items,
    };
};

module.exports = exports;

