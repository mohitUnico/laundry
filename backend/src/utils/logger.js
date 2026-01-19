const winston = require('winston');
const path = require('path');
const fs = require('fs');

const { combine, timestamp, printf, colorize, errors } = winston.format;

// Ensure logs directory exists
const logsDir = path.join(__dirname, '../../logs');
if (!fs.existsSync(logsDir)) {
    fs.mkdirSync(logsDir, { recursive: true });
}

// Custom log format
const logFormat = printf(({ level, message, timestamp, stack, ...meta }) => {
    const metaStr = Object.keys(meta).length ? JSON.stringify(meta) : '';
    return `${timestamp} ${level}: ${stack || message} ${metaStr}`;
});

// Create logger instance
const logger = winston.createLogger({
    level: process.env.LOG_LEVEL || 'info',
    format: combine(timestamp({ format: 'YYYY-MM-DD HH:mm:ss' }), errors({ stack: true }), logFormat),
    transports: [
        // Console transport
        new winston.transports.Console({
            format: combine(colorize(), timestamp({ format: 'YYYY-MM-DD HH:mm:ss' }), logFormat),
        }),
        // File transport for errors
        new winston.transports.File({
            filename: path.join(__dirname, '../../logs/error.log'),
            level: 'error',
            maxsize: 5242880, // 5MB
            maxFiles: 5,
        }),
        // File transport for all logs
        new winston.transports.File({
            filename: path.join(__dirname, '../../logs/combined.log'),
            maxsize: 5242880, // 5MB
            maxFiles: 5,
        }),
    ],
    exceptionHandlers: [
        new winston.transports.File({
            filename: path.join(__dirname, '../../logs/exceptions.log'),
        }),
    ],
    rejectionHandlers: [
        new winston.transports.File({
            filename: path.join(__dirname, '../../logs/rejections.log'),
        }),
    ],
});

// Don't log to console in test environment
if (process.env.NODE_ENV === 'test') {
    logger.transports.forEach((transport) => {
        if (transport instanceof winston.transports.Console) {
            transport.silent = true;
        }
    });
}

module.exports = logger;

