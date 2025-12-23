/**
 * Authentication Routes - Email-First OTP Flow
 * 
 * All authentication flows:
 * 1. Send OTP to email
 * 2. Verify OTP (login if existing, or get session token if new)
 * 3. If new, complete registration with session token
 */

const express = require('express');
const router = express.Router();
const authController = require('../controllers/auth.controller');
const { validate } = require('../middleware/validation.middleware');
const { authenticateJWT, authorize } = require('../middleware/auth.middleware');
const {
  sendOtpSchema,
  sendPortalOtpSchema,
  verifyOtpSchema,
  verifyPortalOtpSchema,
  completeOwnerRegistrationSchema,
  completePortalRegistrationSchema,
  completeManagerRegistrationSchema,
  completeCustomerRegistrationSchema,
  completeDeliveryRegistrationSchema,
  resendOtpSchema
} = require('../validators/auth.validator');

// ============================================================================
// HELPERS (BACKWARD COMPATIBILITY)
// ============================================================================

/**
 * Some older Postman collections send delivery OTP requests with a nested payload:
 * { deliveryData: { email: "..." }, ... }
 *
 * The canonical API expects: { email: "..." }
 * This middleware normalizes the request so validation passes.
 */
const normalizeDeliveryEmailBody = (req, res, next) => {
  if (!req.body?.email && req.body?.deliveryData?.email) {
    req.body.email = req.body.deliveryData.email;
  }
  next();
};

// ============================================================================
// OWNER AUTHENTICATION ROUTES
// ============================================================================

/**
 * @route   POST /api/v1/auth/send-otp
 * @desc    Send OTP to email or phone identifier for portal login
 * @access  Public
 * @body    { identifier: "user@example.com" | "9876543210" }
 */
router.post(
  '/send-otp',
  validate(sendPortalOtpSchema),
  authController.sendPortalOtp
);

/**
 * @route   POST /api/v1/auth/verify-otp
 * @desc    Verify OTP for portal login
 * @access  Public
 * @body    { identifier: "user@example.com" | "9876543210", otp: "123456" }
 */
router.post(
  '/verify-otp',
  validate(verifyPortalOtpSchema),
  authController.verifyPortalOtp
);

/**
 * @route   POST /api/v1/auth/portal/complete-registration
 * @desc    Complete registration for new portal user after OTP verification
 * @access  Public
 * @body    {
 *            sessionToken: "abc123...",
 *            profile: {
 *              name: "User Name",
 *              email?: "user@example.com",
 *              phone?: "9876543210"
 *            }
 *          }
 */
router.post(
  '/portal/complete-registration',
  validate(completePortalRegistrationSchema),
  authController.completePortalRegistration
);

/**
 * @route   POST /api/v1/auth/owner/send-otp
 * @desc    Send OTP to owner email for login or signup
 * @access  Public
 * @body    { email: "owner@example.com" }
 */
router.post(
  '/owner/send-otp',
  validate(sendOtpSchema),
  authController.sendOwnerOtp
);

/**
 * @route   POST /api/v1/auth/owner/verify-otp
 * @desc    Verify OTP and check if owner exists
 * @access  Public
 * @body    { email: "owner@example.com", otp: "123456" }
 * @returns Existing owner: { isNewUser: false, token, user }
 *          New owner: { isNewUser: true, sessionToken, expiresIn }
 */
router.post(
  '/owner/verify-otp',
  validate(verifyOtpSchema),
  authController.verifyOwnerOtp
);

/**
 * @route   POST /api/v1/auth/owner/verify-mart-email/send-otp
 * @desc    Send OTP to mart email for verification during owner registration
 * @access  Public (requires sessionToken)
 * @body    { sessionToken: "abc123...", martEmail: "mart@example.com" }
 */
router.post(
  '/owner/verify-mart-email/send-otp',
  authController.sendMartEmailOtp
);

/**
 * @route   POST /api/v1/auth/owner/verify-mart-email/verify-otp
 * @desc    Verify OTP for mart email
 * @access  Public (requires sessionToken)
 * @body    { sessionToken: "abc123...", martEmail: "mart@example.com", otp: "123456" }
 */
router.post(
  '/owner/verify-mart-email/verify-otp',
  authController.verifyMartEmailOtp
);

/**
 * @route   POST /api/v1/auth/owner/complete-registration
 * @desc    Complete owner + mart registration after OTP verification
 * @access  Public (requires sessionToken and mart email verified)
 * @body    {
 *            sessionToken: "abc123...",
 *            martData: { 
 *              martName, martEmail, martContact, profileImageUrl, 
 *              martCoordinates: { latitude, longitude }
 *            },
 *            ownerData: { ownerName, ownerPhone, ownerEmail }
 *          }
 */
router.post(
  '/owner/complete-registration',
  validate(completeOwnerRegistrationSchema),
  authController.completeOwnerRegistration
);

// ============================================================================
// MANAGER AUTHENTICATION ROUTES
// ============================================================================

/**
 * @route   POST /api/v1/auth/manager/send-otp
 * @desc    Send OTP to manager email for login or signup
 * @access  Public
 * @body    { email: "manager@example.com" }
 */
router.post(
  '/manager/send-otp',
  validate(sendOtpSchema),
  authController.sendManagerOtp
);

/**
 * @route   POST /api/v1/auth/manager/verify-otp
 * @desc    Verify OTP and check if manager exists
 * @access  Public
 * @body    { email: "manager@example.com", otp: "123456" }
 */
router.post(
  '/manager/verify-otp',
  validate(verifyOtpSchema),
  authController.verifyManagerOtp
);

/**
 * @route   POST /api/v1/auth/manager/complete-registration
 * @desc    Complete manager registration after OTP verification
 * @access  Private (requires owner token in Authorization header)
 * @headers Authorization: Bearer {owner_token}
 * @body    {
 *            sessionToken: "abc123...",
 *            managerData: {
 *              martId: "uuid",
 *              fullName: "Manager Name",
 *              phone: "9876543210" (optional)
 *            }
 *          }
 * @returns {
 *            success: true,
 *            message: "Manager registration completed successfully",
 *            data: {
 *              token: "manager_jwt_token",
 *              manager: { userId, fullName, email, role, martId },
 *              owner: { userId, fullName, email, phone, role, martId },
 *              mart: { martId, martName, contactEmail, contactPhone, address, profileImageUrl }
 *            }
 *          }
 */
router.post(
  '/manager/complete-registration',
  authenticateJWT,
  authorize('owner', 'admin'),
  validate(completeManagerRegistrationSchema),
  authController.completeManagerRegistration
);

// ============================================================================
// CUSTOMER AUTHENTICATION ROUTES
// ============================================================================

/**
 * @route   POST /api/v1/auth/customer/send-otp
 * @desc    Send OTP to customer email for login or signup
 * @access  Public
 * @body    { email: "customer@example.com" }
 */
router.post(
  '/customer/send-otp',
  validate(sendOtpSchema),
  authController.sendCustomerOtp
);

/**
 * @route   POST /api/v1/auth/customer/verify-otp
 * @desc    Verify OTP and check if customer exists
 * @access  Public
 * @body    { email: "customer@example.com", otp: "123456" }
 */
router.post(
  '/customer/verify-otp',
  validate(verifyOtpSchema),
  authController.verifyCustomerOtp
);

/**
 * @route   POST /api/v1/auth/customer/complete-registration
 * @desc    Complete customer registration after OTP verification
 * @access  Public (requires sessionToken)
 * @body    {
 *            sessionToken: "abc123...",
 *            customerData: { 
 *              fullName, 
 *              phone, 
 *              address: { addressLabel, address, latitude, longitude }
 *            }
 *          }
 */
router.post(
  '/customer/complete-registration',
  validate(completeCustomerRegistrationSchema),
  authController.completeCustomerRegistration
);

// ============================================================================
// DELIVERY STAFF AUTHENTICATION ROUTES
// ============================================================================

/**
 * @route   POST /api/v1/auth/delivery/send-otp
 * @desc    Send OTP to delivery staff email for login or signup
 * @access  Public
 * @body    { email: "delivery@example.com" }
 */
router.post(
  '/delivery/send-otp',
  validate(sendOtpSchema),
  authController.sendDeliveryOtp
);

/**
 * Backward-compatible alias (older Postman collections / docs)
 * @route   POST /api/v1/auth/delivery/login/send-otp
 * @desc    Send OTP to delivery staff email for login or signup
 * @access  Public
 * @deprecated Use /api/v1/auth/delivery/send-otp
 */
router.post(
  '/delivery/login/send-otp',
  normalizeDeliveryEmailBody,
  validate(sendOtpSchema),
  authController.sendDeliveryOtp
);

/**
 * @route   POST /api/v1/auth/delivery/verify-otp
 * @desc    Verify OTP and check if delivery staff exists
 * @access  Public
 * @body    { email: "delivery@example.com", otp: "123456" }
 */
router.post(
  '/delivery/verify-otp',
  validate(verifyOtpSchema),
  authController.verifyDeliveryOtp
);

/**
 * Backward-compatible alias (older Postman collections / docs)
 * @route   POST /api/v1/auth/delivery/login/verify-otp
 * @desc    Verify OTP and check if delivery staff exists
 * @access  Public
 * @deprecated Use /api/v1/auth/delivery/verify-otp
 */
router.post(
  '/delivery/login/verify-otp',
  normalizeDeliveryEmailBody,
  validate(verifyOtpSchema),
  authController.verifyDeliveryOtp
);

/**
 * @route   POST /api/v1/auth/delivery/complete-registration
 * @desc    Complete delivery staff registration after OTP verification
 * @access  Public (requires sessionToken)
 * @body    {
 *            sessionToken: "abc123...",
 *            deliveryData: { fullName, phone, vehicleType, vehicleNumber, licenseNumber }
 *          }
 */
router.post(
  '/delivery/complete-registration',
  validate(completeDeliveryRegistrationSchema),
  authController.completeDeliveryRegistration
);

// ============================================================================
// COMMON ROUTES
// ============================================================================

/**
 * @route   POST /api/v1/auth/resend-otp
 * @desc    Resend OTP to email
 * @access  Public
 * @body    { email: "user@example.com", userType: "owner" | "manager" | "customer" | "delivery_staff" }
 */
router.post(
  '/resend-otp',
  validate(resendOtpSchema),
  authController.resendOtp
);

/**
 * @route   POST /api/v1/auth/logout
 * @desc    Logout user (client-side token removal)
 * @access  Public
 */
router.post('/logout', authController.logout);

module.exports = router;
