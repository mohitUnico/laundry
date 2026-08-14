const adminSettingsService = require('../services/admin-settings.service');
const logger = require('../utils/logger');

/**
 * Admin Settings Controller
 * - Team member management (owners + staff)
 */

exports.getTeamMembers = async (req, res, next) => {
    try {
        const userId = req.user?.user_id;
        logger.info('Admin team members request', { userId });

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

// Backwards-compatible alias (older route/controller name)
exports.getTeamMembersGrouped = exports.getTeamMembers;

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

