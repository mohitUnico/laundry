const logger = require('../utils/logger');
const { v4: uuidv4 } = require('uuid');

/**
 * Middleware to log HTTP requests with duration and correlation ID
 * Optimized: Only log in development or for errors in production
 */
exports.requestLogger = (req, res, next) => {
  const start = Date.now();

  // Generate correlation ID for request tracking
  req.correlationId = req.headers['x-correlation-id'] || uuidv4();
  res.setHeader('X-Correlation-ID', req.correlationId);

  // Log when response is finished - optimize for production
  res.on('finish', () => {
    const duration = Date.now() - start;
    
    // In production, only log errors and slow requests (>1s)
    // In development, log everything
    const isDevelopment = process.env.NODE_ENV === 'development';
    const isSlow = duration > 1000;
    const isError = res.statusCode >= 400;
    
    if (isDevelopment || isError || isSlow) {
      const logData = {
        method: req.method,
        url: req.originalUrl,
        status: res.statusCode,
        duration: `${duration}ms`,
        ip: req.ip,
        userAgent: req.get('user-agent'),
        correlationId: req.correlationId,
      };

      const logMessage = `${logData.method} ${logData.url} ${logData.status} ${logData.duration}`;

      if (res.statusCode >= 500) {
        logger.error(logMessage, logData);
      } else if (res.statusCode >= 400) {
        logger.warn(logMessage, logData);
      } else if (isSlow) {
        logger.warn(`Slow request: ${logMessage}`, logData);
      } else {
        logger.info(logMessage, logData);
      }
    }
  });

  next();
};

module.exports = exports;

