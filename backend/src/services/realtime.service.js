const logger = require('../utils/logger');

/**
 * Very small in-memory SSE hub.
 * - Works without extra dependencies.
 * - In multi-instance deployments, replace with Redis/pubsub or Supabase Realtime.
 */
class RealtimeService {
    constructor() {
        /** @type {Map<string, Set<import('express').Response>>} */
        this.staffStreams = new Map();
        this._keepAliveInterval = setInterval(() => this._keepAlive(), 25000);
        this._keepAliveInterval.unref?.();
    }

    _getOrCreateSet(staffId) {
        const key = String(staffId);
        if (!this.staffStreams.has(key)) {
            this.staffStreams.set(key, new Set());
        }
        return this.staffStreams.get(key);
    }

    subscribeDeliveryStaff({ staffId, res }) {
        const set = this._getOrCreateSet(staffId);
        set.add(res);

        res.writeHead(200, {
            'Content-Type': 'text/event-stream',
            'Cache-Control': 'no-cache, no-transform',
            Connection: 'keep-alive',
            'X-Accel-Buffering': 'no',
        });

        // initial event
        this._write(res, 'connected', { staffId: String(staffId) });

        res.on('close', () => {
            set.delete(res);
            if (set.size === 0) {
                this.staffStreams.delete(String(staffId));
            }
        });

        logger.info('SSE subscribed for delivery staff', { staffId: String(staffId), active: set.size });
    }

    emitToDeliveryStaff(staffId, event, payload) {
        const set = this.staffStreams.get(String(staffId));
        if (!set || set.size === 0) return;

        for (const res of set) {
            this._write(res, event, payload);
        }
    }

    _write(res, event, payload) {
        try {
            res.write(`event: ${event}\n`);
            res.write(`data: ${JSON.stringify(payload ?? {})}\n\n`);
        } catch (error) {
            // ignore individual stream failures
        }
    }

    _keepAlive() {
        for (const set of this.staffStreams.values()) {
            for (const res of set) {
                try {
                    res.write(`: ping\n\n`);
                } catch (error) {
                    // ignore
                }
            }
        }
    }
}

module.exports = new RealtimeService();

