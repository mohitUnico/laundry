import { useCallback, useEffect, useMemo, useRef, useState } from 'react';
import {
  dashboardApi,
  MartDashboardCustomerSatisfaction,
  MartDashboardDayOverview,
  MartDashboardMonthlyOverview,
  MartDashboardRecentOrders,
  MartDashboardRevenueTrend,
  MartDashboardTopPerformers,
} from '@/services';

type DashboardRange = '7d' | '30d';

export type DashboardState = {
  monthlyOverview: MartDashboardMonthlyOverview | null;
  dayOverview: MartDashboardDayOverview | null;
  revenueTrend: MartDashboardRevenueTrend | null;
  recentOrders: MartDashboardRecentOrders | null;
  topPerformers: MartDashboardTopPerformers | null;
  customerSatisfaction: MartDashboardCustomerSatisfaction | null;
};

const EMPTY_STATE: DashboardState = {
  monthlyOverview: null,
  dayOverview: null,
  revenueTrend: null,
  recentOrders: null,
  topPerformers: null,
  customerSatisfaction: null,
};

// -----------------------------------------------------------------------------
// Dev-friendly request de-dupe / caching
// React 18 StrictMode mounts components twice in development, which can
// double-trigger dashboard effects and cause 429 rate limiting.
// We keep a small module-level in-flight promise + cache so a second mount
// reuses the same request/results instead of firing again.
// -----------------------------------------------------------------------------
let inFlight: Promise<DashboardState> | null = null;
let cache: { range: DashboardRange; at: number; data: DashboardState } | null = null;
const CACHE_TTL_MS = 10_000;
const MONTHLY_POLL_MS = 30_000;

const fetchDashboard = async (range: DashboardRange): Promise<DashboardState> => {
  const [
    monthlyOverviewRes,
    revenueTrendRes,
    recentOrdersRes,
    topPerformersRes,
    dayOverviewRes,
    satisfactionRes,
  ] = await Promise.all([
    dashboardApi.getMonthlyOverview(),
    dashboardApi.getRevenueTrend({ range: range === '30d' ? '7weeks' : '7days' }),
    dashboardApi.getRecentOrders({ limit: 10 }),
    dashboardApi.getTopPerformers({ limit: 5 }),
    dashboardApi.getDayOverview(),
    dashboardApi.getCustomerSatisfaction(),
  ]);

  return {
    monthlyOverview: monthlyOverviewRes.data,
    revenueTrend: revenueTrendRes.data,
    recentOrders: recentOrdersRes.data,
    topPerformers: topPerformersRes.data,
    dayOverview: dayOverviewRes.data,
    customerSatisfaction: satisfactionRes.data,
  };
};

export const useDashboard = () => {
  const [range, setRange] = useState<DashboardRange>('7d');
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [data, setData] = useState<DashboardState>(EMPTY_STATE);

  const monthlyPollInFlightRef = useRef<Promise<void> | null>(null);

  const refresh = useCallback(async (opts?: { force?: boolean }) => {
    setLoading(true);
    setError(null);

    try {
      const now = Date.now();
      const canUseCache =
        !opts?.force && !!cache && cache.range === range && now - cache.at < CACHE_TTL_MS;
      if (canUseCache) {
        setData(cache!.data);
        return;
      }

      if (!inFlight) {
        inFlight = fetchDashboard(range)
          .then((next) => {
            cache = { range, at: Date.now(), data: next };
            return next;
          })
          .finally(() => {
            inFlight = null;
          });
      }

      const next = await inFlight;
      setData(next);
    } catch (e: any) {
      const status = e?.response?.status;
      const retryAfter = e?.response?.headers?.['retry-after'];
      if (status === 429) {
        const hint = retryAfter ? ` Please retry after ${retryAfter}s.` : '';
        setError(`Too many requests (429).${hint}`);
      } else {
      const message =
        e?.response?.data?.message ||
        e?.message ||
        'Failed to load dashboard. Please try again.';
      setError(message);
      }
    } finally {
      setLoading(false);
    }
  }, [range]);

  useEffect(() => {
    void refresh();
  }, [refresh]);

  // Poll only the monthly overview every 30 seconds (no backend changes required).
  // We keep this "silent" (no loading spinner) and de-dupe overlapping polls.
  useEffect(() => {
    let cancelled = false;

    const tick = async () => {
      if (monthlyPollInFlightRef.current) return;

      monthlyPollInFlightRef.current = dashboardApi
        .getMonthlyOverview()
        .then((res) => {
          if (cancelled) return;
          setData((prev) => ({
            ...prev,
            monthlyOverview: res.data,
          }));
        })
        .catch(() => {
          // Intentionally silent: keep last value, avoid UI flicker.
        })
        .finally(() => {
          monthlyPollInFlightRef.current = null;
        });

      await monthlyPollInFlightRef.current;
    };

    // Run immediately and then every 30 seconds.
    void tick();
    const id = window.setInterval(() => {
      void tick();
    }, MONTHLY_POLL_MS);

    return () => {
      cancelled = true;
      window.clearInterval(id);
    };
  }, []);

  const api = useMemo(
    () => ({
      range,
      setRange,
      loading,
      error,
      data,
      refresh,
    }),
    [range, loading, error, data, refresh]
  );

  return api;
};


