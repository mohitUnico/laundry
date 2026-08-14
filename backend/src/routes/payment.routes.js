const express = require('express');
const paymentController = require('../controllers/payment.controller');
const { authenticateJWT, authorize } = require('../middleware/auth.middleware');
const { validate } = require('../middleware/validation.middleware');
const { processPaymentSchema } = require('../validators/payment.validator');
const { ValidationError } = require('../utils/errors');
const Joi = require('joi');

// Use a uniquely named router to avoid any potential identifier clashes
const paymentRouter = express.Router();

// ============================================================================
// VALIDATION HELPERS
// ============================================================================

const uuidParam = Joi.string().uuid().required();

const validateUuidParam = (paramName) => {
    return (req, _res, next) => {
        const { error } = uuidParam.validate(req.params[paramName]);
        if (error) {
            return next(new ValidationError('Validation failed', [{ field: paramName, message: error.message }]));
        }
        next();
    };
};

// Process payment for an order
paymentRouter.post(
    '/process/:orderId',
    authenticateJWT,
    authorize('customer'),
    validateUuidParam('orderId'),
    validate(processPaymentSchema),
    paymentController.processPayment
);

// Get bill/payment details for an order
paymentRouter.get(
    '/bill/:orderId',
    authenticateJWT,
    authorize('customer'),
    validateUuidParam('orderId'),
    paymentController.getBillByOrderId
);

// Get invoice (bill + line items) for an order
paymentRouter.get(
    '/invoice/:orderId',
    authenticateJWT,
    authorize('customer'),
    validateUuidParam('orderId'),
    paymentController.getInvoiceByOrderId
);

module.exports = paymentRouter;

