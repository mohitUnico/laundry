import { logger } from '../utils/logger.js'

export const requestLogger = (req, res, next) => {
    const start = Date.now()

    // Log when response is finished
    res.on('finish', () => {
        const duration = Date.now() - start
        const logData = {
            method: req.method,
            url: req.originalUrl,
            status: res.statusCode,
            duration: `${duration}ms`,
            ip: req.ip,
            userAgent: req.get('user-agent'),
        }

        const logMessage = `${logData.method} ${logData.url} ${logData.status} ${logData.duration}`

        if (res.statusCode >= 500) {
            logger.error(logMessage, logData)
        } else if (res.statusCode >= 400) {
            logger.warn(logMessage, logData)
        } else {
            logger.info(logMessage, logData)
        }
    })

    next()
}

export default requestLogger

