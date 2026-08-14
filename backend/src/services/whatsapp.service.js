/**
 * WhatsApp Notification Service
 * Sends order updates and notifications to customers via WhatsApp (Twilio WhatsApp API).
 * Works alongside FCM: same events (e.g. order status change) can trigger both push and WhatsApp.
 *
 * Prerequisites:
 * - Twilio account with WhatsApp Sandbox or WhatsApp Business API enabled
 * - Pre-approved message template in Twilio (Content Template Builder) for proactive messages
 * - Env: WHATSAPP_ENABLED, TWILIO_ACCOUNT_SID, TWILIO_AUTH_TOKEN, TWILIO_WHATSAPP_FROM
 */

const logger = require('../utils/logger');

const DEFAULT_COUNTRY_CODE = process.env.WHATSAPP_DEFAULT_COUNTRY_CODE || '91';

/**
 * Normalize phone to E.164 for WhatsApp (e.g. 919876543210).
 * Strips spaces/dashes; adds country code if missing.
 * @param {string} phone - Raw phone (e.g. "9876543210", "+91 98765 43210")
 * @param {string} [countryCode] - Country code without + (e.g. "91")
 * @returns {string|null} E.164 digits only, or null if invalid
 */
function normalizePhoneToE164(phone, countryCode = DEFAULT_COUNTRY_CODE) {
    if (!phone || typeof phone !== 'string') return null;
    const digits = phone.replace(/\D/g, '');
    if (digits.length < 10) return null;
    let e164 = digits;
    const cc = (countryCode || '').replace(/\D/g, '');
    if (cc && !digits.startsWith(cc)) {
        e164 = cc + digits;
    }
    return e164 || null;
}

/**
 * @returns {boolean}
 */
function isEnabled() {
    const v = (process.env.WHATSAPP_ENABLED || '').toLowerCase();
    return v === 'true' || v === '1';
}

/**
 * Send WhatsApp message via Twilio (template or content template).
 * @param {object} options
 * @param {string} options.toE164 - Recipient E.164 number (e.g. "919876543210")
 * @param {string} [options.contentSid] - Twilio Content Template SID (preferred for templates)
 * @param {object} [options.contentVariables] - Map of template variable index to value, e.g. { "1": "Placed", "2": "ORD-123" }
 * @param {string} [options.body] - Plain body (only for within 24h window or template; avoid for proactive)
 * @returns {Promise<{ ok: boolean, messageId?: string, skipped?: boolean, reason?: string, error?: string }>}
 */
async function sendWhatsAppMessage({ toE164, contentSid, contentVariables, body }) {
    if (!isEnabled()) {
        return { ok: false, skipped: true, reason: 'whatsapp_disabled' };
    }
    if (!toE164) {
        return { ok: false, skipped: true, reason: 'missing_to_e164' };
    }

    let client;
    try {
        client = require('twilio')(
            process.env.TWILIO_ACCOUNT_SID,
            process.env.TWILIO_AUTH_TOKEN
        );
    } catch (e) {
        logger.warn('Twilio not available for WhatsApp', { component: 'whatsapp', error: e?.message });
        return { ok: false, skipped: true, reason: 'twilio_not_available' };
    }

    const from = process.env.TWILIO_WHATSAPP_FROM || ''; // e.g. "whatsapp:+14155238886"
    if (!from || !from.toLowerCase().startsWith('whatsapp:')) {
        logger.warn('TWILIO_WHATSAPP_FROM not set or invalid (must be whatsapp:+1234567890)', {
            component: 'whatsapp',
        });
        return { ok: false, skipped: true, reason: 'missing_whatsapp_from' };
    }

    const to = `whatsapp:${toE164}`;

    const payload = {
        from,
        to,
    };

    if (contentSid) {
        payload.contentSid = contentSid;
        if (contentVariables && typeof contentVariables === 'object') {
            payload.contentVariables = JSON.stringify(contentVariables);
        }
    } else if (body) {
        payload.body = String(body);
    } else {
        return { ok: false, skipped: true, reason: 'missing_content_sid_or_body' };
    }

    try {
        const message = await client.messages.create(payload);
        logger.info('WhatsApp message sent', {
            component: 'whatsapp',
            sid: message.sid,
            to: toE164,
            status: message.status,
        });
        return { ok: true, messageId: message.sid };
    } catch (e) {
        logger.error('WhatsApp send failed', {
            component: 'whatsapp',
            error: e?.message || String(e),
            to: toE164,
            code: e?.code,
        });
        return {
            ok: false,
            error: e?.message || String(e),
            code: e?.code,
        };
    }
}

/**
 * Human-readable order status for WhatsApp message body/template.
 */
function humanizeOrderStatus(status) {
    const s = String(status || '').toLowerCase().trim();
    const map = {
        placed: 'Placed',
        pickup_assigned: 'Pickup Assigned',
        picked_up: 'Picked Up',
        submitted_to_cm: 'Submitted to Collection',
        received_by_collection: 'Received by Collection',
        submitted_to_services: 'Submitted to Services',
        services_in_progress: 'Services In Progress',
        services_completed: 'Services Completed',
        dispatch_assigned: 'Dispatch Assigned',
        out_for_delivery: 'Out for Delivery',
        payment_pending: 'Payment Pending',
        delivered: 'Delivered',
        closed: 'Closed',
        cancelled: 'Cancelled',
        draft: 'Draft',
    };
    return map[s] || status;
}

/**
 * Send order status update to a customer's WhatsApp number.
 * Uses Content Template if WHATSAPP_ORDER_UPDATE_CONTENT_SID is set; otherwise sends a simple body
 * (only valid within 24h customer session; for proactive use, set up a template and content SID).
 *
 * @param {object} options
 * @param {string} options.phone - Customer phone (any format; will be normalized to E.164)
 * @param {string} options.orderId - Order ID for the message
 * @param {string} options.status - Order status (e.g. "out_for_delivery")
 * @param {string} [options.countryCode] - Country code for E.164 (default from env)
 * @returns {Promise<{ ok: boolean, messageId?: string, skipped?: boolean, reason?: string }>}
 */
async function sendOrderStatusUpdate({ phone, orderId, status, countryCode }) {
    const e164 = normalizePhoneToE164(phone, countryCode);
    if (!e164) {
        return { ok: false, skipped: true, reason: 'invalid_or_missing_phone' };
    }

    const prettyStatus = humanizeOrderStatus(status);
    const contentSid = process.env.WHATSAPP_ORDER_UPDATE_CONTENT_SID;

    if (contentSid) {
        // Content Template Builder template: variable indices depend on your template.
        // Example template: "Your order {{1}} is now: {{2}}"
        return sendWhatsAppMessage({
            toE164: e164,
            contentSid,
            contentVariables: {
                '1': String(orderId || ''),
                '2': prettyStatus,
            },
        });
    }

    // Fallback: plain body (works in sandbox / within 24h window; for production use a template)
    const body = `Order update: Your order ${orderId || 'N/A'} status is now: ${prettyStatus}.`;
    return sendWhatsAppMessage({
        toE164: e164,
        body,
    });
}

module.exports = {
    isEnabled,
    normalizePhoneToE164,
    sendWhatsAppMessage,
    sendOrderStatusUpdate,
    humanizeOrderStatus,
};
