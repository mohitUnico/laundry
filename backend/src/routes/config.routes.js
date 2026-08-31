const express = require('express');
const router = express.Router();

/**
 * Public configuration endpoint for mobile clients.
 * Returns polling intervals (ms) used instead of Supabase Realtime.
 */
router.get('/', (req, res) => {
    res.status(200).json({
        success: true,
        data: {
            polling: {
                ordersIntervalMs: parseInt(process.env.POLLING_ORDERS_MS || '15000', 10),
                couponsIntervalMs: parseInt(process.env.POLLING_COUPONS_MS || '30000', 10),
                trackingIntervalMs: parseInt(process.env.POLLING_TRACKING_MS || '5000', 10),
                deliveryHomeIntervalMs: parseInt(process.env.POLLING_DELIVERY_HOME_MS || '15000', 10),
            },
        },
    });
});

module.exports = router;
