const adminDeliveryStaffManagementService = require('../services/admin-delivery-staff-management.service');
const logger = require('../utils/logger');

/**
 * Admin Delivery Staff Management Controller
 * - GET /api/v1/admin/delivery-staff
 * - PATCH /api/v1/admin/delivery-staff/:staffId/verify
 */

exports.listDeliveryStaffs = async (req, res, next) => {
    try {
        const userId = req.user?.user_id;
        logger.info('Admin delivery staff list request', { userId, query: req.query });

        const data = await adminDeliveryStaffManagementService.getAdminDeliveryStaffs(req.query);

        res.status(200).json({
            success: true,
            data,
            message: 'Delivery staffs fetched successfully',
        });
    } catch (error) {
        next(error);
    }
};

exports.verifyDeliveryStaff = async (req, res, next) => {
    try {
        const userId = req.user?.user_id;
        const { staffId } = req.params;

        logger.info('Admin delivery staff verify request', { userId, staffId });

        const updated = await adminDeliveryStaffManagementService.verifyDeliveryStaff(staffId);

        res.status(200).json({
            success: true,
            data: {
                staffId: updated.staff_id,
                fullName: updated.full_name,
                email: updated.email,
                phone: updated.phone,
                verificationStatus: updated.verification_status,
                isVerifiedByAdmin: updated.is_verified_by_admin,
                updatedAt: updated.updated_at,
            },
            message: 'Delivery staff verified successfully',
        });
    } catch (error) {
        next(error);
    }
};

module.exports = exports;

