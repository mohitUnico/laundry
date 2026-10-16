const paymentService = require('../services/payment.service');
const doorService = require('../services/door.service');
const checkout = require('../services/payments/checkout.service');
const { AuthorizationError, AppError } = require('../utils/errors');

exports.processPayment = async (req, res, next) => {
    try {
        await paymentService.processPayment();
        res.status(200).json({ success: true });
    } catch (error) {
        next(error);
    }
};

async function sendBill(req, res, next) {
    try {
        if (req.user.role !== 'customer') throw new AuthorizationError('Only customers can view their bills');
        const data = await doorService.getCustomerBill(req.user.user_id, req.params.orderId);
        res.status(200).json({ success: true, data, message: 'Bill fetched successfully' });
    } catch (error) {
        next(error);
    }
}

exports.getBillByOrderId = sendBill;
exports.getInvoiceByOrderId = sendBill;

exports.applyCoupon = async (req, res, next) => {
    try {
        if (req.user.role !== 'customer') throw new AuthorizationError('Only customers can apply a coupon');
        const data = await checkout.applyCoupon({
            customerId: req.user.user_id,
            orderId: req.params.orderId,
            code: req.body.code,
        });
        res.status(200).json({ success: true, data });
    } catch (error) {
        next(error);
    }
};

exports.removeCoupon = async (req, res, next) => {
    try {
        if (req.user.role !== 'customer') throw new AuthorizationError('Only customers can remove a coupon');
        const data = await checkout.removeCoupon({
            customerId: req.user.user_id,
            orderId: req.params.orderId,
        });
        res.status(200).json({ success: true, data });
    } catch (error) {
        next(error);
    }
};

exports.createPayIntent = async (req, res, next) => {
    try {
        if (req.user.role !== 'customer') throw new AuthorizationError('Only customers can pay');
        const data = await checkout.createPayIntent({
            customerId: req.user.user_id,
            orderId: req.params.orderId,
            idempotencyKey: req.get('Idempotency-Key') || null,
        });
        res.status(200).json({ success: true, data });
    } catch (error) {
        next(error);
    }
};

exports.paymentStatus = async (req, res, next) => {
    try {
        if (req.user.role !== 'customer') throw new AuthorizationError('Only customers can view payment status');
        const data = await checkout.paymentStatus({
            customerId: req.user.user_id,
            orderId: req.params.orderId,
        });
        res.status(200).json({ success: true, data });
    } catch (error) {
        next(error);
    }
};

exports.webhook = async (req, res, next) => {
    try {
        const rawBody = req.rawBody || JSON.stringify(req.body || {});
        const data = await checkout.applyWebhook({
            providerName: req.params.provider,
            headers: req.headers,
            rawBody,
        });
        res.status(200).json({ success: true, data });
    } catch (error) {
        next(error);
    }
};

exports.mockComplete = async (req, res, next) => {
    try {
        if (process.env.NODE_ENV === 'production') {
            throw new AppError('Not found', 404, 'NOT_FOUND');
        }
        const data = await checkout.devForceAttempt({
            attemptId: req.params.attemptId,
            status: req.body.status,
        });
        res.status(200).json({ success: true, data });
    } catch (error) {
        next(error);
    }
};
