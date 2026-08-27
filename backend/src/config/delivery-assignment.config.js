/**
 * Configuration for delivery assignment requests
 * All limits can be configured via environment variables for easy adjustment
 */

/**
 * Parse integer from environment variable with validation
 * @param {string} envVar - Environment variable name
 * @param {number} defaultValue - Default value if env var is not set or invalid
 * @param {number} min - Minimum allowed value
 * @param {number} max - Maximum allowed value
 * @returns {number} Parsed and validated integer
 */
function parseEnvInt(envVar, defaultValue, min = 0, max = Infinity) {
    const raw = process.env[envVar];
    if (!raw) return defaultValue;

    const parsed = parseInt(raw, 10);
    if (!Number.isFinite(parsed) || parsed < min || parsed > max) {
        console.warn(
            `[config] Invalid value for ${envVar}: "${raw}". Using default: ${defaultValue} (must be between ${min} and ${max})`
        );
        return defaultValue;
    }

    return parsed;
}

/**
 * Parse float from environment variable with validation
 * @param {string} envVar - Environment variable name
 * @param {number} defaultValue - Default value if env var is not set or invalid
 * @param {number} min - Minimum allowed value
 * @param {number} max - Maximum allowed value
 * @returns {number} Parsed and validated float
 */
function parseEnvFloat(envVar, defaultValue, min = 0, max = Infinity) {
    const raw = process.env[envVar];
    if (!raw) return defaultValue;

    const parsed = parseFloat(raw);
    if (!Number.isFinite(parsed) || parsed < min || parsed > max) {
        console.warn(
            `[config] Invalid value for ${envVar}: "${raw}". Using default: ${defaultValue} (must be between ${min} and ${max})`
        );
        return defaultValue;
    }

    return parsed;
}

/**
 * Parse boolean from environment variable
 * @param {string} envVar - Environment variable name
 * @param {boolean} defaultValue - Default value if env var is not set
 * @returns {boolean} Parsed boolean
 */
function parseEnvBool(envVar, defaultValue) {
    const raw = process.env[envVar];
    if (!raw) return defaultValue;

    return raw.toLowerCase() === 'true' || raw === '1';
}

/**
 * Delivery Assignment Configuration
 * All values can be overridden via environment variables
 */
const deliveryAssignmentConfig = {
    // ==================== PICKUP ASSIGNMENT JOB ====================
    /**
     * Maximum number of delivery staff to notify when sending to all active staff
     * Environment: PICKUP_ASSIGNMENT_MAX_STAFF_LIMIT
     * Default: 100
     * Max: 500
     */
    pickupAssignmentMaxStaffLimit: parseEnvInt('PICKUP_ASSIGNMENT_MAX_STAFF_LIMIT', 100, 1, 500),

    /**
     * Assignment request expiry time in seconds
     * Environment: PICKUP_ASSIGNMENT_EXPIRY_SECONDS
     * Default: 120 (2 minutes)
     * Min: 30, Max: 3600
     */
    pickupAssignmentExpirySeconds: parseEnvInt('PICKUP_ASSIGNMENT_EXPIRY_SECONDS', 120, 30, 3600),

    /**
     * Whether to send assignment requests to all active staff (true) or use distance-based filtering (false)
     * Environment: PICKUP_ASSIGNMENT_SEND_TO_ALL
     * Default: true
     */
    pickupAssignmentSendToAll: parseEnvBool('PICKUP_ASSIGNMENT_SEND_TO_ALL', true),

    // ==================== DISTANCE-BASED ASSIGNMENT (when sendToAll is false) ====================
    /**
     * Default radius in kilometers for nearby staff search
     * Environment: DELIVERY_ASSIGNMENT_DEFAULT_RADIUS_KM
     * Default: 5 km
     * Min: 0.1, Max: 100
     */
    defaultRadiusKm: parseEnvFloat('DELIVERY_ASSIGNMENT_DEFAULT_RADIUS_KM', 5, 0.1, 100),

    /**
     * Default limit for nearby staff search
     * Environment: DELIVERY_ASSIGNMENT_DEFAULT_LIMIT
     * Default: 10
     * Min: 1, Max: 50
     */
    defaultLimit: parseEnvInt('DELIVERY_ASSIGNMENT_DEFAULT_LIMIT', 10, 1, 50),

    // ==================== GENERAL ASSIGNMENT REQUEST LIMITS ====================
    /**
     * Maximum limit for "send to all" requests
     * Environment: DELIVERY_ASSIGNMENT_MAX_LIMIT
     * Default: 500
     * Min: 1, Max: 1000
     */
    maxLimit: parseEnvInt('DELIVERY_ASSIGNMENT_MAX_LIMIT', 500, 1, 1000),

    /**
     * Maximum radius allowed for distance-based searches
     * Environment: DELIVERY_ASSIGNMENT_MAX_RADIUS_KM
     * Default: 50 km
     * Min: 1, Max: 500
     */
    maxRadiusKm: parseEnvFloat('DELIVERY_ASSIGNMENT_MAX_RADIUS_KM', 50, 1, 500),

    /**
     * Default expiry time for assignment requests in seconds
     * Environment: DELIVERY_ASSIGNMENT_DEFAULT_EXPIRY_SECONDS
     * Default: 120 (2 minutes)
     * Min: 30, Max: 3600
     */
    defaultExpirySeconds: parseEnvInt('DELIVERY_ASSIGNMENT_DEFAULT_EXPIRY_SECONDS', 120, 30, 3600),

    // ==================== SCHEDULER SUPPORT ====================
    /**
     * Batch size for processing orders in pickup assignment job
     * Environment: PICKUP_ASSIGNMENT_BATCH_SIZE
     * Default: 50
     * Min: 1, Max: 200
     */
    pickupAssignmentBatchSize: parseEnvInt('PICKUP_ASSIGNMENT_BATCH_SIZE', 50, 1, 200),

};

/**
 * Get configuration for pickup assignment job
 * @returns {object} Configuration object for pickup assignment
 */
function getPickupAssignmentConfig() {
    return {
        sendToAll: deliveryAssignmentConfig.pickupAssignmentSendToAll,
        maxStaffLimit: deliveryAssignmentConfig.pickupAssignmentMaxStaffLimit,
        expirySeconds: deliveryAssignmentConfig.pickupAssignmentExpirySeconds,
        batchSize: deliveryAssignmentConfig.pickupAssignmentBatchSize,
    };
}

/**
 * Get default configuration for creating assignment requests
 * @param {object} overrides - Optional overrides for specific values
 * @returns {object} Default configuration for assignment requests
 */
function getDefaultAssignmentConfig(overrides = {}) {
    return {
        radiusKm: deliveryAssignmentConfig.defaultRadiusKm,
        limit: deliveryAssignmentConfig.defaultLimit,
        expiresInSeconds: deliveryAssignmentConfig.defaultExpirySeconds,
        sendToAll: deliveryAssignmentConfig.pickupAssignmentSendToAll,
        ...overrides,
    };
}

/**
 * Validate assignment request parameters against configuration limits
 * @param {object} params - Assignment request parameters
 * @returns {object} Validated and clamped parameters
 */
function validateAssignmentParams(params) {
    const { radiusKm, limit, expiresInSeconds } = params;

    const validated = { ...params };

    if (radiusKm !== null && radiusKm !== undefined) {
        validated.radiusKm = Math.max(0.1, Math.min(radiusKm, deliveryAssignmentConfig.maxRadiusKm));
    }

    if (limit !== null && limit !== undefined) {
        validated.limit = Math.max(1, Math.min(limit, deliveryAssignmentConfig.maxLimit));
    }

    if (expiresInSeconds !== null && expiresInSeconds !== undefined) {
        validated.expiresInSeconds = Math.max(
            30,
            Math.min(expiresInSeconds, 3600)
        );
    }

    return validated;
}

module.exports = {
    config: deliveryAssignmentConfig,
    getPickupAssignmentConfig,
    getDefaultAssignmentConfig,
    validateAssignmentParams,
};
