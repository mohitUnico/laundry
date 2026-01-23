const express = require('express');
const adminSettingsController = require('../controllers/admin-settings.controller');
const { authenticateJWT, authorize } = require('../middleware/auth.middleware');

const router = express.Router();

/**
 * Admin Settings Routes
 *
 * Endpoints:
 * - GET /api/v1/admin/settings/team-members
 */

router.get(
    '/team-members',
    authenticateJWT,
    authorize('super_admin', 'owner', 'admin', 'manager'),
    adminSettingsController.getTeamMembers
);

module.exports = router;

