import { logger } from '../utils/logger.js'
import { AppError } from '../utils/errors.js'

export const errorHandler = (err, req, res, next) => {
    let error = { ...err }
    error.message = err.message

    // Log error
    logger.error(err)

    // Mongoose/Prisma validation error
    if (err.name === 'ValidationError') {
        const message = 'Validation Error'
        error = new AppError(message, 400, 'VALIDATION_ERROR')
    }

    // Prisma unique constraint error
    if (err.code === 'P2002') {
        const message = 'Duplicate field value entered'
        error = new AppError(message, 409, 'DUPLICATE_ERROR')
    }

    // Prisma record not found
    if (err.code === 'P2025') {
        const message = 'Record not found'
        error = new AppError(message, 404, 'NOT_FOUND')
    }

    // JWT errors
    if (err.name === 'JsonWebTokenError') {
        const message = 'Invalid token'
        error = new AppError(message, 401, 'INVALID_TOKEN')
    }

    if (err.name === 'TokenExpiredError') {
        const message = 'Token expired'
        error = new AppError(message, 401, 'TOKEN_EXPIRED')
    }

    // Send error response
    res.status(error.statusCode || 500).json({
        success: false,
        message: error.message || 'Internal Server Error',
        errorCode: error.errorCode || 'INTERNAL_ERROR',
        ...(process.env.NODE_ENV === 'development' && { stack: err.stack }),
    })
}

export default errorHandler

