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
const mockSchema = Joi.object({ status: Joi.string().valid('succeeded', 'failed').required() });

paymentRouter.post('/webhook/:provider', paymentController.webhook);
paymentRouter.post('/mock/attempts/:attemptId/complete', validate(mockSchema), paymentController.mockComplete);

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
paymentRouter.get('/orders/:orderId/payment-status', authenticateJWT, authorize('customer'), validateUuidParam('orderId'), paymentController.paymentStatus);

module.exports = paymentRouter;
