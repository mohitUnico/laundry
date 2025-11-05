const logger = require('../utils/logger');
const { AppError } = require('../utils/errors');

exports.errorHandler = (err, req, res, next) => {
    let error = { ...err };
    error.message = err.message;

    // Log error with context
    logger.error('Error occurred', {
        message: err.message,
        stack: err.stack,
        code: err.code,
        statusCode: err.statusCode,
        correlationId: req.correlationId,
        url: req.originalUrl,
        method: req.method,
    });

    // Mongoose/Prisma validation error
    if (err.name === 'ValidationError') {
        const message = 'Validation Error';
        error = new AppError(message, 400, 'VALIDATION_ERROR');
    }

    // Prisma unique constraint error
    if (err.code === 'P2002') {
        const message = 'Duplicate field value entered';
        error = new AppError(message, 409, 'DUPLICATE_ERROR');
    }

    // Prisma record not found
    if (err.code === 'P2025') {
        const message = 'Record not found';
        error = new AppError(message, 404, 'NOT_FOUND');
    }

    // JWT errors
    if (err.name === 'JsonWebTokenError') {
        const message = 'Invalid token';
        error = new AppError(message, 401, 'INVALID_TOKEN');
    }

    if (err.name === 'TokenExpiredError') {
        const message = 'Token expired';
        error = new AppError(message, 401, 'TOKEN_EXPIRED');
    }

    // Send error response
    res.status(error.statusCode || 500).json({
        success: false,
        message: error.message || 'Internal Server Error',
        errorCode: error.code || 'INTERNAL_ERROR',
        ...(error.errors && { errors: error.errors }),
        ...(process.env.NODE_ENV === 'development' && { stack: err.stack }),
        timestamp: new Date().toISOString(),
        path: req.originalUrl,
    });
};

// 404 handler
exports.notFoundHandler = (req, res, next) => {
    res.status(404).json({
        success: false,
        message: 'Route not found',
        errorCode: 'ROUTE_NOT_FOUND',
        path: req.originalUrl,
        timestamp: new Date().toISOString(),
    });
};

module.exports = exports;

