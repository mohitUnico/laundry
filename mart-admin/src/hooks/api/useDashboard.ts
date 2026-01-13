import { useCallback, useEffect, useMemo, useState } from 'react';
import {
  dashboardApi,
  AdminDashboardCustomerSatisfaction,
  AdminDashboardOrderStatus,
  AdminDashboardRecentOrder,
  AdminDashboardRevenueTrendPoint,
  AdminDashboardSummary,
  AdminDashboardTopPerformer,
} from '@/services';

type DashboardRange = '7d' | '30d';

export type DashboardState = {
  summary: AdminDashboardSummary | null;
  orderStatus: AdminDashboardOrderStatus | null;
  revenueTrend: AdminDashboardRevenueTrendPoint[] | null;
  recentOrders: AdminDashboardRecentOrder[] | null;
  topPerformers: AdminDashboardTopPerformer[] | null;
  customerSatisfaction: AdminDashboardCustomerSatisfaction | null;
};

const EMPTY_STATE: DashboardState = {
  summary: null,
  orderStatus: null,
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
      const [summaryRes, orderStatusRes, revenueTrendRes, recentOrdersRes, topPerformersRes, satisfactionRes] =
        await Promise.all([
          dashboardApi.getAdminSummary(),
          dashboardApi.getAdminOrderStatus(),
          dashboardApi.getAdminRevenueTrend({ range }),
          dashboardApi.getAdminRecentOrders({ limit: 10 }),
          dashboardApi.getAdminTopPerformers({ limit: 5 }),
          dashboardApi.getAdminCustomerSatisfaction(),
        ]);

      setData({
        summary: summaryRes.data,
        orderStatus: orderStatusRes.data,
        revenueTrend: revenueTrendRes.data,
        recentOrders: recentOrdersRes.data,
        topPerformers: topPerformersRes.data,
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


