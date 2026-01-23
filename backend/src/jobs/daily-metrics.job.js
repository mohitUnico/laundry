const logger = require('../utils/logger');
const dailyMetricsService = require('../services/daily-metrics.service');

let jobTimeoutHandle = null;
let jobIntervalHandle = null;

const BACKFILL_DAYS_DEFAULT = 45;

const isJobEnabled = () => {
    if (process.env.NODE_ENV === 'test') return false;
    if (process.env.DAILY_METRICS_JOB_ENABLED === 'false') return false;
    return true;
};

const addUtcDays = (date, days) => {
    const d = new Date(date);
    d.setUTCDate(d.getUTCDate() + days);
    return d;
};

const msUntilNextUtcTime = ({ hour, minute }) => {
    const now = new Date();
    const next = new Date(Date.UTC(now.getUTCFullYear(), now.getUTCMonth(), now.getUTCDate(), hour, minute, 0));
    if (next <= now) {
        next.setUTCDate(next.getUTCDate() + 1);
    }
    return next.getTime() - now.getTime();
};

const runDailyRollup = async () => {
    // At the start of the day (UTC), finalize yesterday and also refresh today.
    const today = new Date();
    const yesterday = addUtcDays(today, -1);

    await dailyMetricsService.recalculateForUtcDate(yesterday);
    await dailyMetricsService.recalculateForUtcDate(today);
};

const backfillRecentDays = async () => {
    const raw = process.env.DAILY_METRICS_BACKFILL_DAYS;
    const days = Number.isFinite(Number(raw)) ? parseInt(raw, 10) : BACKFILL_DAYS_DEFAULT;
    const safeDays = Number.isFinite(days) && days > 0 ? Math.min(days, 365) : BACKFILL_DAYS_DEFAULT;

    const today = new Date();
    const start = addUtcDays(today, -safeDays + 1);

    logger.info('Daily metrics backfill started', { days: safeDays, fromUtc: start.toISOString(), toUtc: today.toISOString() });

    // Sequential (avoid hammering DB)
    for (let i = 0; i < safeDays; i += 1) {
        // eslint-disable-next-line no-await-in-loop
        await dailyMetricsService.recalculateForUtcDate(addUtcDays(start, i));
    }

    logger.info('Daily metrics backfill completed', { days: safeDays });
};

const schedule = () => {
    if (jobTimeoutHandle) clearTimeout(jobTimeoutHandle);
    if (jobIntervalHandle) clearInterval(jobIntervalHandle);

    // Run every day at 00:05 UTC to avoid boundary race conditions.
    const delayMs = msUntilNextUtcTime({ hour: 0, minute: 5 });

    jobTimeoutHandle = setTimeout(() => {
        runDailyRollup().catch((error) => {
            logger.error('Daily metrics rollup failed', { error: error?.message || String(error) });
        });

        jobIntervalHandle = setInterval(() => {
            runDailyRollup().catch((error) => {
                logger.error('Daily metrics rollup failed', { error: error?.message || String(error) });
            });
        }, 24 * 60 * 60 * 1000);
    }, delayMs);

    logger.info('Daily metrics job scheduled', {
        nextRunInMs: delayMs,
        nextRunAtUtc: new Date(Date.now() + delayMs).toISOString(),
    });
};

exports.startDailyMetricsJob = () => {
    if (!isJobEnabled()) {
        logger.info('Daily metrics job disabled');
        return;
    }

    // Startup backfill (configurable): default last 45 days, includes today.
    backfillRecentDays().catch((error) => {
        logger.error('Daily metrics backfill failed', { error: error?.message || String(error) });
    });

    schedule();
};

