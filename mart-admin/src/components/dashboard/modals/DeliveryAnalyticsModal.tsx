import React, { useState, useEffect, useCallback } from 'react';
import { Modal } from '@/components/common';
import { TrendingUp, TrendingDown, Clock, Target, Loader2 } from 'lucide-react';
import { dashboardApi, AdminDashboardDeliveryAnalytics } from '@/services/api/modules/dashboardApi';

interface DeliveryAnalyticsModalProps {
  isOpen: boolean;
  onClose: () => void;
}

export const DeliveryAnalyticsModal: React.FC<DeliveryAnalyticsModalProps> = ({ isOpen, onClose }) => {
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [analytics, setAnalytics] = useState<AdminDashboardDeliveryAnalytics | null>(null);

  // Fetch delivery analytics
  const fetchAnalytics = useCallback(async () => {
    if (!isOpen) return;
    
    setLoading(true);
    setError(null);

    try {
      const response = await dashboardApi.getAdminDeliveryAnalytics({ limit: 10 });

      if (response.success && response.data) {
        setAnalytics(response.data);
      } else {
        setError('Failed to fetch delivery analytics');
      }
    } catch (err: any) {
      console.error('Failed to fetch delivery analytics:', err);
      const errorMessage = err?.response?.data?.message || 'Failed to load delivery analytics. Please try again.';
      setError(errorMessage);
      setAnalytics(null);
    } finally {
      setLoading(false);
    }
  }, [isOpen]);

  useEffect(() => {
    fetchAnalytics();
  }, [fetchAnalytics]);

  const formatMinutes = (minutes: number | null | undefined): string => {
    if (minutes === null || minutes === undefined) return 'N/A';
    return `${minutes} min`;
  };

  const formatDelta = (delta: number | null | undefined): { text: string; trend: 'up' | 'down' } => {
    if (delta === null || delta === undefined) return { text: '—', trend: 'up' };
    const sign = delta >= 0 ? '+' : '';
    return {
      text: `${sign}${delta} min`,
      trend: delta < 0 ? 'up' : 'down',
    };
  };

  const metrics = analytics ? [
    {
      label: 'Today Avg',
      value: formatMinutes(analytics.metrics.todayAvgMinutes),
      change: formatDelta(analytics.metrics.todayDeltaMinutes),
    },
    {
      label: 'Week Avg',
      value: formatMinutes(analytics.metrics.weekAvgMinutes),
      change: formatDelta(analytics.metrics.weekDeltaMinutes),
    },
    {
      label: 'Month Avg',
      value: formatMinutes(analytics.metrics.monthAvgMinutes),
      change: formatDelta(analytics.metrics.monthDeltaMinutes),
    },
  ] : [];

  const statusColors: { [key: string]: string } = {
    'On Time': 'bg-emerald-50 text-emerald-700 border-emerald-200',
    'Delayed': 'bg-red-50 text-red-700 border-red-200',
    'Early': 'bg-blue-50 text-blue-700 border-blue-200',
  };

  return (
    <Modal isOpen={isOpen} onClose={onClose} title="Delivery Analytics" size="xl">
      <div className="space-y-6">
        {/* Error Message */}
        {error && (
          <div className="rounded-xl border border-red-200 bg-red-50 p-4 text-center">
            <div className="text-red-600 text-sm font-medium">{error}</div>
            <button
              onClick={() => fetchAnalytics()}
              className="mt-2 text-xs text-red-600 underline hover:text-red-700"
            >
              Try again
            </button>
          </div>
        )}

        {/* Loading State */}
        {loading && !analytics && (
          <div className="flex items-center justify-center py-12">
            <Loader2 className="animate-spin h-8 w-8 text-blue-600" />
          </div>
        )}

        {!loading && analytics && (
          <>
            {/* Overview Cards */}
            <div className="grid grid-cols-3 gap-4">
              {metrics.map((metric) => (
                <div key={metric.label} className="bg-gradient-to-br from-blue-50 to-blue-100 rounded-xl p-4">
                  <div className="flex items-center justify-between mb-2">
                    <p className="text-sm font-medium text-slate-700">{metric.label}</p>
                    <Clock size={18} className="text-blue-600" />
                  </div>
                  <p className="text-2xl font-bold text-slate-900 mb-1">{metric.value}</p>
                  <div className="flex items-center gap-1">
                    {metric.change.trend === 'up' ? (
                      <TrendingUp size={16} className="text-emerald-600" />
                    ) : (
                      <TrendingDown size={16} className="text-red-600" />
                    )}
                    <span className={`text-sm font-medium ${metric.change.trend === 'up' ? 'text-emerald-600' : 'text-red-600'}`}>
                      {metric.change.text}
                    </span>
                  </div>
                </div>
              ))}
            </div>

            {/* Performance Chart */}
            <div className="bg-gradient-to-br from-purple-50 to-blue-50 rounded-xl p-6">
              <div className="flex items-center justify-between mb-4">
                <h4 className="text-lg font-semibold text-slate-900">Performance Trend</h4>
                <Target size={20} className="text-purple-600" />
              </div>
              <div className="h-48 bg-white/70 rounded-xl flex items-center justify-center border-2 border-dashed border-purple-200">
                <p className="text-slate-500 text-sm">Delivery Time Trend Chart</p>
              </div>
            </div>

            {/* Recent Deliveries */}
            <div>
              <h4 className="text-lg font-semibold text-slate-900 mb-4">Recent Deliveries</h4>
              <div className="overflow-x-auto">
                <table className="w-full">
                  <thead className="bg-slate-50 border-b border-slate-200">
                    <tr>
                      <th className="px-4 py-3 text-left text-sm font-semibold text-slate-700">Order ID</th>
                      <th className="px-4 py-3 text-left text-sm font-semibold text-slate-700">Customer</th>
                      <th className="px-4 py-3 text-left text-sm font-semibold text-slate-700">Time</th>
                      <th className="px-4 py-3 text-left text-sm font-semibold text-slate-700">Status</th>
                    </tr>
                  </thead>
                  <tbody className="divide-y divide-slate-100">
                    {analytics.recentDeliveries.length === 0 ? (
                      <tr>
                        <td colSpan={4} className="px-6 py-12 text-center">
                          <p className="text-slate-500 text-sm">No recent deliveries found</p>
                        </td>
                      </tr>
                    ) : (
                      analytics.recentDeliveries.map((delivery) => (
                        <tr key={delivery.orderId} className="hover:bg-slate-50 transition-colors">
                          <td className="px-4 py-3">
                            <span className="text-sm font-medium text-slate-900">{delivery.orderId}</span>
                          </td>
                          <td className="px-4 py-3">
                            <span className="text-sm text-slate-700">{delivery.customerName || 'Unknown Customer'}</span>
                          </td>
                          <td className="px-4 py-3">
                            <span className="text-sm font-semibold text-slate-900">
                              {formatMinutes(delivery.durationMinutes)}
                            </span>
                          </td>
                          <td className="px-4 py-3">
                            <span className={`inline-flex items-center px-2.5 py-1 rounded-full text-xs font-medium border ${statusColors[delivery.status] || 'bg-gray-50 text-gray-700 border-gray-200'}`}>
                              {delivery.status}
                            </span>
                          </td>
                        </tr>
                      ))
                    )}
                  </tbody>
                </table>
              </div>
            </div>

            {/* Key Insights */}
            <div className="bg-gradient-to-r from-emerald-50 to-blue-50 rounded-xl p-4 border border-emerald-200">
              <div className="flex items-start gap-3">
                <TrendingUp size={20} className="text-emerald-600 flex-shrink-0 mt-0.5" />
                <div>
                  <h5 className="font-semibold text-slate-900 mb-1">Performance Insight</h5>
                  <p className="text-sm text-slate-700">
                    {analytics.metrics.monthDeltaMinutes < 0
                      ? `Average delivery time improved by ${Math.abs(analytics.metrics.monthDeltaMinutes)} minutes this month.`
                      : `Average delivery time increased by ${analytics.metrics.monthDeltaMinutes} minutes this month.`}
                    {' '}Most deliveries are on-time, showing good operational efficiency.
                  </p>
                </div>
              </div>
            </div>
          </>
        )}
      </div>
    </Modal>
  );
};

