const express = require('express');
const appConfigController = require('../controllers/app-config.controller');

const router = express.Router();

/**
 * Public configuration for mobile clients.
 * Existing polling intervals plus v2 client-safe tunables.
 */
router.get('/', appConfigController.getPublicConfig);

module.exports = router;
