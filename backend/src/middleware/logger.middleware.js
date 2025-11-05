const logger = require('../utils/logger');
const { v4: uuidv4 } = require('uuid');

/**
 * Middleware to log HTTP requests with duration and correlation ID
 */
exports.requestLogger = (req, res, next) => {
  const start = Date.now();

  // Generate correlation ID for request tracking
  req.correlationId = req.headers['x-correlation-id'] || uuidv4();
  res.setHeader('X-Correlation-ID', req.correlationId);

  // Log when response is finished
  res.on('finish', () => {
    const duration = Date.now() - start;
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
    } else {
      logger.info(logMessage, logData);
    }
  });

  next();
};

module.exports = exports;

