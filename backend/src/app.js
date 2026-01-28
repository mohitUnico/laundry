const express = require('express');
const cors = require('cors');
const helmet = require('helmet');
const compression = require('compression');
const rateLimit = require('express-rate-limit');
require('./config/env');
const routes = require('./routes');
const { errorHandler, notFoundHandler } = require('./middleware/error.middleware');
const { requestLogger } = require('./middleware/logger.middleware');
const logger = require('./utils/logger');

const app = express();

// Trust proxy for accurate IP addresses
app.set('trust proxy', 1);

// Security middleware
app.use(helmet());

// CORS configuration
const allowedOrigins = process.env.CORS_ORIGIN
    ? process.env.CORS_ORIGIN.split(',').map((origin) => origin.trim()).filter(Boolean)
    : ['http://localhost:3000'];

const isDevelopment = process.env.NODE_ENV === 'development';

const corsOptions = {
    origin: (origin, callback) => {
        // Allow requests with no origin (mobile apps, Postman, etc.)
        if (!origin) {
            callback(null, true);
            return;
        }

        // In development, allow all origins
        // NOTE: Using a function keeps `credentials: true` compatible (wildcard "*" is not allowed with credentials).
        if (isDevelopment) {
            callback(null, true);
            return;
        }

        // Check against explicitly allowed origins
        if (allowedOrigins.includes(origin)) {
            callback(null, true);
            return;
        }

        // Reject all other origins
        callback(new Error(`Not allowed by CORS: ${origin}`));
    },
    credentials: true,
    optionsSuccessStatus: 200,
};
app.use(cors(corsOptions));

// Rate limiting
const limiter = rateLimit({
    windowMs: parseInt(process.env.RATE_LIMIT_WINDOW_MS) || 15 * 60 * 1000, // 15 minutes
    max: parseInt(process.env.RATE_LIMIT_MAX_REQUESTS) || 100,
    message: 'Too many requests from this IP, please try again later.',
    standardHeaders: true,
    legacyHeaders: false,
    // Allow high-frequency endpoints to work reliably (they are already protected by auth):
    // - SSE is long-lived and should not count against burst limits
    // - Location updates can be frequent (even after client-side throttling)
    skip: (req) => {
        const path = req.path || '';
        const hasAuth = typeof req.headers?.authorization === 'string' && req.headers.authorization.startsWith('Bearer ');

        // Always skip SSE + location update endpoints
        if (path.startsWith('/v1/delivery-staff/events') || path.startsWith('/v1/delivery-staff/location')) {
            return true;
        }

        // Delivery staff app screens poll multiple endpoints frequently (home stats, accepted orders, etc.)
        // These routes are already JWT-protected, so applying the global IP limiter causes false 429s.
        if (hasAuth && path.startsWith('/v1/delivery-staff-app')) {
            return true;
        }

        // Staff apps (collection/distribution/service man) can also refresh frequently and are JWT-protected.
        if (hasAuth && path.startsWith('/v1/staff-app')) {
            return true;
        }

        return false;
    },
});
app.use('/api', limiter);

// Body parsing middleware - optimize for faster parsing
app.use(express.json({
    limit: '10mb',
    // Reduce JSON parsing overhead
    strict: false,
}));
app.use(express.urlencoded({
    extended: true,
    limit: '10mb',
    // Optimize parameter parsing
    parameterLimit: 1000,
}));

// Compression middleware
// IMPORTANT: Disable compression for SSE endpoints, otherwise event-stream output can get buffered
// and clients (especially Postman) won't receive events in real-time.
app.use(
    compression({
        filter: (req, res) => {
            const url = req.originalUrl || req.url || '';
            if (url.includes('/api/v1/delivery-staff/events')) {
                return false;
            }
            return compression.filter(req, res);
        },
    })
);

// Request logging
app.use(requestLogger);

// Health check endpoint
app.get('/health', (req, res) => {
    res.status(200).json({
        status: 'ok',
        timestamp: new Date().toISOString(),
        uptime: process.uptime(),
        environment: process.env.NODE_ENV,
    });
});

// API routes
app.use('/api/v1', routes);

// 404 handler
app.use(notFoundHandler);

// Error handling middleware (must be last)
app.use(errorHandler);

// Log startup
logger.info('Express application initialized');

module.exports = app;

