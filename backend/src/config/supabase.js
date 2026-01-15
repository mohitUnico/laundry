/**
 * Supabase client (server-side)
 *
 * Uses SERVICE ROLE key so it must only be used on backend.
 *
 * Note: this is lazy-initialized so the app can still boot without Supabase
 * configured (only endpoints that need it will fail with a clear error).
 */
const { createClient } = require('@supabase/supabase-js');

let _client = null;

function getSupabaseClient() {
    if (_client) return _client;

    const SUPABASE_URL = process.env.SUPABASE_URL;
    const SUPABASE_SERVICE_ROLE_KEY = process.env.SUPABASE_SERVICE_ROLE_KEY;

    if (!SUPABASE_URL) {
        throw new Error('SUPABASE_URL is not defined in environment variables');
    }
    if (!SUPABASE_SERVICE_ROLE_KEY) {
        throw new Error('SUPABASE_SERVICE_ROLE_KEY is not defined in environment variables');
    }

    _client = createClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY, {
        auth: {
            persistSession: false,
            autoRefreshToken: false,
            detectSessionInUrl: false,
        },
    });

    return _client;
}

module.exports = {
    getSupabaseClient,
};

