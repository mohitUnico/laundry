const fs = require('fs');
const path = require('path');

const prisma = require('../config/database');
const logger = require('../utils/logger');

let _initialized = false;
let admin = null; // Lazy-loaded when FIREBASE_ENABLED=true to avoid requiring firebase-admin at startup

function _safeString(v) {
    if (v == null) return '';
    return String(v);
}

function _getAdmin() {
    if (admin) return admin;
    try {
        admin = require('firebase-admin');
        return admin;
    } catch (e) {
        logger.warn('firebase-admin not installed; FCM disabled. Install with: npm install firebase-admin');
        return null;
    }
}

function initFirebaseAdmin() {
    if (_initialized) return true;

    const enabled = _safeString(process.env.FIREBASE_ENABLED || 'false').toLowerCase() === 'true';
    if (!enabled) {
        logger.info('Firebase Admin disabled (FIREBASE_ENABLED != true)');
        return false;
    }

    const adm = _getAdmin();
    if (!adm) return false;

    try {
        const configuredPath = process.env.FIREBASE_SERVICE_ACCOUNT_PATH;
        const serviceAccountPath = configuredPath
            ? path.resolve(process.cwd(), configuredPath)
            : path.resolve(__dirname, '../config/firebase-service-account.json');

        if (!fs.existsSync(serviceAccountPath)) {
            logger.warn('Firebase service account JSON not found', { serviceAccountPath });
            return false;
        }

        const serviceAccount = JSON.parse(fs.readFileSync(serviceAccountPath, 'utf8'));

        // Avoid double init (tests / nodemon reloads)
        if (adm.apps && adm.apps.length > 0) {
            _initialized = true;
            return true;
        }

        adm.initializeApp({
            credential: adm.credential.cert(serviceAccount),
        });

        _initialized = true;
        logger.info('Firebase Admin initialized', {
            projectId: serviceAccount.project_id,
        });
        return true;
    } catch (e) {
        logger.error('Firebase Admin initialization failed', { error: e?.message || String(e) });
        return false;
    }
}

async function sendToToken({ token, title, body, data = {} }) {
    if (!_initialized) {
        const ok = initFirebaseAdmin();
        if (!ok) return { ok: false, skipped: true, reason: 'firebase_not_initialized' };
    }

    if (!token) return { ok: false, skipped: true, reason: 'missing_token' };

    // FCM requires all data values to be strings
    const stringData = {};
    for (const [k, v] of Object.entries(data || {})) {
        stringData[k] = _safeString(v);
    }

    try {
        const message = {
            token,
            notification: {
                title: _safeString(title) || 'Laundry Update',
                body: _safeString(body) || '',
            },
            data: stringData,
            android: { priority: 'high' },
            apns: { headers: { 'apns-priority': '10' } },
        };

        const adm = _getAdmin();
        if (!adm) return { ok: false, skipped: true, reason: 'firebase_admin_not_available' };
        const messageId = await adm.messaging().send(message);
        return { ok: true, messageId };
    } catch (e) {
        logger.error('FCM send failed', { error: e?.message || String(e) });
        return { ok: false, error: e?.message || String(e) };
    }
}

function _humanizeOrderStatus(status) {
    const s = _safeString(status).toLowerCase().trim();
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
        delivered: 'Delivered',
        closed: 'Closed',
        cancelled: 'Cancelled',
        draft: 'Draft',
    };
    return map[s] || status;
}

async function notifyOrderStatusChange({ orderId, status }) {
    if (!orderId || !status) return { ok: false, skipped: true, reason: 'missing_order_or_status' };

    const order = await prisma.order.findUnique({
        where: { order_id: orderId },
        select: {
            order_id: true,
            order_status: true,
            customer: { select: { customer_id: true, fcm_token: true } },
        },
    });

    if (!order || !order.customer) return { ok: false, skipped: true, reason: 'order_or_customer_not_found' };
    const token = order.customer.fcm_token;
    if (!token) return { ok: false, skipped: true, reason: 'customer_missing_fcm_token' };

    const pretty = _humanizeOrderStatus(status);
    return sendToToken({
        token,
        title: 'Order Update',
        body: `Your order status is now: ${pretty}`,
        data: {
            order_id: order.order_id,
            status,
        },
    });
}

module.exports = {
    initFirebaseAdmin,
    sendToToken,
    notifyOrderStatusChange,
};


