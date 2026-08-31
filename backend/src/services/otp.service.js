/**
 * OTP Service - Email-First Authentication
 * 
 * Flow:
 * 1. User enters email → Send OTP
 * 2. User verifies OTP → Check if user exists
 *    - Existing user: Return JWT token (login complete)
 *    - New user: Return session token (needs registration)
 * 3. New user completes registration with session token
 */

// IMPORTANT: Use the shared Prisma client from config/database.
// Creating multiple PrismaClient instances can exhaust the DB connection pool.
// and cause P2024 timeouts under normal app polling.
const prisma = require('../config/database');
const logger = require('../utils/logger');
const { generateToken } = require('../utils/jwt');
const {
    AppError,
    ValidationError,
    NotFoundError,
    AuthenticationError,
    AuthorizationError,
    ConflictError,
} = require('../utils/errors');
const crypto = require('crypto');
const emailService = require('./email.service');
const serviceService = require('./service.service');
const refreshTokenService = require('./refresh-token.service');

// ============================================================================
// CONSTANTS
// ============================================================================

const OTP_EXPIRY_MINUTES = parseInt(process.env.OTP_EXPIRY_MINUTES || '5');
const OTP_MAX_ATTEMPTS = parseInt(process.env.OTP_MAX_ATTEMPTS || '5');
const OTP_RATE_LIMIT_SECONDS = parseInt(process.env.OTP_RATE_LIMIT_SECONDS || '60');
const SESSION_EXPIRY_MINUTES = 30; // Session token expires in 30 minutes

const USER_TYPES = {
    MART: 'mart',
    OWNER: 'owner',
    MANAGER: 'manager',
    COLLECTION_MANAGER: 'collection_manager',
    DISTRIBUTION_MANAGER: 'distribution_manager',
    SERVICE_MAN: 'service_man',
    CUSTOMER: 'customer',
    DELIVERY_STAFF: 'delivery_staff'
};

// Export user types so other modules can reuse the constants safely.
exports.USER_TYPES = USER_TYPES;

const PURPOSE = {
    LOGIN_OR_SIGNUP: 'login_or_signup',
    MART_EMAIL_VERIFICATION: 'mart_email_verification',
    EMAIL_CHANGE: 'email_change',
    PASSWORD_RESET: 'password_reset'
};

// ============================================================================
// HELPER FUNCTIONS
// ============================================================================

/**
 * Generate 6-digit OTP
 */
const _generateOtp = () => {
    return Math.floor(100000 + Math.random() * 900000).toString();
};

/**
 * Generate expiry time
 */
const _getExpiryTime = (minutes) => {
    return new Date(Date.now() + minutes * 60 * 1000);
};

/**
 * Generate session token
 */
const _generateSessionToken = () => {
    return crypto.randomBytes(32).toString('hex');
};

/**
 * Resolve service_id for service man flows from either serviceId or serviceType (service_name)
 * @param {Object} data
 * @param {string} [data.serviceId]
 * @param {string} [data.serviceType]
 * @returns {Promise<string>} service_id
 */
async function _resolveServiceIdForServiceMan({ serviceId, serviceType }) {
    if (serviceId) return serviceId;

    const normalizedType = String(serviceType || '').trim();
    if (!normalizedType) {
        throw new ValidationError('Service type is required');
    }

    const service = await prisma.service.findFirst({
        where: {
            service_name: { equals: normalizedType, mode: 'insensitive' },
            is_active: true
        },
        select: { service_id: true, service_name: true }
    });

    if (!service) {
        throw new NotFoundError('Service');
    }

    return service.service_id;
}

/**
 * Check rate limiting for OTP requests
 */
const _checkRateLimit = async (email, userType) => {
    const recentOtp = await prisma.otpVerification.findFirst({
        where: {
            email,
            user_type: userType,
            created_at: {
                gte: new Date(Date.now() - OTP_RATE_LIMIT_SECONDS * 1000)
            }
        },
        orderBy: {
            created_at: 'desc'
        }
    });

    if (recentOtp) {
        const secondsLeft = Math.ceil(
            (recentOtp.created_at.getTime() + OTP_RATE_LIMIT_SECONDS * 1000 - Date.now()) / 1000
        );
        throw new AppError(
            `Please wait ${secondsLeft} seconds before requesting a new OTP`,
            429
        );
    }
};

/**
 * Increment verification attempts
 */
const _incrementAttempts = async (otpId) => {
    return await prisma.otpVerification.update({
        where: { otp_id: otpId },
        data: { attempts: { increment: 1 } }
    });
};

// ============================================================================
// CORE OTP FUNCTIONS
// ============================================================================

/**
 * Send OTP to email for login or signup
 * @param {string} email - User's email address
 * @param {string} userType - User type (owner, manager, customer, delivery_staff)
 * @returns {Promise<Object>} OTP send result
 */
const sendOtp = async (email, userType) => {
    try {
        // Validate user type
        if (!Object.values(USER_TYPES).includes(userType)) {
            throw new ValidationError('Invalid user type');
        }

        // Normalize email
        email = email.toLowerCase().trim();

        // Staff role guard:
        // If an email is already registered under a DIFFERENT staff role,
        // block OTP sending and return a clear message.
        const staffUserTypes = [
            USER_TYPES.COLLECTION_MANAGER,
            USER_TYPES.DISTRIBUTION_MANAGER,
            USER_TYPES.SERVICE_MAN
        ];

        if (staffUserTypes.includes(userType)) {
            const existingStaff = await prisma.staff.findUnique({
                where: { email },
                select: { role: true }
            });

            if (existingStaff?.role && existingStaff.role !== userType) {
                const prettyRole = String(existingStaff.role).replace(/_/g, ' ');
                throw new ValidationError(`This email is already registered as ${prettyRole}`);
            }
        }

        // Check rate limiting
        await _checkRateLimit(email, userType);

        // Generate OTP
        const otp = _generateOtp();
        const expiresAt = _getExpiryTime(OTP_EXPIRY_MINUTES);

        // Save OTP to database
        await prisma.otpVerification.create({
            data: {
                email,
                otp_code: otp,
                purpose: PURPOSE.LOGIN_OR_SIGNUP,
                user_type: userType,
                expires_at: expiresAt,
                max_attempts: OTP_MAX_ATTEMPTS
            }
        });

        // Send OTP via email
        await emailService.sendOtpEmail(email, otp, userType);

        logger.info('OTP sent successfully', {
            email,
            userType,
            expiresIn: OTP_EXPIRY_MINUTES * 60
        });

        return {
            expiresIn: OTP_EXPIRY_MINUTES * 60 // seconds
        };
    } catch (error) {
        logger.error('Failed to send OTP', {
            error: error.message,
            email,
            userType
        });
        throw error;
    }
};

/**
 * Verify OTP and determine if user exists
 * @param {string} email - User's email address
 * @param {string} otp - 6-digit OTP code
 * @param {string} userType - User type
 * @param {Object} [options] - Optional contextual data for some user types
 * @returns {Promise<Object>} Verification result
 */
const verifyOtp = async (email, otp, userType, options = {}) => {
    try {
        // Normalize email
        email = email.toLowerCase().trim();

        // Find OTP
        const otpRecord = await prisma.otpVerification.findFirst({
            where: {
                email,
                user_type: userType,
                purpose: PURPOSE.LOGIN_OR_SIGNUP,
                is_verified: false
            },
            orderBy: {
                created_at: 'desc'
            }
        });

        if (!otpRecord) {
            throw new AuthenticationError('No OTP found. Please request a new OTP.');
        }

        // Check if expired
        if (new Date() > otpRecord.expires_at) {
            throw new AuthenticationError('OTP has expired. Please request a new OTP.');
        }

        // Check max attempts
        if (otpRecord.attempts >= otpRecord.max_attempts) {
            throw new AuthenticationError('Maximum verification attempts exceeded. Please request a new OTP.');
        }

        // Verify OTP
        if (otpRecord.otp_code !== otp) {
            // Increment attempts
            await _incrementAttempts(otpRecord.otp_id);

            const remainingAttempts = otpRecord.max_attempts - (otpRecord.attempts + 1);
            throw new AuthenticationError(
                `Invalid OTP. ${remainingAttempts} attempt(s) remaining.`
            );
        }

        // Mark OTP as verified
        await prisma.otpVerification.update({
            where: { otp_id: otpRecord.otp_id },
            data: { is_verified: true }
        });

        // Check if user exists based on user type
        let existingUser = null;

        switch (userType) {
            case USER_TYPES.OWNER:
            case USER_TYPES.MANAGER:
                existingUser = await prisma.user.findUnique({
                    where: { email },
                });
                break;

            case USER_TYPES.COLLECTION_MANAGER:
                existingUser = await prisma.staff.findFirst({
                    where: { email, role: 'collection_manager' }
                });
                break;

            case USER_TYPES.DISTRIBUTION_MANAGER:
                existingUser = await prisma.staff.findFirst({
                    where: { email, role: 'distribution_manager' }
                });
                break;

            case USER_TYPES.SERVICE_MAN:
                existingUser = await prisma.staff.findFirst({
                    where: { email, role: 'service_man' },
                    include: {
                        service: {
                            select: {
                                service_id: true,
                                service_name: true
                            }
                        }
                    }
                });
                break;

            case USER_TYPES.CUSTOMER:
                existingUser = await prisma.customer.findUnique({
                    where: { email }
                });
                break;

            case USER_TYPES.DELIVERY_STAFF:
                // NOTE: DeliveryStaff model in current Prisma schema does not define a `mart` relation,
                // so we must not use `include: { mart: ... }` here (it causes PrismaClientValidationError).
                existingUser = await prisma.deliveryStaff.findUnique({
                    where: { email },
                    // Select minimal fields so OTP verification isn't coupled to optional profile/document columns.
                    // (DB still must be migrated for the full registration flow.)
                    select: {
                        staff_id: true,
                        email: true,
                        full_name: true,
                        phone: true,
                        verification_status: true,
                        is_verified_by_admin: true,
                    },
                });
                break;
        }

        if (existingUser) {
            // Existing user - login complete
            logger.info('Existing user verified', {
                email,
                userType,
                userId: existingUser.user_id || existingUser.customer_id || existingUser.staff_id
            });

            const userId =
                existingUser.user_id ||
                existingUser.customer_id ||
                existingUser.staff_id ||
                existingUser.manager_id;

            // Generate access + refresh token
            const tokens = await refreshTokenService.issueTokens({
                userId,
                userType,
                email: existingUser.email,
                role: existingUser.role || userType,
                fullName: existingUser.full_name,
            });

            return {
                isNewUser: false,
                token: tokens.token,
                refreshToken: tokens.refreshToken,
                user: {
                    userId,
                    email: existingUser.email,
                    fullName: existingUser.full_name,
                    role: existingUser.role || userType,
                    ...(userType === USER_TYPES.SERVICE_MAN
                        ? {
                            serviceId: existingUser.service_id || null,
                            serviceName: existingUser.service?.service_name || null
                        }
                        : {})
                    ,
                    ...(userType === USER_TYPES.DELIVERY_STAFF
                        ? {
                            verificationStatus: existingUser.verification_status || null,
                            isVerifiedByAdmin:
                                typeof existingUser.is_verified_by_admin === 'boolean'
                                    ? existingUser.is_verified_by_admin
                                    : null,
                        }
                        : {})
                }
            };
        } else {
            // New user - needs registration
            logger.info('New user verified, creating session', {
                email,
                userType
            });

            // Create session token
            const sessionToken = _generateSessionToken();
            const sessionExpiresAt = _getExpiryTime(SESSION_EXPIRY_MINUTES);

            await prisma.otpSession.create({
                data: {
                    email,
                    user_type: userType,
                    is_new_user: true,
                    session_token: sessionToken,
                    expires_at: sessionExpiresAt
                }
            });

            return {
                isNewUser: true,
                sessionToken,
                expiresIn: SESSION_EXPIRY_MINUTES * 60 // seconds
            };
        }
    } catch (error) {
        logger.error('OTP verification failed', {
            error: error.message,
            email,
            userType
        });
        throw error;
    }
};

/**
 * Send OTP to mart email for verification during owner registration
 * @param {string} sessionToken - Session token from owner email verification
 * @param {string} martEmail - Mart's contact email to verify
 * @returns {Promise<Object>} Send result
 */
const sendMartEmailOtp = async (sessionToken, martEmail) => {
    try {
        // Validate inputs
        if (!sessionToken || !martEmail) {
            throw new ValidationError('Session token and mart email are required');
        }

        // Normalize email
        const normalizedEmail = martEmail.toLowerCase().trim();

        // Verify session exists and is valid
        const session = await prisma.otpSession.findUnique({
            where: { session_token: sessionToken }
        });

        if (!session) {
            throw new AuthenticationError('Invalid or expired session token');
        }

        if (session.user_type !== USER_TYPES.OWNER) {
            throw new ValidationError('Session token is not for owner registration');
        }

        if (!session.is_new_user) {
            throw new ValidationError('Session is not for new user registration');
        }

        if (new Date() > session.expires_at) {
            throw new AuthenticationError('Session has expired. Please start over.');
        }

        if (session.is_completed) {
            throw new ValidationError('Registration already completed');
        }

        // Check if mart email already exists
        const existingConfig = await prisma.laundryConfig.findUnique({
            where: { contact_email: normalizedEmail }
        });

        if (existingConfig) {
            throw new ValidationError('This business email is already registered');
        }

        // Check rate limiting (owner + purpose)
        await _checkRateLimit(normalizedEmail, USER_TYPES.OWNER);

        // Generate OTP
        const otpCode = _generateOtp();
        const expiresAt = _getExpiryTime(OTP_EXPIRY_MINUTES);

        // Save OTP
        await prisma.otpVerification.create({
            data: {
                email: normalizedEmail,
                otp_code: otpCode,
                purpose: PURPOSE.MART_EMAIL_VERIFICATION,
                user_type: USER_TYPES.OWNER,
                expires_at: expiresAt,
                max_attempts: OTP_MAX_ATTEMPTS
            }
        });

        // Send OTP email
        await emailService.sendOtpEmail(normalizedEmail, otpCode, USER_TYPES.MART);

        logger.info('Mart email OTP sent successfully', {
            martEmail: normalizedEmail,
            sessionToken: sessionToken.substring(0, 10) + '...',
            expiresIn: OTP_EXPIRY_MINUTES * 60
        });

        return {
            success: true,
            martEmail: normalizedEmail,
            expiresIn: OTP_EXPIRY_MINUTES * 60
        };
    } catch (error) {
        logger.error('Failed to send mart email OTP', {
            error: error.message,
            sessionToken: sessionToken?.substring(0, 10) + '...',
            martEmail
        });
        throw error;
    }
};

/**
 * Verify OTP for mart email during owner registration
 * @param {string} sessionToken - Session token from owner email verification
 * @param {string} martEmail - Mart's contact email
 * @param {string} otp - OTP code to verify
 * @returns {Promise<Object>} Verification result
 */
const verifyMartEmailOtp = async (sessionToken, martEmail, otp) => {
    try {
        // Validate inputs
        if (!sessionToken || !martEmail || !otp) {
            throw new ValidationError('Session token, mart email, and OTP are required');
        }

        // Normalize email
        const normalizedEmail = martEmail.toLowerCase().trim();

        // Verify session exists and is valid
        const session = await prisma.otpSession.findUnique({
            where: { session_token: sessionToken }
        });

        if (!session) {
            throw new AuthenticationError('Invalid or expired session token');
        }

        if (session.user_type !== USER_TYPES.OWNER) {
            throw new ValidationError('Session token is not for owner registration');
        }

        if (!session.is_new_user) {
            throw new ValidationError('Session is not for new user registration');
        }

        if (new Date() > session.expires_at) {
            throw new AuthenticationError('Session has expired. Please start over.');
        }

        if (session.is_completed) {
            throw new ValidationError('Registration already completed');
        }

        // Find OTP record
        const otpRecord = await prisma.otpVerification.findFirst({
            where: {
                email: normalizedEmail,
                purpose: PURPOSE.MART_EMAIL_VERIFICATION,
                user_type: USER_TYPES.OWNER,
                is_verified: false
            },
            orderBy: {
                created_at: 'desc'
            }
        });

        if (!otpRecord) {
            throw new NotFoundError('OTP not found or already verified');
        }

        // Check expiration
        if (new Date() > otpRecord.expires_at) {
            throw new AuthenticationError('OTP has expired. Please request a new one.');
        }

        // Check max attempts
        if (otpRecord.attempts >= otpRecord.max_attempts) {
            throw new AuthenticationError('Maximum verification attempts exceeded. Please request a new OTP.');
        }

        // Verify OTP
        if (otpRecord.otp_code !== otp) {
            // Increment attempts
            await _incrementAttempts(otpRecord.otp_id);

            const remainingAttempts = otpRecord.max_attempts - (otpRecord.attempts + 1);
            throw new AuthenticationError(
                `Invalid OTP. ${remainingAttempts} attempt(s) remaining.`
            );
        }

        // Mark OTP as verified
        await prisma.otpVerification.update({
            where: { otp_id: otpRecord.otp_id },
            data: { is_verified: true }
        });

        // Update session with verified mart email
        await prisma.otpSession.update({
            where: { session_token: sessionToken },
            data: {
                business_email: normalizedEmail,
                business_email_verified: true
            }
        });

        logger.info('Mart email OTP verified successfully', {
            martEmail: normalizedEmail,
            sessionToken: sessionToken.substring(0, 10) + '...'
        });

        return {
            success: true,
            martEmail: normalizedEmail,
            message: 'Mart email verified successfully. You can now complete registration.'
        };
    } catch (error) {
        logger.error('Mart email OTP verification failed', {
            error: error.message,
            sessionToken: sessionToken?.substring(0, 10) + '...',
            martEmail
        });
        throw error;
    }
};

/**
 * Complete owner registration (Owner + Mart)
 * @param {string} sessionToken - Session token from verify OTP
 * @param {Object} martData - Mart registration data
 * @param {Object} ownerData - Owner registration data
 * @returns {Promise<Object>} Registration result
 */
const completeOwnerRegistration = async (sessionToken, martData, ownerData) => {
    try {
        // Verify session
        const session = await prisma.otpSession.findUnique({
            where: { session_token: sessionToken }
        });

        if (!session) {
            throw new AuthenticationError('Invalid or expired session token');
        }

        if (session.user_type !== USER_TYPES.OWNER) {
            throw new ValidationError('Session token is not for owner registration');
        }

        if (!session.is_new_user) {
            throw new ValidationError('Session is not for new user registration');
        }

        if (new Date() > session.expires_at) {
            throw new AuthenticationError('Session has expired. Please start over.');
        }

        if (session.is_completed) {
            throw new ValidationError('Registration already completed');
        }

        // IMPORTANT: Check if business email is verified
        if (!session.business_email_verified || !session.business_email) {
            throw new ValidationError('Business email must be verified before completing registration');
        }

        const businessEmail = martData?.businessEmail || martData?.martEmail;
        const businessName = martData?.businessName || martData?.martName;

        if (!businessEmail || !businessName) {
            throw new ValidationError('Business name and email are required');
        }

        // Validate business email matches the data
        if (businessEmail && businessEmail.toLowerCase() !== session.business_email) {
            throw new ValidationError('Business email does not match verified email');
        }

        // Single business: only one LaundryConfig can exist
        const existingBusiness = await prisma.laundryConfig.findFirst();
        if (existingBusiness) {
            throw new ValidationError('Business is already configured. Please login.');
        }

        // Create business config and owner in transaction
        const result = await prisma.$transaction(async (tx) => {
            // Create LaundryConfig with verified email
            const config = await tx.laundryConfig.create({
                data: {
                    business_name: businessName,
                    contact_email: session.business_email, // Use verified business email from session
                    contact_phone: martData.martContact || '',
                    address: martData.address || '',
                    latitude: martData.martCoordinates?.latitude || 0,
                    longitude: martData.martCoordinates?.longitude || 0,
                    service_radius_km: martData.serviceRadiusKm || {
                        tiers: [
                            { minKm: 0, maxKm: 5, pricePerKm: 20 },
                            { minKm: 5, maxKm: 10, pricePerKm: 40 }
                        ],
                        maxRadius: 10
                    },
                    is_active: true,
                    logo_url: martData.profileImageUrl || null
                }
            });

            // Create owner user (NO PASSWORD - OTP-based auth)
            const owner = await tx.user.create({
                data: {
                    full_name: ownerData.ownerName, // Updated field name
                    email: session.email, // Use verified owner email from session
                    phone: ownerData.ownerPhone || null, // Updated field name
                    role: 'admin', // Owner is admin
                    is_active: true
                }
            });

            // Mark session as completed
            await tx.otpSession.update({
                where: { session_token: sessionToken },
                data: {
                    is_completed: true,
                    user_id: owner.user_id
                }
            });

            return { config, owner };
        });

        // Generate JWT token
        const token = generateToken({
            userId: result.owner.user_id,
            email: result.owner.email,
            role: result.owner.role,
            fullName: result.owner.full_name,
            martId: result.owner.mart_id
        });

        logger.info('Owner registration completed', {
            email: session.email,
            configId: result.config.config_id,
            userId: result.owner.user_id
        });

        // NOTE: Single business model has no mart_id; default service creation should be updated separately.

        // Send welcome email (non-blocking)
        emailService.sendWelcomeEmail(session.email, ownerData.ownerName, USER_TYPES.OWNER)
            .catch(err => logger.error('Failed to send welcome email', { error: err.message }));

        return {
            token,
            // Backward compatible shape ("mart" = LaundryConfig)
            mart: {
                martId: result.config.config_id,
                martName: result.config.business_name,
                contactEmail: result.config.contact_email,
                contactPhone: result.config.contact_phone,
                address: result.config.address,
                profileImageUrl: result.config.logo_url
            },
            owner: {
                userId: result.owner.user_id,
                fullName: result.owner.full_name,
                email: result.owner.email,
                role: result.owner.role,
                martId: null
            }
        };
    } catch (error) {
        logger.error('Owner registration failed', {
            error: error.message
        });
        throw error;
    }
};

/**
 * Complete manager registration
 * @param {string} sessionToken - Session token from verify OTP
 * @param {Object} managerData - Manager registration data
 * @param {Object} owner - Owner information from JWT token
 * @returns {Promise<Object>} Registration result
 */
const completeManagerRegistration = async (sessionToken, managerData, owner) => {
    try {
        // Verify session
        const session = await prisma.otpSession.findUnique({
            where: { session_token: sessionToken }
        });

        if (!session) {
            throw new AuthenticationError('Invalid or expired session token');
        }

        if (session.user_type !== USER_TYPES.MANAGER) {
            throw new ValidationError('Session token is not for manager registration');
        }

        if (!session.is_new_user) {
            throw new ValidationError('Session is not for new user registration');
        }

        if (new Date() > session.expires_at) {
            throw new AuthenticationError('Session has expired. Please start over.');
        }

        if (session.is_completed) {
            throw new ValidationError('Registration already completed');
        }

        // Verify mart exists and owner owns it
        const mart = await prisma.laundryMart.findUnique({
            where: { mart_id: managerData.martId },
            include: {
                users: {
                    where: {
                        user_id: owner.user_id,
                        role: 'owner'
                    },
                    select: {
                        user_id: true,
                        full_name: true,
                        email: true,
                        role: true
                    }
                }
            }
        });

        if (!mart) {
            throw new NotFoundError('Mart');
        }

        // Verify owner exists in database and owns the mart
        const ownerUser = await prisma.user.findUnique({
            where: { user_id: owner.user_id }
        });

        if (!ownerUser) {
            logger.error('Owner not found in database', { userId: owner.user_id });
            throw new AuthenticationError('Owner not found in database');
        }

        // Compare mart IDs (case-insensitive for UUIDs)
        const ownerMartId = String(ownerUser.mart_id || '').toLowerCase();
        const requestMartId = String(managerData.martId || '').toLowerCase();

        if (requestMartId !== ownerMartId) {
            logger.warn('Owner mart ID mismatch', {
                ownerUserId: owner.user_id,
                ownerMartId: ownerMartId,
                requestMartId: requestMartId
            });
            throw new AuthorizationError('Owner does not have access to this mart');
        }

        if (ownerUser.role !== 'owner' && ownerUser.role !== 'admin') {
            logger.warn('Invalid role for manager registration', {
                userId: owner.user_id,
                role: ownerUser.role
            });
            throw new AuthorizationError('Only mart owners can add managers');
        }

        // Create manager user
        const manager = await prisma.$transaction(async (tx) => {
            const newManager = await tx.user.create({
                data: {
                    mart_id: managerData.martId,
                    full_name: managerData.fullName,
                    email: session.email,
                    phone: managerData.phone,
                    role: 'manager',
                    is_active: true
                }
            });

            // Mark session as completed
            await tx.otpSession.update({
                where: { session_token: sessionToken },
                data: {
                    is_completed: true,
                    user_id: newManager.user_id
                }
            });

            return newManager;
        });

        // Generate JWT token
        const token = generateToken({
            userId: manager.user_id,
            email: manager.email,
            role: manager.role,
            fullName: manager.full_name,
            martId: manager.mart_id
        });

        logger.info('Manager registration completed', {
            email: session.email,
            userId: manager.user_id,
            martId: manager.mart_id
        });

        // Send welcome email (non-blocking)
        emailService.sendWelcomeEmail(session.email, managerData.fullName, USER_TYPES.MANAGER)
            .catch(err => logger.error('Failed to send welcome email', { error: err.message }));

        // Fetch owner details for response
        const ownerDetails = await prisma.user.findUnique({
            where: { user_id: owner.user_id },
            select: {
                user_id: true,
                full_name: true,
                email: true,
                phone: true,
                role: true,
                mart_id: true
            }
        });

        // Fetch mart details for response
        const martDetails = await prisma.laundryMart.findUnique({
            where: { mart_id: managerData.martId },
            select: {
                mart_id: true,
                mart_name: true,
                contact_email: true,
                contact_phone: true,
                address: true,
                profile_image_url: true
            }
        });

        return {
            token,
            manager: {
                userId: manager.user_id,
                fullName: manager.full_name,
                email: manager.email,
                role: manager.role,
                martId: manager.mart_id
            },
            owner: ownerDetails ? {
                userId: ownerDetails.user_id,
                fullName: ownerDetails.full_name,
                email: ownerDetails.email,
                phone: ownerDetails.phone,
                role: ownerDetails.role,
                martId: ownerDetails.mart_id
            } : null,
            mart: martDetails ? {
                martId: martDetails.mart_id,
                martName: martDetails.mart_name,
                contactEmail: martDetails.contact_email,
                contactPhone: martDetails.contact_phone,
                address: martDetails.address,
                profileImageUrl: martDetails.profile_image_url
            } : null
        };
    } catch (error) {
        logger.error('Manager registration failed', {
            error: error.message
        });
        throw error;
    }
};

/**
 * Complete collection manager registration (created by owner/admin)
 * @param {string} sessionToken - Session token from verify OTP
 * @param {{fullName:string, phone?:string|null}} collectionManagerData
 * @param {Object} owner - Owner/admin token payload
 * @returns {Promise<Object>}
 */
const completeCollectionManagerRegistration = async (sessionToken, collectionManagerData, owner) => {
    try {
        const session = await prisma.otpSession.findUnique({
            where: { session_token: sessionToken }
        });

        if (!session) throw new AuthenticationError('Invalid or expired session token');
        if (session.user_type !== USER_TYPES.COLLECTION_MANAGER) {
            throw new ValidationError('Session token is not for collection manager registration');
        }
        if (!session.is_new_user) throw new ValidationError('Session is not for new user registration');
        if (new Date() > session.expires_at) throw new AuthenticationError('Session has expired. Please start over.');
        if (session.is_completed) throw new ValidationError('Registration already completed');

        if (!owner?.role || owner.role !== 'admin') {
            throw new AuthorizationError('Only admin can create a collection manager');
        }

        const existingManager = await prisma.staff.findFirst({
            where: { role: 'collection_manager' },
            select: { staff_id: true, email: true }
        });
        if (existingManager) {
            throw new ConflictError('Collection manager already exists');
        }

        const manager = await prisma.$transaction(async (tx) => {
            const newManager = await tx.staff.create({
                data: {
                    role: 'collection_manager',
                    full_name: collectionManagerData.fullName,
                    email: session.email,
                    phone: collectionManagerData.phone || null,
                    is_active: true
                }
            });

            await tx.otpSession.update({
                where: { session_token: sessionToken },
                data: {
                    is_completed: true,
                    user_id: newManager.staff_id
                }
            });

            return newManager;
        });

        const token = generateToken({
            userId: manager.staff_id,
            email: manager.email,
            role: USER_TYPES.COLLECTION_MANAGER,
            fullName: manager.full_name
        });

        emailService
            .sendWelcomeEmail(session.email, collectionManagerData.fullName, USER_TYPES.COLLECTION_MANAGER)
            .catch((err) => logger.error('Failed to send welcome email', { error: err.message }));

        return {
            token,
            collectionManager: {
                managerId: manager.staff_id,
                fullName: manager.full_name,
                email: manager.email,
                phone: manager.phone
            }
        };
    } catch (error) {
        logger.error('Collection manager registration failed', { error: error.message });
        throw error;
    }
};

/**
 * Complete distribution manager registration (created by owner/admin)
 * @param {string} sessionToken - Session token from verify OTP
 * @param {{fullName:string, phone?:string|null}} distributionManagerData
 * @param {Object} owner - Owner/admin token payload
 * @returns {Promise<Object>}
 */
const completeDistributionManagerRegistration = async (sessionToken, distributionManagerData, owner) => {
    try {
        const session = await prisma.otpSession.findUnique({
            where: { session_token: sessionToken }
        });

        if (!session) throw new AuthenticationError('Invalid or expired session token');
        if (session.user_type !== USER_TYPES.DISTRIBUTION_MANAGER) {
            throw new ValidationError('Session token is not for distribution manager registration');
        }
        if (!session.is_new_user) throw new ValidationError('Session is not for new user registration');
        if (new Date() > session.expires_at) throw new AuthenticationError('Session has expired. Please start over.');
        if (session.is_completed) throw new ValidationError('Registration already completed');

        if (!owner?.role || owner.role !== 'admin') {
            throw new AuthorizationError('Only admin can create a distribution manager');
        }

        const existingManager = await prisma.staff.findFirst({
            where: { role: 'distribution_manager' },
            select: { staff_id: true, email: true }
        });
        if (existingManager) {
            throw new ConflictError('Distribution manager already exists');
        }

        const manager = await prisma.$transaction(async (tx) => {
            const newManager = await tx.staff.create({
                data: {
                    role: 'distribution_manager',
                    full_name: distributionManagerData.fullName,
                    email: session.email,
                    phone: distributionManagerData.phone || null,
                    is_active: true
                }
            });

            await tx.otpSession.update({
                where: { session_token: sessionToken },
                data: {
                    is_completed: true,
                    user_id: newManager.staff_id
                }
            });

            return newManager;
        });

        const token = generateToken({
            userId: manager.staff_id,
            email: manager.email,
            role: USER_TYPES.DISTRIBUTION_MANAGER,
            fullName: manager.full_name
        });

        emailService
            .sendWelcomeEmail(session.email, distributionManagerData.fullName, USER_TYPES.DISTRIBUTION_MANAGER)
            .catch((err) => logger.error('Failed to send welcome email', { error: err.message }));

        return {
            token,
            distributionManager: {
                managerId: manager.staff_id,
                fullName: manager.full_name,
                email: manager.email,
                phone: manager.phone
            }
        };
    } catch (error) {
        logger.error('Distribution manager registration failed', { error: error.message });
        throw error;
    }
};

/**
 * Complete service man registration (created by owner/admin)
 * @param {string} sessionToken - Session token from verify OTP
 * @param {{fullName:string, phone?:string|null, serviceId?:string, serviceType?:string}} serviceManData
 * @param {Object} owner - Owner/admin token payload
 * @returns {Promise<Object>}
 */
const completeServiceManRegistration = async (sessionToken, serviceManData, owner) => {
    try {
        const session = await prisma.otpSession.findUnique({
            where: { session_token: sessionToken }
        });

        if (!session) throw new AuthenticationError('Invalid or expired session token');
        if (session.user_type !== USER_TYPES.SERVICE_MAN) {
            throw new ValidationError('Session token is not for service man registration');
        }
        if (!session.is_new_user) throw new ValidationError('Session is not for new user registration');
        if (new Date() > session.expires_at) throw new AuthenticationError('Session has expired. Please start over.');
        if (session.is_completed) throw new ValidationError('Registration already completed');

        if (!owner?.role || owner.role !== 'admin') {
            throw new AuthorizationError('Only admin can create a service man');
        }

        const resolvedServiceId = serviceManData.serviceId;
        if (!resolvedServiceId) {
            throw new ValidationError('Service ID is required');
        }

        const existingForService = await prisma.staff.findFirst({
            where: { service_id: resolvedServiceId, role: 'service_man' },
            select: { staff_id: true, email: true }
        });

        if (existingForService) {
            throw new ValidationError('This service already has a service man assigned');
        }

        const serviceMan = await prisma.$transaction(async (tx) => {
            const newServiceMan = await tx.staff.create({
                data: {
                    role: 'service_man',
                    service_id: resolvedServiceId,
                    full_name: serviceManData.fullName,
                    email: session.email,
                    phone: serviceManData.phone || null,
                    is_active: true
                }
            });

            await tx.otpSession.update({
                where: { session_token: sessionToken },
                data: {
                    is_completed: true,
                    user_id: newServiceMan.staff_id
                }
            });

            return newServiceMan;
        });

        const token = generateToken({
            userId: serviceMan.staff_id,
            email: serviceMan.email,
            role: USER_TYPES.SERVICE_MAN,
            fullName: serviceMan.full_name
        });

        emailService
            .sendWelcomeEmail(session.email, serviceManData.fullName, USER_TYPES.SERVICE_MAN)
            .catch((err) => logger.error('Failed to send welcome email', { error: err.message }));

        return {
            token,
            serviceMan: {
                serviceManId: serviceMan.staff_id,
                fullName: serviceMan.full_name,
                email: serviceMan.email,
                phone: serviceMan.phone,
                serviceId: serviceMan.service_id
            }
        };
    } catch (error) {
        logger.error('Service man registration failed', { error: error.message });
        throw error;
    }
};

/**
 * Complete customer registration
 * @param {string} sessionToken - Session token from verify OTP
 * @param {Object} customerData - Customer registration data
 * @returns {Promise<Object>} Registration result
 */
const completeCustomerRegistration = async (sessionToken, customerData) => {
    try {
        // Verify session
        const session = await prisma.otpSession.findUnique({
            where: { session_token: sessionToken }
        });

        if (!session) {
            throw new AuthenticationError('Invalid or expired session token');
        }

        if (session.user_type !== USER_TYPES.CUSTOMER) {
            throw new ValidationError('Session token is not for customer registration');
        }

        if (!session.is_new_user) {
            throw new ValidationError('Session is not for new user registration');
        }

        if (new Date() > session.expires_at) {
            throw new AuthenticationError('Session has expired. Please start over.');
        }

        if (session.is_completed) {
            throw new ValidationError('Registration already completed');
        }

        // Create customer and address
        const customer = await prisma.$transaction(async (tx) => {
            const newCustomer = await tx.customer.create({
                data: {
                    full_name: customerData.fullName,
                    email: session.email,
                    phone: customerData.phone,
                    is_active: true
                }
            });

            // Create customer address if provided
            if (customerData.address) {
                await tx.customerAddress.create({
                    data: {
                        customer_id: newCustomer.customer_id,
                        address_label: customerData.address.addressLabel,
                        full_address: customerData.address.address,
                        latitude: customerData.address.latitude,
                        longitude: customerData.address.longitude,
                        is_default: true // First address is set as default
                    }
                });
            }

            // Mark session as completed
            await tx.otpSession.update({
                where: { session_token: sessionToken },
                data: {
                    is_completed: true,
                    user_id: newCustomer.customer_id
                }
            });

            return newCustomer;
        });

        const tokens = await refreshTokenService.issueTokens({
            userId: customer.customer_id,
            userType: USER_TYPES.CUSTOMER,
            email: customer.email,
            role: 'customer',
            fullName: customer.full_name
        });

        logger.info('Customer registration completed', {
            email: session.email,
            customerId: customer.customer_id
        });

        // Send welcome email (non-blocking)
        emailService.sendWelcomeEmail(session.email, customerData.fullName, USER_TYPES.CUSTOMER)
            .catch(err => logger.error('Failed to send welcome email', { error: err.message }));

        // Fetch the created address
        const customerAddress = customerData.address ? await prisma.customerAddress.findFirst({
            where: { customer_id: customer.customer_id },
            orderBy: { created_at: 'desc' }
        }) : null;

        return {
            token: tokens.token,
            refreshToken: tokens.refreshToken,
            customer: {
                customerId: customer.customer_id,
                fullName: customer.full_name,
                email: customer.email,
                phone: customer.phone,
                address: customerAddress ? {
                    addressId: customerAddress.address_id,
                    addressLabel: customerAddress.address_label,
                    address: customerAddress.full_address,
                    latitude: customerAddress.latitude.toString(),
                    longitude: customerAddress.longitude.toString(),
                    isDefault: customerAddress.is_default
                } : null
            }
        };
    } catch (error) {
        logger.error('Customer registration failed', {
            error: error.message
        });
        throw error;
    }
};

/**
 * Complete delivery staff registration
 * @param {string} sessionToken - Session token from verify OTP
 * @param {Object} deliveryData - Delivery staff registration data
 * @returns {Promise<Object>} Registration result
 */
const completeDeliveryRegistration = async (sessionToken, deliveryData) => {
    try {
        // Verify session
        const session = await prisma.otpSession.findUnique({
            where: { session_token: sessionToken }
        });

        if (!session) {
            throw new AuthenticationError('Invalid or expired session token');
        }

        if (session.user_type !== USER_TYPES.DELIVERY_STAFF) {
            throw new ValidationError('Session token is not for delivery staff registration');
        }

        if (!session.is_new_user) {
            throw new ValidationError('Session is not for new user registration');
        }

        if (new Date() > session.expires_at) {
            throw new AuthenticationError('Session has expired. Please start over.');
        }

        if (session.is_completed) {
            throw new ValidationError('Registration already completed');
        }

        // Create delivery staff
        const deliveryStaff = await prisma.$transaction(async (tx) => {
            const newStaff = await tx.deliveryStaff.create({
                data: {
                    full_name: deliveryData.fullName,
                    email: session.email,
                    phone: deliveryData.phone,
                    address: deliveryData.address || null,
                    current_latitude: (deliveryData.currentCoordinates?.latitude != null) ? deliveryData.currentCoordinates.latitude : null,
                    current_longitude: (deliveryData.currentCoordinates?.longitude != null) ? deliveryData.currentCoordinates.longitude : null,
                    vehicle_type: deliveryData.vehicleType,
                    vehicle_number: deliveryData.vehicleNumber,
                    profile_image_url: deliveryData.profileImageUrl || null,
                    id_proof_type: deliveryData.idProofType || null,
                    id_proof_url: deliveryData.idProofUrl || null,
                    driving_license_url: deliveryData.drivingLicenseUrl || null,
                    verification_status: 'pending',
                    is_active: true
                }
            });

            // Mark session as completed
            await tx.otpSession.update({
                where: { session_token: sessionToken },
                data: {
                    is_completed: true,
                    user_id: newStaff.staff_id
                }
            });

            return newStaff;
        });

        // Generate JWT token
        const token = generateToken({
            userId: deliveryStaff.staff_id,
            email: deliveryStaff.email,
            role: 'delivery_staff',
            fullName: deliveryStaff.full_name
        });

        logger.info('Delivery staff registration completed', {
            email: session.email,
            staffId: deliveryStaff.staff_id
        });

        // Send welcome email (non-blocking)
        emailService.sendWelcomeEmail(session.email, deliveryData.fullName, USER_TYPES.DELIVERY_STAFF)
            .catch(err => logger.error('Failed to send welcome email', { error: err.message }));

        return {
            token,
            deliveryStaff: {
                staffId: deliveryStaff.staff_id,
                fullName: deliveryStaff.full_name,
                email: deliveryStaff.email,
                phone: deliveryStaff.phone,
                verificationStatus: deliveryStaff.verification_status
            }
        };
    } catch (error) {
        logger.error('Delivery staff registration failed', {
            error: error.message
        });
        throw error;
    }
};

/**
 * Resend OTP
 * @param {string} email - User's email address
 * @param {string} userType - User type
 * @returns {Promise<Object>} OTP send result
 */
const resendOtp = async (email, userType) => {
    try {
        // Delete old unverified OTPs for this email
        await prisma.otpVerification.deleteMany({
            where: {
                email: email.toLowerCase().trim(),
                user_type: userType,
                is_verified: false
            }
        });

        // Send new OTP
        return await sendOtp(email, userType);
    } catch (error) {
        logger.error('Failed to resend OTP', {
            error: error.message,
            email,
            userType
        });
        throw error;
    }
};

/**
 * Clean up expired OTPs and sessions (run periodically via cron)
 */
const cleanupExpiredOtps = async () => {
    try {
        const now = new Date();

        const [deletedOtps, deletedSessions] = await Promise.all([
            prisma.otpVerification.deleteMany({
                where: {
                    expires_at: {
                        lt: now
                    }
                }
            }),
            prisma.otpSession.deleteMany({
                where: {
                    expires_at: {
                        lt: now
                    }
                }
            })
        ]);

        logger.info('Cleanup completed', {
            deletedOtps: deletedOtps.count,
            deletedSessions: deletedSessions.count
        });

        return {
            deletedOtps: deletedOtps.count,
            deletedSessions: deletedSessions.count
        };
    } catch (error) {
        logger.error('Cleanup failed', { error: error.message });
        throw error;
    }
};

// ============================================================================
// EXPORTS
// ============================================================================

module.exports = {
    // Core functions
    sendOtp,
    verifyOtp,
    resendOtp,

    // Mart email verification (for owner registration)
    sendMartEmailOtp,
    verifyMartEmailOtp,

    // Registration completion
    completeOwnerRegistration,
    completeManagerRegistration,
    completeCollectionManagerRegistration,
    completeDistributionManagerRegistration,
    completeServiceManRegistration,
    completeCustomerRegistration,
    completeDeliveryRegistration,

    // Utility
    cleanupExpiredOtps,
    refreshAccessToken: refreshTokenService.rotateRefreshToken,

    // Constants (for use in controllers/routes)
    USER_TYPES,
    PURPOSE
};
