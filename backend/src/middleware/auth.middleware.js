const jwt = require('jsonwebtoken');
const { AuthenticationError, AuthorizationError } = require('../utils/errors');
const prisma = require('../config/database');

/**
 * JWT Authentication Middleware
 * Verifies JWT token and attaches decoded user to request
 */
exports.authenticateJWT = async (req, res, next) => {
    try {
        // Get token from header
        const authHeader = req.headers.authorization;
        if (!authHeader || !authHeader.startsWith('Bearer ')) {
            throw new AuthenticationError('No token provided');
        }

        const token = authHeader.substring(7);

        // Verify token
        const decoded = jwt.verify(token, process.env.JWT_SECRET);

        // Attach user to request
        req.user = decoded;
        next();
    } catch (error) {
        if (error.name === 'JsonWebTokenError') {
            next(new AuthenticationError('Invalid token'));
        } else if (error.name === 'TokenExpiredError') {
            next(new AuthenticationError('Token expired'));
        } else {
            next(error);
        }
    }
};

/**
 * Role-based Authorization Middleware
 * Checks if user has required role(s)
 * @param {...string} roles - Allowed roles
 */
exports.authorize = (...roles) => {
    return (req, res, next) => {
        if (!req.user) {
            return next(new AuthenticationError());
        }

        if (!roles.includes(req.user.role)) {
            return next(new AuthorizationError('You do not have permission to perform this action'));
        }

        next();
    };
};

/**
 * Optional Authentication Middleware
 * Attaches user if token is present, otherwise continues
 */
exports.optionalAuth = async (req, res, next) => {
    try {
        const authHeader = req.headers.authorization;
        if (authHeader && authHeader.startsWith('Bearer ')) {
            const token = authHeader.substring(7);
            const decoded = jwt.verify(token, process.env.JWT_SECRET);
            req.user = decoded;
        }
        next();
    } catch (error) {
        // Continue without authentication
        next();
    }
};

module.exports = exports;

