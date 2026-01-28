const paymentService = require('../services/payment.service');
const { AuthorizationError } = require('../utils/errors');

/**
 * Process payment for an order
 * POST /api/v1/payments/process/:orderId
 */
exports.processPayment = async (req, res, next) => {
    try {
        if (req.user.role !== 'customer') {
            throw new AuthorizationError('Only customers can process payments');
        }

        const customerId = req.user.user_id;
        const { orderId } = req.params;
        const { payment_method, transaction_id, payment_status } = req.body;

        const bill = await paymentService.processPayment(customerId, orderId, {
            payment_method,
            transaction_id,
            payment_status,
        });

        res.status(200).json({
            success: true,
            data: bill,
            message: 'Payment processed successfully',
        });
    } catch (error) {
        next(error);
    }
};

/**
 * Get bill/payment details for an order
 * GET /api/v1/payments/bill/:orderId
 */
exports.getBillByOrderId = async (req, res, next) => {
    try {
        if (req.user.role !== 'customer') {
            throw new AuthorizationError('Only customers can view their bills');
        }

        const customerId = req.user.user_id;
        const { orderId } = req.params;

        const bill = await paymentService.getBillByOrderId(customerId, orderId);

        if (!bill) {
            return res.status(200).json({
                success: true,
                data: null,
                message: 'Bill not found for this order',
            });
        }

        res.status(200).json({
            success: true,
            data: bill,
            message: 'Bill fetched successfully',
        });
    } catch (error) {
        next(error);
    }
};

/**
 * Get invoice (bill + line items) for an order
 * GET /api/v1/payments/invoice/:orderId
 */
exports.getInvoiceByOrderId = async (req, res, next) => {
    try {
        if (req.user.role !== 'customer') {
            throw new AuthorizationError('Only customers can view their invoices');
        }

        const customerId = req.user.user_id;
        const { orderId } = req.params;

        const invoice = await paymentService.getInvoiceByOrderId(customerId, orderId);

        if (!invoice) {
            return res.status(200).json({
                success: true,
                data: null,
                message: 'Invoice not generated for this order',
            });
        }

        res.status(200).json({
            success: true,
            data: invoice,
            message: 'Invoice fetched successfully',
        });
    } catch (error) {
        next(error);
    }
};

module.exports = exports;

