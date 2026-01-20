const Joi = require('joi');

/**
 * Payment processing schema
 */
const processPaymentSchema = Joi.object({
    payment_method: Joi.string()
        .valid('card', 'cod', 'upi', 'wallet', 'pending')
        .required()
        .messages({
            'any.only': 'Payment method must be one of: card, cod, upi, wallet, pending',
            'any.required': 'Payment method is required',
        }),
    transaction_id: Joi.string()
        .trim()
        .max(255)
        .allow(null, '')
        .optional()
        .messages({
            'string.max': 'Transaction ID must not exceed 255 characters',
        }),
    payment_status: Joi.string()
        .valid('pending', 'completed', 'failed', 'refunded')
        .default('completed')
        .optional()
        .messages({
            'any.only': 'Payment status must be one of: pending, completed, failed, refunded',
        }),
});

module.exports = {
    processPaymentSchema,
};

