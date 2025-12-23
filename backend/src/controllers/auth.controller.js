/**
 * Authentication Controller - Email-First OTP Authentication
 * 
 * All authentication flows follow the same pattern:
 * 1. Send OTP to email
 * 2. Verify OTP (returns token if existing user, session token if new)
 * 3. If new user, complete registration with session token
 */

const otpService = require('../services/otp.service');
const portalAuthService = require('../services/portal-auth.service');
const logger = require('../utils/logger');

// ============================================================================
// PORTAL AUTHENTICATION (EMAIL/PHONE OTP)
// ============================================================================

const sendPortalOtp = async (req, res, next) => {
  try {
    const { identifier } = req.body;

    const result = await portalAuthService.sendOtp(identifier);

    res.status(200).json(result);
  } catch (error) {
    logger.error('Send portal OTP failed', { error: error.message });
    next(error);
  }
};

const verifyPortalOtp = async (req, res, next) => {
  try {
    const { identifier, otp } = req.body;

    const result = await portalAuthService.verifyOtp(identifier, otp);

    res.status(200).json(result);
  } catch (error) {
    logger.error('Verify portal OTP failed', { error: error.message });
    next(error);
  }
};

const completePortalRegistration = async (req, res, next) => {
  try {
    const { sessionToken, profile } = req.body;

    const result = await portalAuthService.completeRegistration(sessionToken, profile);

    res.status(201).json(result);
  } catch (error) {
    logger.error('Complete portal registration failed', { error: error.message });
    next(error);
  }
};

// ============================================================================
// OWNER AUTHENTICATION
// ============================================================================

/**
 * Send OTP to owner email
 * POST /api/v1/auth/owner/send-otp
 */
const sendOwnerOtp = async (req, res, next) => {
  try {
    const { email } = req.body;

    const result = await otpService.sendOtp(email, otpService.USER_TYPES.OWNER);

    res.status(200).json({
      success: true,
      message: 'OTP sent successfully to your email',
      data: {
        email,
        expiresIn: result.expiresIn
      }
    });
  } catch (error) {
    logger.error('Send owner OTP failed', { error: error.message });
    next(error);
  }
};

/**
 * Verify owner OTP
 * POST /api/v1/auth/owner/verify-otp
 * 
 * Response:
 * - Existing owner: { isNewUser: false, token, user }
 * - New owner: { isNewUser: true, sessionToken, expiresIn }
 */
const verifyOwnerOtp = async (req, res, next) => {
  try {
    const { email, otp } = req.body;

    const result = await otpService.verifyOtp(email, otp, otpService.USER_TYPES.OWNER);

    if (result.isNewUser) {
      // New owner - needs to complete registration
      res.status(200).json({
        success: true,
        message: 'Email verified. Please complete your mart registration.',
        data: {
          isNewUser: true,
          sessionToken: result.sessionToken,
          expiresIn: result.expiresIn
        }
      });
    } else {
      // Existing owner - login complete
      res.status(200).json({
        success: true,
        message: 'Login successful',
        data: {
          isNewUser: false,
          token: result.token,
          user: result.user
        }
      });
    }
  } catch (error) {
    logger.error('Verify owner OTP failed', { error: error.message });
    next(error);
  }
};

/**
 * Send OTP to mart email for verification
 * POST /api/v1/auth/owner/verify-mart-email/send-otp
 * 
 * Requires sessionToken from owner email verification
 * Supports both portal auth flow and owner auth flow
 */
const sendMartEmailOtp = async (req, res, next) => {
  try {
    const { sessionToken, martEmail, businessEmail } = req.body;
    const emailToVerify = martEmail || businessEmail;

    // Try portal auth service first (for portal registration flow)
    try {
      const result = await portalAuthService.sendMartEmailOtp(sessionToken, emailToVerify);
      return res.status(200).json({
        success: true,
        message: result.message || 'OTP sent successfully to mart email',
        data: {
          martEmail: result.martEmail,
          expiresIn: result.expiresIn
        }
      });
    } catch (portalError) {
      // If portal auth fails, try otp service (for owner auth flow)
      // Only fallback if it's an authentication error (session not found)
      if (portalError.code === 'AUTHENTICATION_ERROR' || portalError.message.includes('session')) {
        const result = await otpService.sendMartEmailOtp(sessionToken, emailToVerify);
        return res.status(200).json({
          success: true,
          message: 'OTP sent successfully to mart email',
          data: {
            martEmail: result.martEmail,
            expiresIn: result.expiresIn
          }
        });
      }
      // Re-throw if it's a different error (validation, etc.)
      throw portalError;
    }
  } catch (error) {
    logger.error('Send mart email OTP failed', { error: error.message });
    next(error);
  }
};

/**
 * Verify OTP for mart email
 * POST /api/v1/auth/owner/verify-mart-email/verify-otp
 * 
 * Requires sessionToken and mart email OTP
 * Supports both portal auth flow and owner auth flow
 */
const verifyMartEmailOtp = async (req, res, next) => {
  try {
    const { sessionToken, martEmail, businessEmail, otp } = req.body;
    const emailToVerify = martEmail || businessEmail;

    // Try portal auth service first (for portal registration flow)
    try {
      const result = await portalAuthService.verifyMartEmailOtp(sessionToken, emailToVerify, otp);
      return res.status(200).json({
        success: true,
        message: result.message,
        data: {
          martEmail: result.martEmail,
          martEmailVerified: true
        }
      });
    } catch (portalError) {
      // If portal auth fails, try otp service (for owner auth flow)
      // Only fallback if it's an authentication error (session not found)
      if (portalError.code === 'AUTHENTICATION_ERROR' || portalError.message.includes('session')) {
        const result = await otpService.verifyMartEmailOtp(sessionToken, emailToVerify, otp);
        return res.status(200).json({
          success: true,
          message: result.message,
          data: {
            martEmail: result.martEmail,
            martEmailVerified: true
          }
        });
      }
      // Re-throw if it's a different error (validation, etc.)
      throw portalError;
    }
  } catch (error) {
    logger.error('Verify mart email OTP failed', { error: error.message });
    next(error);
  }
};

/**
 * Complete owner registration (Owner + Mart)
 * POST /api/v1/auth/owner/complete-registration
 * 
 * Requires sessionToken from verify-otp response
 * Requires mart email to be verified first
 * Supports both portal auth flow and owner auth flow
 */
const completeOwnerRegistration = async (req, res, next) => {
  try {
    const { sessionToken, martData, ownerData } = req.body;

    // Try portal auth service first (for portal registration flow)
    try {
      const result = await portalAuthService.completeOwnerRegistration(
        sessionToken,
        martData,
        ownerData
      );
      return res.status(201).json({
        success: true,
        message: 'Registration completed successfully. Welcome to Laundry App!',
        data: {
          token: result.token,
          mart: result.mart,
          owner: result.owner
        }
      });
    } catch (portalError) {
      // If portal auth fails, try otp service (for owner auth flow)
      // Only fallback if it's an authentication error (session not found)
      if (portalError.code === 'AUTHENTICATION_ERROR' || portalError.message.includes('session')) {
        const result = await otpService.completeOwnerRegistration(
          sessionToken,
          martData,
          ownerData
        );
        return res.status(201).json({
          success: true,
          message: 'Registration completed successfully. Welcome to Laundry App!',
          data: {
            token: result.token,
            mart: result.mart,
            owner: result.owner
          }
        });
      }
      // Re-throw if it's a different error (validation, etc.)
      throw portalError;
    }
  } catch (error) {
    logger.error('Complete owner registration failed', { error: error.message });
    next(error);
  }
};

// ============================================================================
// MANAGER AUTHENTICATION
// ============================================================================

/**
 * Send OTP to manager email
 * POST /api/v1/auth/manager/send-otp
 */
const sendManagerOtp = async (req, res, next) => {
  try {
    const { email } = req.body;

    const result = await otpService.sendOtp(email, otpService.USER_TYPES.MANAGER);

    res.status(200).json({
      success: true,
      message: 'OTP sent successfully to your email',
      data: {
        email,
        expiresIn: result.expiresIn
      }
    });
  } catch (error) {
    logger.error('Send manager OTP failed', { error: error.message });
    next(error);
  }
};

/**
 * Verify manager OTP
 * POST /api/v1/auth/manager/verify-otp
 */
const verifyManagerOtp = async (req, res, next) => {
  try {
    const { email, otp } = req.body;

    const result = await otpService.verifyOtp(email, otp, otpService.USER_TYPES.MANAGER);

    if (result.isNewUser) {
      // New manager - needs to complete registration
      res.status(200).json({
        success: true,
        message: 'Email verified. Please complete your registration.',
        data: {
          isNewUser: true,
          sessionToken: result.sessionToken,
          expiresIn: result.expiresIn
        }
      });
    } else {
      // Existing manager - login complete
      res.status(200).json({
        success: true,
        message: 'Login successful',
        data: {
          isNewUser: false,
          token: result.token,
          user: result.user
        }
      });
    }
  } catch (error) {
    logger.error('Verify manager OTP failed', { error: error.message });
    next(error);
  }
};

/**
 * Complete manager registration
 * POST /api/v1/auth/manager/complete-registration
 * 
 * Requires:
 * - Owner token in Authorization header (Bearer token)
 * - sessionToken from verify-otp response
 * - managerData with martId (must match owner's mart)
 */
const completeManagerRegistration = async (req, res, next) => {
  try {
    const { sessionToken, managerData } = req.body;
    const ownerToken = req.user; // From authenticateJWT middleware

    // Validate token has required fields
    if (!ownerToken) {
      logger.error('No user data in token');
      return res.status(401).json({
        success: false,
        message: 'Invalid token: no user data',
        errorCode: 'AUTHENTICATION_ERROR'
      });
    }

    // Get user identifier from token (support both user_id and userId)
    const userId = ownerToken.user_id || ownerToken.userId;
    const userEmail = ownerToken.email;

    if (!userId && !userEmail) {
      logger.error('Token missing user identifier', { tokenFields: Object.keys(ownerToken) });
      return res.status(401).json({
        success: false,
        message: 'Invalid token: missing user identifier',
        errorCode: 'AUTHENTICATION_ERROR'
      });
    }

    // Fetch owner from database to get actual mart_id (token might not have it)
    const prisma = require('../config/database');
    const ownerUser = await prisma.user.findUnique({
      where: userId ? { user_id: userId } : { email: userEmail },
      select: {
        user_id: true,
        email: true,
        full_name: true,
        role: true,
        mart_id: true
      }
    });

    if (!ownerUser) {
      logger.error('Owner not found in database', {
        userId: userId || 'undefined',
        email: userEmail || 'undefined',
        tokenFields: Object.keys(ownerToken)
      });
      return res.status(401).json({
        success: false,
        message: 'Owner not found in database',
        errorCode: 'AUTHENTICATION_ERROR'
      });
    }

    // Use owner from database (not token) for verification
    const owner = {
      user_id: ownerUser.user_id,
      email: ownerUser.email,
      full_name: ownerUser.full_name,
      role: ownerUser.role,
      mart_id: ownerUser.mart_id
    };

    logger.info('Manager registration request', {
      ownerId: owner.user_id,
      ownerRole: owner.role,
      ownerMartId: owner.mart_id,
      requestMartId: managerData?.martId,
      tokenMartId: ownerToken.mart_id
    });

    // Verify owner is an owner/admin
    if (owner.role !== 'owner' && owner.role !== 'admin') {
      logger.warn('Unauthorized manager registration attempt', {
        userId: owner.user_id,
        role: owner.role
      });
      return res.status(403).json({
        success: false,
        message: 'Only mart owners can add managers',
        errorCode: 'AUTHORIZATION_ERROR'
      });
    }

    // Verify martId matches owner's mart (case-insensitive comparison for UUIDs)
    const ownerMartId = String(owner.mart_id || '').toLowerCase();
    const requestMartId = String(managerData?.martId || '').toLowerCase();

    if (!ownerMartId) {
      logger.error('Owner has no mart_id', { userId: owner.user_id });
      return res.status(400).json({
        success: false,
        message: 'Owner is not associated with any mart',
        errorCode: 'VALIDATION_ERROR'
      });
    }

    if (requestMartId !== ownerMartId) {
      logger.warn('Mart ID mismatch', {
        ownerMartId: ownerMartId,
        requestMartId: requestMartId,
        ownerId: owner.user_id
      });
      return res.status(403).json({
        success: false,
        message: 'Mart ID does not match owner\'s mart',
        errorCode: 'AUTHORIZATION_ERROR',
        details: {
          ownerMartId: ownerMartId,
          requestMartId: requestMartId
        }
      });
    }

    const result = await otpService.completeManagerRegistration(
      sessionToken,
      managerData,
      owner
    );

    res.status(201).json({
      success: true,
      message: 'Manager registration completed successfully',
      data: {
        token: result.token,
        manager: result.manager,
        owner: result.owner,
        mart: result.mart
      }
    });
  } catch (error) {
    logger.error('Complete manager registration failed', { error: error.message });
    next(error);
  }
};

// ============================================================================
// CUSTOMER AUTHENTICATION
// ============================================================================

/**
 * Send OTP to customer email
 * POST /api/v1/auth/customer/send-otp
 */
const sendCustomerOtp = async (req, res, next) => {
  try {
    const { email } = req.body;

    const result = await otpService.sendOtp(email, otpService.USER_TYPES.CUSTOMER);

    res.status(200).json({
      success: true,
      message: 'OTP sent successfully to your email',
      data: {
        email,
        expiresIn: result.expiresIn
      }
    });
  } catch (error) {
    logger.error('Send customer OTP failed', { error: error.message });
    next(error);
  }
};

/**
 * Verify customer OTP
 * POST /api/v1/auth/customer/verify-otp
 */
const verifyCustomerOtp = async (req, res, next) => {
  try {
    const { email, otp } = req.body;

    const result = await otpService.verifyOtp(email, otp, otpService.USER_TYPES.CUSTOMER);

    if (result.isNewUser) {
      // New customer - needs to complete registration
      res.status(200).json({
        success: true,
        message: 'Email verified. Please complete your profile.',
        data: {
          isNewUser: true,
          sessionToken: result.sessionToken,
          expiresIn: result.expiresIn
        }
      });
    } else {
      // Existing customer - login complete
      res.status(200).json({
        success: true,
        message: 'Login successful',
        data: {
          isNewUser: false,
          token: result.token,
          user: result.user
        }
      });
    }
  } catch (error) {
    logger.error('Verify customer OTP failed', { error: error.message });
    next(error);
  }
};

/**
 * Complete customer registration
 * POST /api/v1/auth/customer/complete-registration
 */
const completeCustomerRegistration = async (req, res, next) => {
  try {
    const { sessionToken, customerData } = req.body;

    const result = await otpService.completeCustomerRegistration(
      sessionToken,
      customerData
    );

    res.status(201).json({
      success: true,
      message: 'Registration completed successfully. Welcome to Laundry App!',
      data: {
        token: result.token,
        customer: result.customer
      }
    });
  } catch (error) {
    logger.error('Complete customer registration failed', { error: error.message });
    next(error);
  }
};

// ============================================================================
// DELIVERY STAFF AUTHENTICATION
// ============================================================================

/**
 * Send OTP to delivery staff email
 * POST /api/v1/auth/delivery/send-otp
 */
const sendDeliveryOtp = async (req, res, next) => {
  try {
    const { email } = req.body;

    const result = await otpService.sendOtp(email, otpService.USER_TYPES.DELIVERY_STAFF);

    res.status(200).json({
      success: true,
      message: 'OTP sent successfully to your email',
      data: {
        email,
        expiresIn: result.expiresIn
      }
    });
  } catch (error) {
    logger.error('Send delivery OTP failed', { error: error.message });
    next(error);
  }
};

/**
 * Verify delivery staff OTP
 * POST /api/v1/auth/delivery/verify-otp
 */
const verifyDeliveryOtp = async (req, res, next) => {
  try {
    const { email, otp } = req.body;

    const result = await otpService.verifyOtp(email, otp, otpService.USER_TYPES.DELIVERY_STAFF);

    if (result.isNewUser) {
      // New delivery staff - needs to complete registration
      res.status(200).json({
        success: true,
        message: 'Email verified. Please complete your registration.',
        data: {
          isNewUser: true,
          sessionToken: result.sessionToken,
          expiresIn: result.expiresIn
        }
      });
    } else {
      // Existing delivery staff - login complete
      res.status(200).json({
        success: true,
        message: 'Login successful',
        data: {
          isNewUser: false,
          token: result.token,
          user: result.user
        }
      });
    }
  } catch (error) {
    logger.error('Verify delivery OTP failed', { error: error.message });
    next(error);
  }
};

/**
 * Complete delivery staff registration
 * POST /api/v1/auth/delivery/complete-registration
 */
const completeDeliveryRegistration = async (req, res, next) => {
  try {
    const { sessionToken, deliveryData } = req.body;

    const result = await otpService.completeDeliveryRegistration(
      sessionToken,
      deliveryData
    );

    res.status(201).json({
      success: true,
      message: 'Registration completed successfully. Welcome to our delivery team!',
      data: {
        token: result.token,
        deliveryStaff: result.deliveryStaff
      }
    });
  } catch (error) {
    logger.error('Complete delivery registration failed', { error: error.message });
    next(error);
  }
};

// ============================================================================
// COLLECTION MANAGER AUTHENTICATION
// ============================================================================

/**
 * Send OTP to collection manager email
 * POST /api/v1/auth/collection-manager/send-otp
 */
const sendCollectionManagerOtp = async (req, res, next) => {
  try {
    const { email } = req.body;

    const result = await otpService.sendOtp(email, otpService.USER_TYPES.COLLECTION_MANAGER);

    res.status(200).json({
      success: true,
      message: 'OTP sent successfully to your email',
      data: {
        email,
        expiresIn: result.expiresIn
      }
    });
  } catch (error) {
    logger.error('Send collection manager OTP failed', { error: error.message });
    next(error);
  }
};

/**
 * Verify collection manager OTP
 * POST /api/v1/auth/collection-manager/verify-otp
 */
const verifyCollectionManagerOtp = async (req, res, next) => {
  try {
    const { email, otp } = req.body;

    const result = await otpService.verifyOtp(email, otp, otpService.USER_TYPES.COLLECTION_MANAGER);

    if (result.isNewUser) {
      res.status(200).json({
        success: true,
        message: 'Email verified. Awaiting owner approval to complete your profile.',
        data: {
          isNewUser: true,
          sessionToken: result.sessionToken,
          expiresIn: result.expiresIn
        }
      });
    } else {
      res.status(200).json({
        success: true,
        message: 'Login successful',
        data: {
          isNewUser: false,
          token: result.token,
          user: result.user
        }
      });
    }
  } catch (error) {
    logger.error('Verify collection manager OTP failed', { error: error.message });
    next(error);
  }
};

/**
 * Complete collection manager registration
 * POST /api/v1/auth/collection-manager/complete-registration
 *
 * Requires owner/admin token in Authorization header.
 */
const completeCollectionManagerRegistration = async (req, res, next) => {
  try {
    const { sessionToken, collectionManagerData } = req.body;

    const result = await otpService.completeCollectionManagerRegistration(
      sessionToken,
      collectionManagerData,
      req.user
    );

    res.status(201).json({
      success: true,
      message: 'Collection manager registration completed successfully',
      data: {
        token: result.token,
        collectionManager: result.collectionManager
      }
    });
  } catch (error) {
    logger.error('Complete collection manager registration failed', { error: error.message });
    next(error);
  }
};

// ============================================================================
// DISTRIBUTION MANAGER AUTHENTICATION
// ============================================================================

/**
 * Send OTP to distribution manager email
 * POST /api/v1/auth/distribution-manager/send-otp
 */
const sendDistributionManagerOtp = async (req, res, next) => {
  try {
    const { email } = req.body;

    const result = await otpService.sendOtp(email, otpService.USER_TYPES.DISTRIBUTION_MANAGER);

    res.status(200).json({
      success: true,
      message: 'OTP sent successfully to your email',
      data: {
        email,
        expiresIn: result.expiresIn
      }
    });
  } catch (error) {
    logger.error('Send distribution manager OTP failed', { error: error.message });
    next(error);
  }
};

/**
 * Verify distribution manager OTP
 * POST /api/v1/auth/distribution-manager/verify-otp
 */
const verifyDistributionManagerOtp = async (req, res, next) => {
  try {
    const { email, otp } = req.body;

    const result = await otpService.verifyOtp(email, otp, otpService.USER_TYPES.DISTRIBUTION_MANAGER);

    if (result.isNewUser) {
      res.status(200).json({
        success: true,
        message: 'Email verified. Awaiting owner approval to complete your profile.',
        data: {
          isNewUser: true,
          sessionToken: result.sessionToken,
          expiresIn: result.expiresIn
        }
      });
    } else {
      res.status(200).json({
        success: true,
        message: 'Login successful',
        data: {
          isNewUser: false,
          token: result.token,
          user: result.user
        }
      });
    }
  } catch (error) {
    logger.error('Verify distribution manager OTP failed', { error: error.message });
    next(error);
  }
};

/**
 * Complete distribution manager registration
 * POST /api/v1/auth/distribution-manager/complete-registration
 *
 * Requires owner/admin token in Authorization header.
 */
const completeDistributionManagerRegistration = async (req, res, next) => {
  try {
    const { sessionToken, distributionManagerData } = req.body;

    const result = await otpService.completeDistributionManagerRegistration(
      sessionToken,
      distributionManagerData,
      req.user
    );

    res.status(201).json({
      success: true,
      message: 'Distribution manager registration completed successfully',
      data: {
        token: result.token,
        distributionManager: result.distributionManager
      }
    });
  } catch (error) {
    logger.error('Complete distribution manager registration failed', { error: error.message });
    next(error);
  }
};

// ============================================================================
// SERVICE MAN AUTHENTICATION
// ============================================================================

/**
 * Send OTP to service man email
 * POST /api/v1/auth/service-man/send-otp
 *
 * NOTE: requires serviceType/serviceId in request (validated at route layer)
 */
const sendServiceManOtp = async (req, res, next) => {
  try {
    const { email } = req.body;

    const result = await otpService.sendOtp(email, otpService.USER_TYPES.SERVICE_MAN);

    res.status(200).json({
      success: true,
      message: 'OTP sent successfully to your email',
      data: {
        email,
        expiresIn: result.expiresIn
      }
    });
  } catch (error) {
    logger.error('Send service man OTP failed', { error: error.message });
    next(error);
  }
};

/**
 * Verify service man OTP
 * POST /api/v1/auth/service-man/verify-otp
 *
 * Requires serviceType/serviceId in request so we can enforce that the login is for the correct service.
 */
const verifyServiceManOtp = async (req, res, next) => {
  try {
    const { email, otp } = req.body;

    const result = await otpService.verifyOtp(email, otp, otpService.USER_TYPES.SERVICE_MAN);

    if (result.isNewUser) {
      res.status(200).json({
        success: true,
        message: 'Email verified. Awaiting owner approval to complete your profile.',
        data: {
          isNewUser: true,
          sessionToken: result.sessionToken,
          expiresIn: result.expiresIn
        }
      });
    } else {
      res.status(200).json({
        success: true,
        message: 'Login successful',
        data: {
          isNewUser: false,
          token: result.token,
          user: result.user
        }
      });
    }
  } catch (error) {
    logger.error('Verify service man OTP failed', { error: error.message });
    next(error);
  }
};

/**
 * Complete service man registration
 * POST /api/v1/auth/service-man/complete-registration
 *
 * Requires owner/admin token in Authorization header.
 */
const completeServiceManRegistration = async (req, res, next) => {
  try {
    const { sessionToken, serviceManData } = req.body;

    const result = await otpService.completeServiceManRegistration(sessionToken, serviceManData, req.user);

    res.status(201).json({
      success: true,
      message: 'Service man registration completed successfully',
      data: {
        token: result.token,
        serviceMan: result.serviceMan
      }
    });
  } catch (error) {
    logger.error('Complete service man registration failed', { error: error.message });
    next(error);
  }
};

// ============================================================================
// COMMON ENDPOINTS
// ============================================================================

/**
 * Resend OTP
 * POST /api/v1/auth/resend-otp
 */
const resendOtp = async (req, res, next) => {
  try {
    const { email, userType } = req.body;

    const result = await otpService.resendOtp(email, userType);

    res.status(200).json({
      success: true,
      message: 'OTP resent successfully to your email',
      data: {
        email,
        expiresIn: result.expiresIn
      }
    });
  } catch (error) {
    logger.error('Resend OTP failed', { error: error.message });
    next(error);
  }
};

/**
 * Logout
 * POST /api/v1/auth/logout
 * 
 * Note: Since we're using JWT, logout is handled client-side by removing the token.
 * This endpoint is provided for consistency and can be used for logging/analytics.
 */
const logout = async (req, res, next) => {
  try {
    // In a stateless JWT system, we don't need to do anything server-side
    // The client should remove the token from storage

    logger.info('User logged out', {
      userId: req.user?.userId,
      email: req.user?.email
    });

    res.status(200).json({
      success: true,
      message: 'Logged out successfully'
    });
  } catch (error) {
    logger.error('Logout failed', { error: error.message });
    next(error);
  }
};

// ============================================================================
// EXPORTS
// ============================================================================

module.exports = {
  // Portal login
  sendPortalOtp,
  verifyPortalOtp,
  completePortalRegistration,

  // Owner
  sendOwnerOtp,
  verifyOwnerOtp,
  sendMartEmailOtp,
  verifyMartEmailOtp,
  completeOwnerRegistration,

  // Manager
  sendManagerOtp,
  verifyManagerOtp,
  completeManagerRegistration,

  // Customer
  sendCustomerOtp,
  verifyCustomerOtp,
  completeCustomerRegistration,

  // Delivery
  sendDeliveryOtp,
  verifyDeliveryOtp,
  completeDeliveryRegistration,

  // Collection manager
  sendCollectionManagerOtp,
  verifyCollectionManagerOtp,
  completeCollectionManagerRegistration,

  // Distribution manager
  sendDistributionManagerOtp,
  verifyDistributionManagerOtp,
  completeDistributionManagerRegistration,

  // Service man
  sendServiceManOtp,
  verifyServiceManOtp,
  completeServiceManRegistration,

  // Common
  resendOtp,
  logout
};
