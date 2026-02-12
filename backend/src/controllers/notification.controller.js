const prisma = require('../config/database');
const { ValidationError } = require('../utils/errors');

/**
 * Save/update the customer's FCM token.
 * Customer JWT required: req.user.user_id is customer_id in this codebase.
 */
exports.saveCustomerFcmToken = async (req, res, next) => {
    try {
        const customerId = req.user?.user_id;
        const fcmToken = req.body?.fcmToken;

        if (!customerId) {
            throw new ValidationError('Missing customer identity');
        }
        if (!fcmToken || typeof fcmToken !== 'string') {
            throw new ValidationError('fcmToken is required');
        }

        await prisma.customer.update({
            where: { customer_id: customerId },
            data: { fcm_token: fcmToken.trim() },
            select: { customer_id: true },
        });

        res.status(200).json({
            success: true,
            message: 'FCM token saved',
        });
    } catch (error) {
        next(error);
    }
};

/**
 * Clear the customer's FCM token only if it matches the token provided by the device.
 * Prevents Device A logout from clearing Device B's token when both use same account.
 */
exports.clearCustomerFcmTokenIfMatches = async (req, res, next) => {
    try {
        const customerId = req.user?.user_id;
        const providedToken = req.body?.fcmToken;

        if (!customerId) {
            throw new ValidationError('Missing customer identity');
        }
        if (!providedToken || typeof providedToken !== 'string') {
            throw new ValidationError('fcmToken is required');
        }

        const current = await prisma.customer.findUnique({
            where: { customer_id: customerId },
            select: { fcm_token: true },
        });

        if (current?.fcm_token && current.fcm_token === providedToken.trim()) {
            await prisma.customer.update({
                where: { customer_id: customerId },
                data: { fcm_token: null },
                select: { customer_id: true },
            });
        }

        res.status(200).json({
            success: true,
            message: 'FCM token cleared if matched',
        });
    } catch (error) {
        next(error);
    }
};

