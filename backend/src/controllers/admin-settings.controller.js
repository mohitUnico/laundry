const adminSettingsService = require('../services/admin-settings.service');
const logger = require('../utils/logger');

/**
 * Admin Settings Controller
 * - Team member management (owners + staff)
 */

exports.getTeamMembersGrouped = async (req, res, next) => {
    try {
        const userId = req.user?.user_id;
        logger.info('Admin team members grouped request', { userId });

        const data = await adminSettingsService.getTeamMembersGrouped();

        res.status(200).json({
            success: true,
            data,
            message: 'Team members fetched successfully',
        });
    } catch (error) {
        next(error);
    }
};

exports.createTeamMember = async (req, res, next) => {
    try {
        const userId = req.user?.user_id;
        logger.info('Admin create team member request', { userId, role: req.body?.role });

        const created = await adminSettingsService.createTeamMember(req.body);

        res.status(201).json({
            success: true,
            data: created,
            message: 'Team member created successfully',
        });
    } catch (error) {
        next(error);
    }
};

module.exports = exports;

