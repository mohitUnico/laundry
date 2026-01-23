const adminSettingsService = require('../services/admin-settings.service');
const logger = require('../utils/logger');

/**
 * Admin Settings Controller
 * - GET /api/v1/admin/settings/team-members
 */

exports.getTeamMembers = async (req, res, next) => {
    try {
        const userId = req.user?.user_id;
        logger.info('Admin settings team members request', { userId });

        const data = await adminSettingsService.getTeamMembers();

        res.status(200).json({
            success: true,
            data,
            message: 'Team members fetched successfully',
        });
    } catch (error) {
        next(error);
    }
};

module.exports = exports;

