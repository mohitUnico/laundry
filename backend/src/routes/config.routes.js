const express = require('express');
const router = express.Router();

/**
 * Public configuration endpoint
 * Returns client-side configuration (Supabase credentials, etc.)
 * No authentication required - these are public keys meant for client apps
 */
router.get('/config', (req, res) => {
    const SUPABASE_URL = process.env.SUPABASE_URL;
    const SUPABASE_ANON_KEY = process.env.SUPABASE_ANON_KEY;

    res.status(200).json({
        success: true,
        data: {
            supabase: SUPABASE_URL && SUPABASE_ANON_KEY
                ? {
                      url: SUPABASE_URL,
                      anonKey: SUPABASE_ANON_KEY,
                  }
                : null,
        },
    });
});

module.exports = router;

