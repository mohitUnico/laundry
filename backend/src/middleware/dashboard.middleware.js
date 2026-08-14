const { AppError } = require('../utils/errors');

/**
 * Dashboard Middleware
 * Validates dashboard-specific requests
 */

/**
 * Validate and parse optional current_timestamp from request body
 * Defaults to current time if not provided
 */
exports.parseTimestamp = (req, res, next) => {
    try {
        const { current_timestamp } = req.body || {};

        if (current_timestamp) {
            const timestamp = new Date(current_timestamp);
            if (isNaN(timestamp.getTime())) {
                throw new AppError('Invalid current_timestamp format. Must be a valid ISO 8601 date string', 400);
            }

            // Check if timestamp is not in the future
            if (timestamp > new Date()) {
                throw new AppError('current_timestamp cannot be in the future', 400);
            }

            req.currentTimestamp = timestamp;
        } else {
            req.currentTimestamp = new Date();
        }

        next();
    } catch (error) {
        next(error);
    }
};

/**
 * Validate query parameters for dashboard endpoints
 */
exports.validateQueryParams = (req, res, next) => {
    try {
        const { range, limit } = req.query;

        // Validate range if provided
        if (range) {
            const validRanges = ['7days', '7weeks', '7months'];
            if (!validRanges.includes(range)) {
                throw new AppError('Invalid range parameter. Valid values: 7days, 7weeks, 7months', 400);
            }
        }

        // Validate limit if provided
        if (limit) {
            const limitNum = parseInt(limit);
            if (isNaN(limitNum) || limitNum < 1 || limitNum > 100) {
                throw new AppError('Invalid limit parameter. Must be between 1 and 100', 400);
            }
        }

        next();
    } catch (error) {
        next(error);
    }
};

