const express = require('express');
const paymentController = require('../controllers/payment.controller');
const { authenticateJWT, authorize } = require('../middleware/auth.middleware');
const { validate } = require('../middleware/validation.middleware');
const { ValidationError } = require('../utils/errors');
const Joi = require('joi');

const paymentRouter = express.Router();
const uuidParam = Joi.string().uuid().required();

const validateUuidParam = (paramName) => (req, _res, next) => {
    const { error } = uuidParam.validate(req.params[paramName]);
    if (error) return next(new ValidationError('Validation failed', [{ field: paramName, message: error.message }]));
    next();
};

const couponSchema = Joi.object({ code: Joi.string().min(2).max(50).required() });
const razorpayConfirmSchema = Joi.object({
    razorpayOrderId: Joi.string().min(5).max(100).required(),
    razorpayPaymentId: Joi.string().min(5).max(100).required(),
    razorpaySignature: Joi.string().min(10).max(256).required(),
});
const refundSchema = Joi.object({ reason: Joi.string().min(3).max(255).required() });

paymentRouter.post('/webhook/:provider', paymentController.webhook);

paymentRouter.post(
    '/orders/:orderId/process',
    authenticateJWT,
    authorize('customer'),
    validateUuidParam('orderId'),
    paymentController.processPayment
);
paymentRouter.post(
    '/process/:orderId',
    authenticateJWT,
    authorize('customer'),
    validateUuidParam('orderId'),
    paymentController.processPayment
);

paymentRouter.get('/orders/:orderId/bill', authenticateJWT, authorize('customer'), validateUuidParam('orderId'), paymentController.getBillByOrderId);
paymentRouter.get('/orders/:orderId/invoice', authenticateJWT, authorize('customer'), validateUuidParam('orderId'), paymentController.getInvoiceByOrderId);
paymentRouter.get('/bill/:orderId', authenticateJWT, authorize('customer'), validateUuidParam('orderId'), paymentController.getBillByOrderId);
paymentRouter.get('/invoice/:orderId', authenticateJWT, authorize('customer'), validateUuidParam('orderId'), paymentController.getInvoiceByOrderId);

paymentRouter.post('/orders/:orderId/coupon', authenticateJWT, authorize('customer'), validateUuidParam('orderId'), validate(couponSchema), paymentController.applyCoupon);
paymentRouter.delete('/orders/:orderId/coupon', authenticateJWT, authorize('customer'), validateUuidParam('orderId'), paymentController.removeCoupon);
paymentRouter.post('/orders/:orderId/pay-intent', authenticateJWT, authorize('customer'), validateUuidParam('orderId'), paymentController.createPayIntent);
paymentRouter.post(
    '/orders/:orderId/razorpay/confirm',
    authenticateJWT,
    authorize('customer'),
    validateUuidParam('orderId'),
    validate(razorpayConfirmSchema),
    paymentController.confirmRazorpay
);
paymentRouter.post('/orders/:orderId/cancel-attempt', authenticateJWT, authorize('customer'), validateUuidParam('orderId'), paymentController.cancelAttempt);
paymentRouter.get('/orders/:orderId/payment-status', authenticateJWT, authorize('customer'), validateUuidParam('orderId'), paymentController.paymentStatus);
paymentRouter.post(
    '/orders/:orderId/refund',
    authenticateJWT,
    authorize('admin', 'owner', 'super_admin'),
    validateUuidParam('orderId'),
    validate(refundSchema),
    paymentController.refundPayment
);

module.exports = paymentRouter;
