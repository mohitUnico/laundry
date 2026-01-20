import { useCallback, useEffect, useMemo, useState } from 'react';
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

export const useDashboard = () => {
  const [range, setRange] = useState<DashboardRange>('7d');
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [data, setData] = useState<DashboardState>(EMPTY_STATE);

  const refresh = useCallback(async () => {
    setLoading(true);
    setError(null);

    try {
      const [
        monthlyOverviewRes,
        revenueTrendRes,
        recentOrdersRes,
        topPerformersRes,
        dayOverviewRes,
        satisfactionRes,
      ] =
        await Promise.all([
          dashboardApi.getMonthlyOverview(),
          dashboardApi.getRevenueTrend({ range: range === '30d' ? '7weeks' : '7days' }),
          dashboardApi.getRecentOrders({ limit: 10 }),
          dashboardApi.getTopPerformers({ limit: 5 }),
          dashboardApi.getDayOverview(),
          dashboardApi.getCustomerSatisfaction(),
        ]);

      setData({
        monthlyOverview: monthlyOverviewRes.data,
        revenueTrend: revenueTrendRes.data,
        recentOrders: recentOrdersRes.data,
        topPerformers: topPerformersRes.data,
        dayOverview: dayOverviewRes.data,
        customerSatisfaction: satisfactionRes.data,
      });
    } catch (e: any) {
      const message =
        e?.response?.data?.message ||
        e?.message ||
        'Failed to load dashboard. Please try again.';
      setError(message);
    } finally {
      setLoading(false);
    }
  }, [range]);

  useEffect(() => {
    void refresh();
  }, [refresh]);

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


