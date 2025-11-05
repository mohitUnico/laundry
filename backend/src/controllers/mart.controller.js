/**
 * Mart Controller
 * Handles HTTP requests for mart operations
 */

const martService = require('../services/mart.service');
const otpService = require('../services/otp.service');
const logger = require('../utils/logger');
const { ValidationError } = require('../utils/errors');

/**
 * Complete mart registration after OTP verifications
 * POST /api/v1/marts/register
 * NOTE: Both mart phone and owner phone must be verified via OTP before calling this
 */
exports.registerMart = async (req, res, next) => {
    try {
        const martData = req.body;

        // Verify mart phone OTP status
        const martPhoneVerified = await otpService.isPhoneVerified(
            martData.contactPhone,
            'mart_signup'
        );

        if (!martPhoneVerified) {
            throw new ValidationError('Mart phone number is not verified. Please verify via OTP first.');
        }

        // Verify owner phone OTP status
        const ownerPhoneVerified = await otpService.isPhoneVerified(
            martData.owner.phone,
            'owner_signup'
        );

        if (!ownerPhoneVerified) {
            throw new ValidationError('Owner phone number is not verified. Please verify via OTP first.');
        }

        // Register mart with verification flags
        const result = await martService.registerMart(martData, true, true);

        logger.info('Mart registration completed', {
            martId: result.mart.mart_id,
            ownerId: result.owner.user_id,
            correlationId: req.correlationId,
        });

        res.status(201).json({
            success: true,
            data: result,
            message: 'Mart registered successfully',
        });
    } catch (error) {
        next(error);
    }
};

/**
 * Get mart by ID
 * GET /api/v1/marts/:martId
 */
exports.getMartById = async (req, res, next) => {
    try {
        const { martId } = req.params;
        const mart = await martService.getMartById(martId);

        res.status(200).json({
            success: true,
            data: mart,
        });
    } catch (error) {
        next(error);
    }
};

/**
 * Get all users of a mart
 * GET /api/v1/marts/:martId/users
 */
exports.getMartUsers = async (req, res, next) => {
    try {
        const { martId } = req.params;
        const users = await martService.getMartUsers(martId);

        res.status(200).json({
            success: true,
            data: users,
        });
    } catch (error) {
        next(error);
    }
};

/**
 * Update mart details
 * PATCH /api/v1/marts/:martId
 */
exports.updateMart = async (req, res, next) => {
    try {
        const { martId } = req.params;
        const updateData = req.body;

        const mart = await martService.updateMart(martId, updateData);

        logger.info('Mart updated', {
            martId,
            correlationId: req.correlationId,
        });

        res.status(200).json({
            success: true,
            data: mart,
            message: 'Mart updated successfully',
        });
    } catch (error) {
        next(error);
    }
};

/**
 * Deactivate mart
 * DELETE /api/v1/marts/:martId
 */
exports.deactivateMart = async (req, res, next) => {
    try {
        const { martId } = req.params;

        await martService.deactivateMart(martId);

        logger.info('Mart deactivated', {
            martId,
            correlationId: req.correlationId,
        });

        res.status(200).json({
            success: true,
            message: 'Mart deactivated successfully',
        });
    } catch (error) {
        next(error);
    }
};

module.exports = exports;
