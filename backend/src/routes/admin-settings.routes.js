const express = require('express');
const adminSettingsController = require('../controllers/admin-settings.controller');
const { authenticateJWT, authorize } = require('../middleware/auth.middleware');
const { validate, validateQuery } = require('../middleware/validation.middleware');
const { listTeamMembersQuerySchema, createTeamMemberSchema } = require('../validators/admin-settings.validator');

const router = express.Router();

/**
 * Admin Settings Routes
 *
 * Endpoints:
 * - GET /api/v1/admin/settings/team-members
 * - POST /api/v1/admin/settings/team-members
 */

router.get(
    '/team-members',
    authenticateJWT,
    authorize('super_admin', 'owner', 'admin', 'manager'),
    validateQuery(listTeamMembersQuerySchema),
    adminSettingsController.getTeamMembers
);

router.post(
    '/team-members',
    authenticateJWT,
    authorize('super_admin', 'owner', 'admin'),
    validate(createTeamMemberSchema),
    adminSettingsController.createTeamMember
);

module.exports = router;

