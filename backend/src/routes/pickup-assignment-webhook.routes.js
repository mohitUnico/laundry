const express = require('express');
const pickupAssignmentWebhookController = require('../controllers/pickup-assignment-webhook.controller');

const router = express.Router();

/**
 * Webhook endpoint for processing pickup assignments
 * This endpoint can be called by:
 * - Database triggers (via pg_net/http extension)
 * - pg_cron scheduled jobs
 * - External schedulers
 * - Manual triggers
 * 
 * Security: Protected by webhook secret token (if configured)
 */
router.post('/process', pickupAssignmentWebhookController.processPickupAssignments);

/**
 * Process pickup assignment for a specific order
 * Useful for immediate processing when pickup_time_from is set
 */
router.post('/process/:orderId', pickupAssignmentWebhookController.processOrderPickupAssignment);

module.exports = router;

