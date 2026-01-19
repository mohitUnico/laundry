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

const corsOptions = {
    origin: (origin, callback) => {
        if (!origin || allowedOrigins.includes(origin)) {
            callback(null, true);
        } else {
            callback(new Error(`Not allowed by CORS: ${origin}`));
        }
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
app.use(compression());

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

