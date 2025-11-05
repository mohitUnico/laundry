/**
 * JWT Utility Functions
 * Helper functions for generating and managing JWT tokens
 */

const jwt = require('jsonwebtoken');
const logger = require('./logger');

/**
 * Generate JWT token for a user
 * @param {Object} user - User object from database
 * @returns {string} JWT token
 */
exports.generateToken = (user) => {
    if (!process.env.JWT_SECRET) {
        throw new Error('JWT_SECRET is not defined in environment variables');
    }

    // Support both userId (camelCase) and user_id (snake_case) for compatibility
    const userId = user.user_id || user.userId;
    const martId = user.mart_id || user.martId;
    const fullName = user.full_name || user.fullName;

    const payload = {
        user_id: userId,
        email: user.email,
        role: user.role,
        mart_id: martId,
        full_name: fullName,
    };

    const options = {
        expiresIn: process.env.JWT_EXPIRY || '7d', // Default 7 days
    };

    try {
        const token = jwt.sign(payload, process.env.JWT_SECRET, options);

        logger.debug('JWT token generated', {
            userId: user.user_id,
            email: user.email,
            role: user.role,
        });

        return token;
    } catch (error) {
        logger.error('Failed to generate JWT token', {
            error: error.message,
            userId: user.user_id,
        });
        throw error;
    }
};

/**
 * Verify and decode JWT token
 * @param {string} token - JWT token
 * @returns {Object} Decoded token payload
 */
exports.verifyToken = (token) => {
    if (!process.env.JWT_SECRET) {
        throw new Error('JWT_SECRET is not defined in environment variables');
    }

    try {
        return jwt.verify(token, process.env.JWT_SECRET);
    } catch (error) {
        logger.error('Failed to verify JWT token', {
            error: error.message,
        });
        throw error;
    }
};

/**
 * Decode JWT token without verification (for debugging)
 * @param {string} token - JWT token
 * @returns {Object} Decoded token payload
 */
exports.decodeToken = (token) => {
    return jwt.decode(token);
};

/**
 * Generate token expiry date
 * @param {string} expiresIn - Expiry duration (e.g., '7d', '1h')
 * @returns {Date} Expiry date
 */
exports.getTokenExpiry = (expiresIn = '7d') => {
    const now = new Date();
    const duration = expiresIn.match(/(\d+)([dhms])/);

    if (!duration) {
        return new Date(now.getTime() + 7 * 24 * 60 * 60 * 1000); // Default 7 days
    }

    const [, value, unit] = duration;
    const numValue = parseInt(value);

    switch (unit) {
        case 'd': // days
            return new Date(now.getTime() + numValue * 24 * 60 * 60 * 1000);
        case 'h': // hours
            return new Date(now.getTime() + numValue * 60 * 60 * 1000);
        case 'm': // minutes
            return new Date(now.getTime() + numValue * 60 * 1000);
        case 's': // seconds
            return new Date(now.getTime() + numValue * 1000);
        default:
            return new Date(now.getTime() + 7 * 24 * 60 * 60 * 1000);
    }
};

module.exports = exports;

