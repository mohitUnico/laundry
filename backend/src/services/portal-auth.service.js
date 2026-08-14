const crypto = require('crypto');
const prisma = require('../config/database');
const logger = require('../utils/logger');
const emailService = require('./email.service');
const { generateToken } = require('../utils/jwt');
const {
  AppError,
  ValidationError,
  AuthenticationError,
} = require('../utils/errors');

const OTP_EXPIRY_MINUTES = parseInt(process.env.PORTAL_OTP_EXPIRY_MINUTES || '5', 10);
const OTP_CLEANUP_INTERVAL_MS = parseInt(
  process.env.PORTAL_OTP_CLEANUP_INTERVAL_MS || String(5 * 60 * 1000),
  10
);
const REGISTRATION_SESSION_EXPIRY_MINUTES = parseInt(
  process.env.PORTAL_REGISTRATION_SESSION_EXPIRY_MINUTES || '30',
  10
);

let cleanupIntervalHandle = null;

const IDENTIFIER_TYPES = {
  EMAIL: 'email',
  PHONE: 'phone',
};

const generateOtp = () => Math.floor(100000 + Math.random() * 900000).toString();

const getExpiryDate = () => new Date(Date.now() + OTP_EXPIRY_MINUTES * 60 * 1000);

const normalizeIdentifier = (identifier) => {
  if (!identifier || typeof identifier !== 'string') {
    throw new ValidationError('Identifier is required');
  }

  const trimmed = identifier.trim();

  if (!trimmed) {
    throw new ValidationError('Identifier is required');
  }

  if (trimmed.includes('@')) {
    const normalizedEmail = trimmed.toLowerCase();
    return {
      type: IDENTIFIER_TYPES.EMAIL,
      value: normalizedEmail,
    };
  }

  const digits = trimmed.replace(/\D/g, '');

  if (digits.length < 6) {
    throw new ValidationError('Phone number must contain at least 6 digits');
  }

  return {
    type: IDENTIFIER_TYPES.PHONE,
    value: digits,
  };
};

const ensureJwtSecret = () => {
  if (!process.env.JWT_SECRET) {
    throw new AppError('JWT_SECRET is not configured', 500);
  }
};

const generateSessionToken = () => crypto.randomBytes(32).toString('hex');

const sanitizePhone = (value) => {
  if (!value) {
    return null;
  }

  const digits = value.replace(/\D/g, '');
  return digits || null;
};

const sendOtp = async (identifier) => {
  const normalized = normalizeIdentifier(identifier);

  // Portal flow only supports email (OtpVerification table uses email field)
  if (normalized.type !== IDENTIFIER_TYPES.EMAIL) {
    throw new ValidationError('Portal login currently only supports email. Please use your email address.');
  }

  const email = normalized.value;
  const otp = generateOtp();
  const expiresAt = getExpiryDate();
  const USER_TYPE = 'owner'; // Portal login is for owners/managers

  // Delete old sessions and OTPs for this email
  await prisma.otpSession.deleteMany({
    where: { email },
  });

  await prisma.otpVerification.deleteMany({
    where: {
      email,
      purpose: 'login_or_signup',
      user_type: USER_TYPE,
    },
  });

  // Save OTP to database
  await prisma.otpVerification.create({
    data: {
      email,
      otp_code: otp,
      purpose: 'login_or_signup',
      user_type: USER_TYPE,
      expires_at: expiresAt,
      max_attempts: 5,
    },
  });

  logger.info('Portal OTP generated', {
    email,
    expiresAt,
  });

  // Send OTP email
  try {
    await emailService.sendOtpEmail(email, otp, 'portal');
  } catch (error) {
    logger.error('Portal OTP email dispatch failed', {
      email,
      error: error.message,
    });
    throw new AppError('Failed to send OTP email. Please try again later.', 500);
  }

  // Check if user exists
  const existingUser = await prisma.user.findUnique({
    where: { email },
  });

  return {
    success: true,
    message: 'OTP sent successfully',
    data: {
      identifier: email,
      identifierType: IDENTIFIER_TYPES.EMAIL,
      isRegistered: Boolean(existingUser),
      expiresIn: OTP_EXPIRY_MINUTES * 60,
    },
  };
};

const verifyOtp = async (identifier, otp) => {
  const normalized = normalizeIdentifier(identifier);

  // Portal flow only supports email
  if (normalized.type !== IDENTIFIER_TYPES.EMAIL) {
    throw new ValidationError('Portal login currently only supports email. Please use your email address.');
  }

  const email = normalized.value;
  const USER_TYPE = 'owner';

  // Find OTP record
  const otpRecord = await prisma.otpVerification.findFirst({
    where: {
      email,
      purpose: 'login_or_signup',
      user_type: USER_TYPE,
      is_verified: false,
    },
    orderBy: { created_at: 'desc' },
  });

  if (!otpRecord) {
    throw new AuthenticationError('Invalid or expired OTP');
  }

  if (otpRecord.expires_at < new Date()) {
    await prisma.otpVerification.deleteMany({
      where: { email, purpose: 'login_or_signup', user_type: USER_TYPE },
    });
    throw new AuthenticationError('Invalid or expired OTP');
  }

  if (otpRecord.attempts >= otpRecord.max_attempts) {
    throw new AuthenticationError('Maximum verification attempts exceeded. Please request a new OTP.');
  }

  if (otpRecord.otp_code !== otp) {
    // Increment attempts
    await prisma.otpVerification.update({
      where: { otp_id: otpRecord.otp_id },
      data: { attempts: { increment: 1 } },
    });
    const remainingAttempts = otpRecord.max_attempts - (otpRecord.attempts + 1);
    throw new AuthenticationError(`Invalid OTP. ${remainingAttempts} attempt(s) remaining.`);
  }

  // Mark OTP as verified
  await prisma.otpVerification.update({
    where: { otp_id: otpRecord.otp_id },
    data: { is_verified: true },
  });

  // Check for existing user in User table
  const existingUser = await prisma.user.findUnique({
    where: { email },
  });

  // If user exists, return login response
  if (existingUser) {
    const token = generateToken(existingUser);

    logger.info('Portal OTP verified for existing user', {
      email,
      userId: existingUser.user_id,
      role: existingUser.role,
    });

    // Map User model to IUser format expected by frontend
    const user = {
      id: existingUser.user_id,
      name: existingUser.full_name,
      email: existingUser.email,
      phone: existingUser.phone,
      role: existingUser.role || 'Admin',
      createdAt: existingUser.created_at.toISOString(),
      updatedAt: existingUser.updated_at.toISOString(),
    };

    return {
      success: true,
      message: 'OTP verified successfully',
      data: {
        isRegistered: true,
        token,
        user,
      },
    };
  }

  // User doesn't exist - create registration session for new user
  const sessionToken = generateSessionToken();
  const expiresAt = new Date(Date.now() + REGISTRATION_SESSION_EXPIRY_MINUTES * 60 * 1000);

  await prisma.otpSession.upsert({
    where: { session_token: sessionToken },
    update: {
      email,
      user_type: USER_TYPE,
      is_new_user: true,
      session_token: sessionToken,
      expires_at: expiresAt,
      is_completed: false,
    },
    create: {
      email,
      user_type: USER_TYPE,
      is_new_user: true,
      session_token: sessionToken,
      expires_at: expiresAt,
      is_completed: false,
    },
  });

  logger.info('Portal OTP verified for new user', {
    email,
  });

  return {
    success: true,
    message: 'OTP verified. Complete your registration to continue.',
    data: {
      isRegistered: false,
      sessionToken,
      sessionExpiresIn: REGISTRATION_SESSION_EXPIRY_MINUTES * 60,
      identifier: email,
      identifierType: IDENTIFIER_TYPES.EMAIL,
    },
  };
};

const completeRegistration = async (sessionToken, profileData = {}) => {
  // This function is deprecated - portal registration should use completeOwnerRegistration
  // Keeping for backward compatibility but redirecting to owner registration flow
  throw new ValidationError('Please use the owner registration flow. This endpoint is deprecated.');
};

const cleanupExpiredOtps = async () => {
  const now = new Date();

  // Cleanup expired OTPs and sessions using existing tables
  const [otpResult, sessionResult] = await Promise.all([
    prisma.otpVerification.deleteMany({
      where: {
        expires_at: {
          lt: now,
        },
        purpose: 'login_or_signup',
        user_type: 'owner',
      },
    }),
    prisma.otpSession.deleteMany({
      where: {
        expires_at: {
          lt: now,
        },
        user_type: 'owner',
      },
    }),
  ]);

  if (otpResult.count > 0) {
    logger.info('Portal OTP cleanup completed', { removed: otpResult.count });
  }

  if (sessionResult.count > 0) {
    logger.info('Portal registration session cleanup completed', { removed: sessionResult.count });
  }

  return otpResult.count + sessionResult.count;
};

const startCleanupJob = () => {
  if (cleanupIntervalHandle) {
    return;
  }

  cleanupIntervalHandle = setInterval(() => {
    cleanupExpiredOtps().catch((error) => {
      logger.error('Portal OTP cleanup failed', { error: error.message });
    });
  }, OTP_CLEANUP_INTERVAL_MS);

  logger.info('Portal OTP cleanup job started', {
    intervalMs: OTP_CLEANUP_INTERVAL_MS,
  });
};

/**
 * Send OTP to mart email for verification during portal registration
 * @param {string} sessionToken - Session token from portal registration
 * @param {string} martEmail - Mart's contact email to verify
 * @returns {Promise<Object>} Send result
 */
const sendMartEmailOtp = async (sessionToken, martEmail) => {
  try {
    // Validate inputs
    if (!sessionToken || !martEmail) {
      throw new ValidationError('Session token and business email are required');
    }

    // Normalize email
    const normalizedEmail = martEmail.toLowerCase().trim();

    // Verify session exists and is valid
    const session = await prisma.otpSession.findUnique({
      where: { session_token: sessionToken },
    });

    if (!session) {
      throw new AuthenticationError('Invalid or expired session token');
    }

    if (new Date() > session.expires_at) {
      throw new AuthenticationError('Session has expired. Please start over.');
    }

    if (session.user_type !== 'owner') {
      throw new ValidationError('Session token is not for owner registration');
    }

    // Single-business: verify this business email isn't already used by LaundryConfig
    const existingConfig = await prisma.laundryConfig.findUnique({
      where: { contact_email: normalizedEmail },
    });

    if (existingConfig) {
      throw new ValidationError('This business email is already registered');
    }

    // Delete old OTPs for this mart email
    await prisma.otpVerification.deleteMany({
      where: {
        email: normalizedEmail,
        purpose: 'mart_email_verification',
        user_type: 'owner',
      },
    });

    // Generate OTP
    const otp = generateOtp();
    const expiresAt = getExpiryDate();

    // Save OTP
    await prisma.otpVerification.create({
      data: {
        email: normalizedEmail,
        otp_code: otp,
        purpose: 'mart_email_verification',
        user_type: 'owner',
        expires_at: expiresAt,
        max_attempts: 5,
      },
    });

    // Send OTP email
    await emailService.sendOtpEmail(normalizedEmail, otp, 'portal');

    logger.info('Business email OTP sent successfully', {
      businessEmail: normalizedEmail,
      sessionToken: sessionToken.substring(0, 10) + '...',
      expiresIn: OTP_EXPIRY_MINUTES * 60,
    });

    return {
      success: true,
      message: 'OTP sent successfully to business email',
      martEmail: normalizedEmail,
      expiresIn: OTP_EXPIRY_MINUTES * 60,
    };
  } catch (error) {
    logger.error('Failed to send business email OTP', {
      error: error.message,
      sessionToken: sessionToken?.substring(0, 10) + '...',
      martEmail,
    });
    throw error;
  }
};

/**
 * Verify OTP for mart email during portal registration
 * @param {string} sessionToken - Session token from portal registration
 * @param {string} martEmail - Mart's contact email
 * @param {string} otp - OTP code to verify
 * @returns {Promise<Object>} Verification result
 */
const verifyMartEmailOtp = async (sessionToken, martEmail, otp) => {
  try {
    // Validate inputs
    if (!sessionToken || !martEmail || !otp) {
      throw new ValidationError('Session token, business email, and OTP are required');
    }

    // Normalize email
    const normalizedEmail = martEmail.toLowerCase().trim();

    // Verify session exists and is valid
    const session = await prisma.otpSession.findUnique({
      where: { session_token: sessionToken },
    });

    if (!session) {
      throw new AuthenticationError('Invalid or expired session token');
    }

    if (new Date() > session.expires_at) {
      throw new AuthenticationError('Session has expired. Please start over.');
    }

    if (session.user_type !== 'owner') {
      throw new ValidationError('Session token is not for owner registration');
    }

    // Find OTP record
    const otpRecord = await prisma.otpVerification.findFirst({
      where: {
        email: normalizedEmail,
        purpose: 'mart_email_verification',
        user_type: 'owner',
        is_verified: false,
      },
      orderBy: { created_at: 'desc' },
    });

    if (!otpRecord) {
      throw new AuthenticationError('OTP not found. Please request a new OTP.');
    }

    // Check expiration
    if (new Date() > otpRecord.expires_at) {
      await prisma.otpVerification.deleteMany({
        where: {
          email: normalizedEmail,
          purpose: 'mart_email_verification',
          user_type: 'owner',
        },
      });
      throw new AuthenticationError('OTP has expired. Please request a new one.');
    }

    // Check max attempts
    if (otpRecord.attempts >= otpRecord.max_attempts) {
      throw new AuthenticationError('Maximum verification attempts exceeded. Please request a new OTP.');
    }

    // Verify OTP
    if (otpRecord.otp_code !== otp) {
      // Increment attempts
      await prisma.otpVerification.update({
        where: { otp_id: otpRecord.otp_id },
        data: { attempts: { increment: 1 } },
      });
      const remainingAttempts = otpRecord.max_attempts - (otpRecord.attempts + 1);
      throw new AuthenticationError(`Invalid OTP. ${remainingAttempts} attempt(s) remaining.`);
    }

    // Mark OTP as verified and update session
    await Promise.all([
      prisma.otpVerification.update({
        where: { otp_id: otpRecord.otp_id },
        data: { is_verified: true },
      }),
      prisma.otpSession.update({
        where: { session_token: sessionToken },
        data: {
          business_email: normalizedEmail,
          business_email_verified: true,
        },
      }),
    ]);

    logger.info('Business email OTP verified successfully', {
      businessEmail: normalizedEmail,
      sessionToken: sessionToken.substring(0, 10) + '...',
    });

    return {
      success: true,
      message: 'Business email verified successfully. You can now complete registration.',
      martEmail: normalizedEmail,
    };
  } catch (error) {
    logger.error('Business email OTP verification failed', {
      error: error.message,
      sessionToken: sessionToken?.substring(0, 10) + '...',
      martEmail,
    });
    throw error;
  }
};

/**
 * Complete owner registration (Owner + Mart) for portal flow
 * @param {string} sessionToken - Session token from portal registration
 * @param {Object} martData - Mart registration data
 * @param {Object} ownerData - Owner registration data
 * @returns {Promise<Object>} Registration result
 */
const completeOwnerRegistration = async (sessionToken, martData, ownerData) => {
  try {
    // Verify session
    const session = await prisma.otpSession.findUnique({
      where: { session_token: sessionToken },
    });

    if (!session) {
      throw new AuthenticationError('Invalid or expired session token');
    }

    if (new Date() > session.expires_at) {
      await prisma.otpSession.delete({ where: { session_id: session.session_id } }).catch(() => null);
      throw new AuthenticationError('Session has expired. Please start over.');
    }

    if (session.user_type !== 'owner') {
      throw new ValidationError('Session token is not for owner registration');
    }

    if (session.is_completed) {
      throw new ValidationError('Registration already completed');
    }

    const businessName = martData?.businessName || martData?.martName;
    const businessEmail = martData?.businessEmail || martData?.martEmail;

    if (!businessName || !businessEmail) {
      throw new ValidationError('Business name and email are required');
    }

    if (!ownerData || !ownerData.ownerName) {
      throw new ValidationError('Owner name is required');
    }

    // Normalize business email
    const normalizedBusinessEmail = businessEmail.toLowerCase().trim();

    // Single business: only one LaundryConfig can exist
    const existingBusiness = await prisma.laundryConfig.findFirst();
    if (existingBusiness) {
      throw new ValidationError('Business is already configured. Please login.');
    }

    // Ensure this business email isn't already registered
    const existingConfigByEmail = await prisma.laundryConfig.findUnique({
      where: { contact_email: normalizedBusinessEmail },
    });
    if (existingConfigByEmail) {
      throw new ValidationError('This business email is already registered');
    }

    // IMPORTANT: Check if business email is verified
    if (!session.business_email_verified || session.business_email !== normalizedBusinessEmail) {
      throw new ValidationError('Business email must be verified before completing registration');
    }

    // Get owner email from session (OtpSession uses email field)
    const ownerEmail = session.email;
    const ownerPhone = ownerData.ownerPhone || null;

    // Check if owner email already exists in User table
    if (ownerEmail) {
      const existingUser = await prisma.user.findUnique({
        where: { email: ownerEmail },
      });

      if (existingUser) {
        throw new ValidationError('This email is already registered as a user. Please use a different email.');
      }
    }

    // Check if owner phone already exists (if provided)
    if (ownerPhone) {
      const existingUserByPhone = await prisma.user.findFirst({
        where: { phone: ownerPhone },
      });

      if (existingUserByPhone) {
        throw new ValidationError('This phone number is already registered. Please use a different phone number.');
      }
    }

    // Validate owner email doesn't match mart email
    if (ownerEmail && normalizedBusinessEmail && ownerEmail.toLowerCase() === normalizedBusinessEmail.toLowerCase()) {
      throw new ValidationError('Owner email must be different from business email.');
    }

    // Validate owner phone doesn't match mart contact (if both provided)
    if (ownerPhone && martData.martContact) {
      const cleanedOwnerPhone = ownerPhone.replace(/\D/g, '');
      const cleanedMartContact = martData.martContact.replace(/\D/g, '');
      if (cleanedOwnerPhone === cleanedMartContact) {
        throw new ValidationError('Owner contact number must be different from mart contact number.');
      }
    }

    // Create mart and owner in transaction
    const result = await prisma.$transaction(async (tx) => {
      // Create LaundryConfig (single business)
      const config = await tx.laundryConfig.create({
        data: {
          business_name: businessName.trim(),
          contact_email: normalizedBusinessEmail,
          contact_phone: martData.martContact || '',
          address: martData.address || '',
          latitude: martData.martCoordinates?.latitude || 0,
          longitude: martData.martCoordinates?.longitude || 0,
          service_radius_km: martData.serviceRadiusKm || {
            tiers: [
              { minKm: 0, maxKm: 5, pricePerKm: 20 },
              { minKm: 5, maxKm: 10, pricePerKm: 40 },
            ],
            maxRadius: 10,
          },
          is_active: true,
          logo_url: martData.profileImageUrl || null,
        },
      });

      // Create owner user
      const owner = await tx.user.create({
        data: {
          full_name: ownerData.ownerName.trim(),
          email: ownerEmail,
          phone: ownerPhone,
          role: 'admin', // Business owner/admin
          is_active: true,
        },
      });

      // Mark session as completed
      await tx.otpSession.update({
        where: { session_id: session.session_id },
        data: { is_completed: true },
      });

      return { config, owner };
    });

    const token = generateToken(result.owner);

    logger.info('Portal owner registration completed', {
      email: session.email,
      configId: result.config.config_id,
      userId: result.owner.user_id,
    });

    return {
      token,
      // Backward compatible shape for existing web panel ("mart" = single business config)
      mart: {
        martId: result.config.config_id,
        martName: result.config.business_name,
        contactEmail: result.config.contact_email,
        contactPhone: result.config.contact_phone,
        address: result.config.address,
        profileImageUrl: result.config.logo_url,
      },
      owner: {
        userId: result.owner.user_id,
        fullName: result.owner.full_name,
        email: result.owner.email,
        phone: result.owner.phone,
        role: result.owner.role,
        martId: null,
      },
    };
  } catch (error) {
    logger.error('Portal owner registration failed', {
      error: error.message,
    });
    throw error;
  }
};

module.exports = {
  sendOtp,
  verifyOtp,
  completeRegistration,
  sendMartEmailOtp,
  verifyMartEmailOtp,
  completeOwnerRegistration,
  cleanupExpiredOtps,
  startCleanupJob,
};


