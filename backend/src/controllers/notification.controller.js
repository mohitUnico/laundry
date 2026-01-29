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


