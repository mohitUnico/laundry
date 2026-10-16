const express = require('express');
const Joi = require('joi');
const { authenticateJWT, authorize } = require('../middleware/auth.middleware');
const { validate } = require('../middleware/validation.middleware');
const appConfigController = require('../controllers/app-config.controller');

const router = express.Router();

const updateSchema = Joi.object({
    value: Joi.any().required(),
});

router.get(
    '/',
    authenticateJWT,
    authorize('admin', 'owner'),
    appConfigController.listAdminConfig
);

router.put(
    '/:key',
    authenticateJWT,
    authorize('admin', 'owner'),
    validate(updateSchema),
    appConfigController.updateAdminConfig
);

module.exports = router;
