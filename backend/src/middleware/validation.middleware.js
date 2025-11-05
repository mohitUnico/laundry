const { ValidationError } = require('../utils/errors');

/**
 * Middleware to validate request body against Joi schema
 * @param {Object} schema - Joi validation schema
 * @returns {Function} Express middleware
 */
exports.validate = (schema) => {
    return (req, res, next) => {
        const { error, value } = schema.validate(req.body, {
            abortEarly: false,
            stripUnknown: true,
        });

        if (error) {
            const errors = error.details.map((detail) => ({
                field: detail.path.join('.'),
                message: detail.message,
            }));

            return next(new ValidationError('Validation failed', errors));
        }

        // Replace req.body with validated value
        req.body = value;
        next();
    };
};

/**
 * Middleware to validate query parameters against Joi schema
 * @param {Object} schema - Joi validation schema
 * @returns {Function} Express middleware
 */
exports.validateQuery = (schema) => {
    return (req, res, next) => {
        const { error, value } = schema.validate(req.query, {
            abortEarly: false,
            stripUnknown: true,
        });

        if (error) {
            const errors = error.details.map((detail) => ({
                field: detail.path.join('.'),
                message: detail.message,
            }));

            return next(new ValidationError('Query validation failed', errors));
        }

        req.query = value;
        next();
    };
};

module.exports = exports;

