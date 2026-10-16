const express = require('express');
const { authenticateJWT, authorize } = require('../middleware/auth.middleware');
const { validateUuidParam } = require('../middleware/delivery-staff-app.middleware');
const adminCatalogue = require('../services/admin-catalogue.service');

const router = express.Router();

router.get('/', authenticateJWT, authorize('admin', 'owner'), async (req, res, next) => {
    try {
        const data = await adminCatalogue.listServices();
        res.status(200).json({ success: true, data });
    } catch (error) {
        next(error);
    }
});

router.post('/:serviceId/service-man/release', authenticateJWT, authorize('admin', 'owner'), validateUuidParam('serviceId'), async (req, res, next) => {
    try {
        const data = await adminCatalogue.releaseServiceMan({
            serviceId: req.params.serviceId,
            actorUserId: req.user.user_id,
        });
        res.status(200).json({ success: true, data });
    } catch (error) {
        next(error);
    }
});

router.get('/assignment-health', authenticateJWT, authorize('admin', 'owner'), async (req, res, next) => {
    try {
        const data = await adminCatalogue.assignmentHealth();
        res.status(200).json({ success: true, data });
    } catch (error) {
        next(error);
    }
});

module.exports = router;
