const winston = require('winston');
const path = require('path');
const fs = require('fs');

const { combine, timestamp, printf, colorize, errors } = winston.format;

// Ensure logs directory exists
const logsDir = path.join(__dirname, '../../logs');
if (!fs.existsSync(logsDir)) {
    fs.mkdirSync(logsDir, { recursive: true });
}

// Console filter: when LOG_COMPONENTS is set (comma-separated), only show logs with matching component.
// Example: LOG_COMPONENTS=pickup-assignment-queue,pickup-assignment-worker,pickup-assignment-catchup,whatsapp
// Legacy: LOG_ONLY_PICKUP_ASSIGNMENT=true is equivalent to LOG_COMPONENTS=pickup-assignment-job
const getAllowedComponents = () => {
    const components = process.env.LOG_COMPONENTS;
    if (components) {
        return components.split(',').map((c) => c.trim()).filter(Boolean);
    }
    if (process.env.LOG_ONLY_PICKUP_ASSIGNMENT === 'true') {
        return ['pickup-assignment-job'];
    }
    return [];
};
const componentFilter = winston.format((info) => {
    const allowed = getAllowedComponents();
    if (allowed.length === 0) return info;
    return allowed.includes(info.component) ? info : false;
})();

// Custom log format
const logFormat = printf(({ level, message, timestamp, stack, component, ...meta }) => {
    const rest = { ...meta };
    if (component !== undefined) rest.component = component;
    const metaStr = Object.keys(rest).length ? JSON.stringify(rest) : '';
    return `${timestamp} ${level}: ${stack || message} ${metaStr}`;
});

// Create logger instance
const logger = winston.createLogger({
    level: process.env.LOG_LEVEL || 'info',
    format: combine(timestamp({ format: 'YYYY-MM-DD HH:mm:ss' }), errors({ stack: true }), logFormat),
    transports: [
        // Console transport (when LOG_COMPONENTS set, only matching component logs)
        new winston.transports.Console({
            format: combine(
                componentFilter,
                colorize(),
                timestamp({ format: 'YYYY-MM-DD HH:mm:ss' }),
                logFormat
            ),
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

