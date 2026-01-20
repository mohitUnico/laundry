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

module.exports = exports;

