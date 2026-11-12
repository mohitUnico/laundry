const express = require('express');
const { authenticateJWT, authorize } = require('../middleware/auth.middleware');
const slotsService = require('../services/slots.service');

const router = express.Router();

router.get('/', authenticateJWT, authorize('customer'), async (req, res, next) => {
    try {
        const data = await slotsService.listSlots();
        res.status(200).json({ success: true, data });
    } catch (error) {
        next(error);
    }
});

module.exports = router;
