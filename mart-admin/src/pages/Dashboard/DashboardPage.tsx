import React, { useState } from 'react';
import {
  SummaryCard,
  OrderStatusWidget,
  AlertCard,
  RevenueChart,
  RecentOrders,
  TopPerformers,
  CustomerSatisfaction,
  QuickActions,
  FloatingActionButton,
} from '@/components/dashboard';
import {
  ReportModal,
  CreateOrderModal,
  AddCustomerModal,
  AddStaffModal,
  SendNotificationModal,
  ActiveOrdersModal,
  NewCustomersModal,
  DeliveryAnalyticsModal,
  LateDeliveryModal,
  FilteredOrdersModal,
  AllRecentOrdersModal,
} from '@/components/dashboard/modals';
import { Toast, Modal } from '@/components/common';
import { useToast } from '@/hooks/common';
import { useDashboard } from '@/hooks/api';
import { formatCompactCurrency } from '@/utils/formatters';
import { dashboardApi, type AdminRevenueBreakdown } from '@/services/api/modules/dashboardApi';
import { useEffect, useCallback } from 'react';
import { Download, Loader2, Plus } from 'lucide-react';
import { useNavigate } from 'react-router-dom';
import { ROUTES } from '@/routes';
import { ExportDropdown } from '@/components/layout/Header/ExportDropdown';
import {
  ResponsiveContainer,
  ComposedChart,
  Bar,
  Line,
  XAxis,
  YAxis,
  CartesianGrid,
  Tooltip,
} from 'recharts';

export const DashboardPage: React.FC = () => {
  const navigate = useNavigate();
  const { toast, showToast, hideToast } = useToast();
  const [showReportModal, setShowReportModal] = useState(false);
  const [showCreateOrderModal, setShowCreateOrderModal] = useState(false);
  const [showAddCustomerModal, setShowAddCustomerModal] = useState(false);
  const [showAddStaffModal, setShowAddStaffModal] = useState(false);
  const [showNotificationModal, setShowNotificationModal] = useState(false);
  const [showRevenueModal, setShowRevenueModal] = useState(false);
  const [showActiveOrdersModal, setShowActiveOrdersModal] = useState(false);
  const [showNewCustomersModal, setShowNewCustomersModal] = useState(false);
  const [showDeliveryAnalyticsModal, setShowDeliveryAnalyticsModal] = useState(false);
  const [showLateDeliveryModal, setShowLateDeliveryModal] = useState(false);
  const [showFilteredOrdersModal, setShowFilteredOrdersModal] = useState(false);
  const [showAllRecentOrdersModal, setShowAllRecentOrdersModal] = useState(false);
  const [selectedStatus, setSelectedStatus] = useState<string>('');
  const [exportOpen, setExportOpen] = useState(false);
  const [revenueLoading, setRevenueLoading] = useState(false);
  const [revenueError, setRevenueError] = useState<string | null>(null);
  const [revenueBreakdown, setRevenueBreakdown] = useState<AdminRevenueBreakdown | null>(null);
  const [selectedRevenuePeriod, setSelectedRevenuePeriod] = useState<'daily' | 'weekly' | 'monthly'>('weekly');

  const { data, error, loading, range, setRange, refresh } = useDashboard();

  const fetchRevenueBreakdown = useCallback(async () => {
    if (!showRevenueModal) return;

    setRevenueLoading(true);
    setRevenueError(null);

    try {
      const res = await dashboardApi.getAdminRevenueBreakdown();
      if (!res.success) throw new Error(res.message || 'Failed to fetch revenue data');
      setRevenueBreakdown(res.data);
    } catch (err: any) {
      console.error('Failed to fetch revenue data:', err);
      const errorMessage = err?.response?.data?.message || 'Failed to load revenue data. Please try again.';
      setRevenueError(errorMessage);
      setRevenueBreakdown(null);
    } finally {
      setRevenueLoading(false);
    }
  }, [showRevenueModal]);

  useEffect(() => {
    fetchRevenueBreakdown();
  }, [fetchRevenueBreakdown]);

  const handleReportSuccess = () => {
    showToast('Report generated successfully!', 'success');
  };

  const handleCreateOrderSuccess = () => {
    showToast('Order created successfully!', 'success');
  };

  const handleAddCustomerSuccess = () => {
    showToast('Customer added successfully!', 'success');
  };

  const handleAddStaffSuccess = () => {
    showToast('Staff member added successfully!', 'success');
  };

  const handleNotificationSuccess = () => {
    showToast('Notification sent successfully!', 'success');
  };

  const handleStatusClick = (status: string) => {
    setSelectedStatus(status);
    setShowFilteredOrdersModal(true);
  };

  const monthlyOverview = data.monthlyOverview;
  const dayOverview = data.dayOverview;
  const trend = data.revenueTrend;
  const satisfaction = data.customerSatisfaction;

  const formatSignedPercent = (value?: number | null) => {
    const n = typeof value === 'number' && Number.isFinite(value) ? value : 0;
    const sign = n > 0 ? '+' : '';
    return `${sign}${n}%`;
  };

  const isoFromDurationAgo = (durationAgo?: string | null) => {
    if (!durationAgo) return new Date().toISOString();
    const match = durationAgo
      .toLowerCase()
      .match(/(\d+)\s*(sec|secs|second|seconds|min|mins|minute|minutes|hr|hrs|hour|hours|day|days)\s*ago/);
    if (!match) return new Date().toISOString();

    const value = Number.parseInt(match[1] || '0', 10);
    const unit = match[2] || '';

    const ms =
      unit.startsWith('sec')
        ? value * 1000
        : unit.startsWith('min')
          ? value * 60 * 1000
          : unit.startsWith('hr') || unit.startsWith('hour')
            ? value * 60 * 60 * 1000
            : value * 24 * 60 * 60 * 1000;

    return new Date(Date.now() - ms).toISOString();
  };

  // Monthly overview (mart scoped)
  const summaryTotalRevenue = monthlyOverview
    ? formatCompactCurrency(Number.parseFloat(monthlyOverview.total_revenue) || 0)
    : '—';
  const summaryTotalOrders = monthlyOverview ? monthlyOverview.total_orders : null;
  const summaryNewCustomers = monthlyOverview ? monthlyOverview.new_customers : null;
  const summaryAvgDelivery = monthlyOverview ? `${monthlyOverview.avg_delivery_time} min` : '—';

  // Growth deltas (vs last month), from monthly-overview API
  const summaryRevenueGrowth = formatSignedPercent(monthlyOverview?.percentage_increase_total_revenue);
  const summaryOrdersGrowth = `${formatSignedPercent(
    monthlyOverview?.percentage_increase_total_orders
  )} from last month`;
  const summaryCustomersGrowth = `${formatSignedPercent(
    monthlyOverview?.percentage_increase_new_customers
  )} from last month`;
  const summaryDeliveryGrowth = `${formatSignedPercent(
    monthlyOverview?.percentage_increase_avg_delivery_time
  )} from last month`;

  const statusItems = dayOverview
    ? [
        { label: 'Pending', count: dayOverview.pending_orders, color: '#facc15' },
        { label: 'In progress', count: dayOverview.in_progress, color: '#60a5fa' },
        { label: 'Out for delivery', count: dayOverview.out_for_delivery, color: '#22d3ee' },
        { label: 'Completed today', count: dayOverview.completed_today, color: '#34d399' },
      ]
    : undefined;

  const recentOrdersItems =
    (data.recentOrders?.data || []).map((o) => ({
      id: o.order_id,
      customer: o.customer_name || 'Unknown Customer',
      amount: Number(o.order_price) || 0,
      status: o.status || 'unknown',
      timeIso: isoFromDurationAgo(o.duration_ago),
    })) || [];

  const topPerformersItems =
    (data.topPerformers?.top_performers || []).map((p) => ({
      name: p.delivery_staff_name,
      deliveries: p.total_deliveries,
      rating: p.overall_rating,
      avatarUrl: null,
    })) || [];

  const chartPoints = (trend?.data || []).map((p) => ({
    label: p.label,
    totalRevenue: p.total_revenue,
    totalOrders: p.total_orders,
  }));

  const trendTotals = {
    totalRevenue: trend?.total_revenue || 0,
    totalOrders: trend?.total_orders || 0,
  };

  const handleRangeChange = (nextRange: '7d' | '30d') => {
    setRange(nextRange);
  };

  const handleRetry = async () => {
    await refresh();
  };

  const handleExportSelect = (fmt: 'PDF' | 'Excel' | 'CSV') => {
    setExportOpen(false);
    showToast(`Dashboard exported as ${fmt}!`, 'success');
  };

  return (
    <div className="w-full">
      <div className="mx-auto w-full max-w-[1240px] rounded-2xl border border-slate-100 bg-white p-4 shadow-soft sm:p-6 md:p-7 lg:p-8">
        <div className="space-y-4 sm:space-y-5 md:space-y-6 lg:space-y-7">
          <div className="flex flex-col gap-3 sm:flex-row sm:items-start sm:justify-between">
            <div>
              <h1 className="text-2xl sm:text-3xl font-semibold text-[#0F172A]">Dashboard</h1>
              <p className="mt-1 text-sm text-[#64748B]">Welcome back! Here’s your business overview.</p>
            </div>
            <div className="flex items-center gap-3">
              <button
                onClick={() => setShowReportModal(true)}
                className="inline-flex items-center gap-2 rounded-full bg-[#2F47FF] px-4 py-2 text-sm font-medium text-white hover:bg-[#263BE6] transition-colors"
              >
                <Plus size={16} />
                Add Report
              </button>
              <div className="relative">
                <button
                  onClick={() => setExportOpen((v) => !v)}
                  className="inline-flex items-center gap-2 rounded-full border border-[#2F47FF] px-4 py-2 text-sm font-medium text-[#2F47FF] hover:bg-[#EEF2FF] transition-colors"
                >
                  <Download size={16} />
                  Export Report
                </button>
                <ExportDropdown open={exportOpen} onClose={() => setExportOpen(false)} onSelect={handleExportSelect} />
              </div>
            </div>
          </div>

          {error && (
            <div className="bg-red-50 border border-red-200 text-red-800 rounded-xl p-3 sm:p-4 flex items-center justify-between gap-3">
              <div className="text-sm">
                <span className="font-semibold">Dashboard error:</span> {error}
              </div>
              <button
                onClick={handleRetry}
                className="px-3 py-1.5 rounded-lg bg-red-600 text-white text-sm font-medium hover:bg-red-700"
              >
                Retry
              </button>
            </div>
          )}

          {/* Summary Cards */}
          <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-2 xl:grid-cols-4 gap-3 sm:gap-4 md:gap-5 lg:gap-6">
            <div
              onClick={() => setShowRevenueModal(true)}
              className="cursor-pointer transform transition-all hover:scale-[1.02] active:scale-[0.98] hover:shadow-lg"
            >
              <SummaryCard
                title="Total Revenue"
                value={summaryTotalRevenue}
                growth={summaryRevenueGrowth}
                isPrimary
              />
            </div>
            <div
              onClick={() => setShowActiveOrdersModal(true)}
              className="cursor-pointer transform transition-all hover:scale-[1.02] active:scale-[0.98] hover:shadow-lg"
            >
              <SummaryCard title="Total Orders" value={summaryTotalOrders ?? '—'} growth={summaryOrdersGrowth} />
            </div>
            <div
              onClick={() => setShowNewCustomersModal(true)}
              className="cursor-pointer transform transition-all hover:scale-[1.02] active:scale-[0.98] hover:shadow-lg"
            >
              <SummaryCard title="New Customers" value={summaryNewCustomers ?? '—'} growth={summaryCustomersGrowth} />
            </div>
            <div
              onClick={() => setShowDeliveryAnalyticsModal(true)}
              className="cursor-pointer transform transition-all hover:scale-[1.02] active:scale-[0.98] hover:shadow-lg"
            >
              <SummaryCard title="Avg. Delivery Time" value={summaryAvgDelivery} growth={summaryDeliveryGrowth} />
            </div>
          </div>

          {/* Order Status + Alert */}
          <div className="grid grid-cols-1 lg:grid-cols-3 gap-3 sm:gap-4 md:gap-5 lg:gap-6">
            <div className="lg:col-span-2 order-1 lg:order-1">
              <OrderStatusWidget items={statusItems} loading={loading} onStatusClick={handleStatusClick} />
            </div>
            <div className="order-2 lg:order-2">
              <AlertCard onCta={() => setShowLateDeliveryModal(true)} />
            </div>
          </div>

          {/* Revenue Chart + Top Performers */}
          <div className="grid grid-cols-1 xl:grid-cols-3 gap-3 sm:gap-4 md:gap-5 lg:gap-6">
            <div className="xl:col-span-2 order-1">
              <RevenueChart
                range={range}
                onRangeChange={handleRangeChange}
                points={chartPoints}
                totalRevenue={trendTotals.totalRevenue}
                totalOrders={trendTotals.totalOrders}
              />
            </div>
            <div className="order-2">
              <TopPerformers items={topPerformersItems} />
            </div>
          </div>

          {/* Recent Orders + Customer Satisfaction + Quick Actions */}
          <div className="grid grid-cols-1 xl:grid-cols-3 gap-3 sm:gap-4 md:gap-5 lg:gap-6">
            <div className="xl:col-span-2 order-1">
              <RecentOrders items={recentOrdersItems} onViewAll={() => navigate(ROUTES.ORDERS)} />
            </div>
            <div className="xl:col-span-1 order-2">
              <div className="space-y-3 sm:space-y-4 md:space-y-5 lg:space-y-6">
                <CustomerSatisfaction
                  value={satisfaction?.overall ?? 0}
                  fiveStars={satisfaction?.five_stars ?? 0}
                  fourStars={satisfaction?.four_stars ?? 0}
                  lessThanThree={satisfaction?.less_than_three ?? 0}
                />
                <QuickActions
                  onCreateOrder={() => setShowCreateOrderModal(true)}
                  onAddCustomer={() => setShowAddCustomerModal(true)}
                  onAddStaff={() => setShowAddStaffModal(true)}
                  onSendNotification={() => setShowNotificationModal(true)}
                />
              </div>
            </div>
          </div>

          {/* Modals */}
          <ReportModal
            isOpen={showReportModal}
            onClose={() => setShowReportModal(false)}
            onSuccess={handleReportSuccess}
          />
          <CreateOrderModal
            isOpen={showCreateOrderModal}
            onClose={() => setShowCreateOrderModal(false)}
            onSuccess={handleCreateOrderSuccess}
          />
          <AddCustomerModal
            isOpen={showAddCustomerModal}
            onClose={() => setShowAddCustomerModal(false)}
            onSuccess={handleAddCustomerSuccess}
          />
          <AddStaffModal
            isOpen={showAddStaffModal}
            onClose={() => setShowAddStaffModal(false)}
            onSuccess={handleAddStaffSuccess}
          />
          <SendNotificationModal
            isOpen={showNotificationModal}
            onClose={() => setShowNotificationModal(false)}
            onSuccess={handleNotificationSuccess}
          />

      {/* Revenue Breakdown Modal */}
      <Modal
        isOpen={showRevenueModal}
        onClose={() => setShowRevenueModal(false)}
        title="Revenue Breakdown"
        size="lg"
      >
        <div className="space-y-4 sm:space-y-5 md:space-y-6">
          <div className="rounded-xl border border-slate-200 bg-slate-50 px-4 py-2 text-sm text-slate-600">
            Showing <span className="font-semibold">live data</span>.
          </div>
          {/* Error Message */}
          {revenueError && (
            <div className="rounded-xl border border-red-200 bg-red-50 p-4 text-center">
              <div className="text-red-600 text-sm font-medium">{revenueError}</div>
              <button
                onClick={() => fetchRevenueBreakdown()}
                className="mt-2 text-xs text-red-600 underline hover:text-red-700"
              >
                Try again
              </button>
            </div>
          )}

          {/* Loading State */}
          {revenueLoading && !revenueBreakdown && (
            <div className="flex items-center justify-center py-12">
              <Loader2 className="animate-spin h-8 w-8 text-blue-600" />
            </div>
          )}

          {/* Revenue Cards */}
          {!revenueLoading && revenueBreakdown && (
            <div className="grid grid-cols-1 sm:grid-cols-3 gap-3 sm:gap-4">
              {(['daily', 'weekly', 'monthly'] as const).map((key) => {
                const p = revenueBreakdown.periods[key];
                const isSelected = selectedRevenuePeriod === key;
                const delta = typeof p.delta_pct === 'number' ? p.delta_pct : 0;
                const isPositive = delta >= 0;
                const badgeText = `${delta > 0 ? '+' : ''}${delta.toFixed(1)}%`;
                const compareText =
                  p.compare_to === 'yesterday' ? 'vs yesterday' : p.compare_to === 'last_week' ? 'vs last week' : 'vs last month';

                return (
                  <button
                    key={key}
                    type="button"
                    onClick={() => setSelectedRevenuePeriod(key)}
                    className={[
                      'text-left rounded-2xl border p-4 transition-colors',
                      isSelected ? 'border-[#2F47FF] bg-[#EEF2FF]' : 'border-slate-200 bg-white hover:bg-slate-50',
                    ].join(' ')}
                  >
                    <div className="flex items-start justify-between gap-2">
                      <div>
                        <div className="text-sm text-slate-600 capitalize">{key}</div>
                        <div className="mt-1 text-2xl font-semibold text-[#2F47FF]">
                          {formatCompactCurrency(p.revenue || 0)}
                        </div>
                        <div className="mt-1 text-xs text-slate-500">{compareText}</div>
                      </div>
                      <div
                        className={[
                          'shrink-0 rounded-full px-2 py-1 text-xs font-semibold',
                          isPositive ? 'bg-emerald-100 text-emerald-700' : 'bg-red-100 text-red-700',
                        ].join(' ')}
                      >
                        {badgeText}
                      </div>
                    </div>
                  </button>
                );
              })}
            </div>
          )}

          {/* Revenue Trend Chart */}
          {!revenueLoading && revenueBreakdown && (
            <div className="rounded-2xl border border-slate-200 bg-white p-4 sm:p-5">
              <div className="flex items-start justify-between gap-3">
                <div>
                  <div className="text-sm font-semibold text-slate-900">Revenue Trend</div>
                  <div className="text-xs text-slate-500">Last 7 days</div>
                </div>
                <div className="flex items-center gap-3 text-xs text-slate-600">
                  <div className="flex items-center gap-1.5">
                    <span className="h-2 w-2 rounded-full bg-[#2F47FF]" />
                    Revenue
                  </div>
                  <div className="flex items-center gap-1.5">
                    <span className="h-2 w-2 rounded-full bg-[#EF4444]" />
                    Orders
                  </div>
                </div>
              </div>

              <div className="mt-3 h-56">
                <ResponsiveContainer width="100%" height="100%">
                  <ComposedChart data={revenueBreakdown.trend_last_7_days}>
                    <defs>
                      <linearGradient id="revGrad" x1="0" y1="0" x2="0" y2="1">
                        <stop offset="0%" stopColor="#2F47FF" stopOpacity={0.9} />
                        <stop offset="100%" stopColor="#2F47FF" stopOpacity={0.2} />
                      </linearGradient>
                    </defs>
                    <CartesianGrid stroke="#E2E8F0" strokeDasharray="3 3" vertical={false} />
                    <XAxis dataKey="label" axisLine={false} tickLine={false} tick={{ fill: '#64748B', fontSize: 12 }} />
                    <YAxis
                      yAxisId="rev"
                      axisLine={false}
                      tickLine={false}
                      tick={{ fill: '#64748B', fontSize: 12 }}
                      width={40}
                    />
                    <YAxis
                      yAxisId="ord"
                      orientation="right"
                      axisLine={false}
                      tickLine={false}
                      tick={{ fill: '#64748B', fontSize: 12 }}
                      width={30}
                    />
                    <Tooltip
                      cursor={{ fill: 'rgba(148,163,184,0.12)' }}
                      contentStyle={{
                        backgroundColor: 'white',
                        border: '1px solid #E2E8F0',
                        borderRadius: '10px',
                        boxShadow: '0 10px 30px rgba(15,23,42,0.10)',
                        fontSize: '12px',
                      }}
                      formatter={(value: any, name: any) => {
                        if (name === 'revenue') return [formatCompactCurrency(Number(value) || 0), 'Revenue'];
                        if (name === 'orders') return [Number(value) || 0, 'Orders'];
                        return [value, name];
                      }}
                      labelFormatter={(label: any) => String(label)}
                    />
                    <Bar yAxisId="rev" dataKey="revenue" fill="url(#revGrad)" radius={[10, 10, 0, 0]} barSize={26} />
                    <Line
                      yAxisId="ord"
                      type="monotone"
                      dataKey="orders"
                      stroke="#EF4444"
                      strokeWidth={2}
                      dot={{ r: 3, strokeWidth: 2, fill: '#fff' }}
                      activeDot={{ r: 4 }}
                    />
                  </ComposedChart>
                </ResponsiveContainer>
              </div>
            </div>
          )}
        </div>
      </Modal>

      {/* Active Orders Modal */}
      <ActiveOrdersModal
        isOpen={showActiveOrdersModal}
        onClose={() => setShowActiveOrdersModal(false)}
      />

      {/* New Customers Modal */}
      <NewCustomersModal
        isOpen={showNewCustomersModal}
        onClose={() => setShowNewCustomersModal(false)}
      />

      {/* Delivery Analytics Modal */}
      <DeliveryAnalyticsModal
        isOpen={showDeliveryAnalyticsModal}
        onClose={() => setShowDeliveryAnalyticsModal(false)}
      />

      {/* Late Delivery Modal */}
      <LateDeliveryModal
        isOpen={showLateDeliveryModal}
        onClose={() => setShowLateDeliveryModal(false)}
      />

      <FilteredOrdersModal
        isOpen={showFilteredOrdersModal}
        onClose={() => setShowFilteredOrdersModal(false)}
        status={selectedStatus}
      />

      <AllRecentOrdersModal
        isOpen={showAllRecentOrdersModal}
        onClose={() => setShowAllRecentOrdersModal(false)}
      />

      {/* Floating Action Button */}
      <FloatingActionButton
        onCreateOrder={() => setShowCreateOrderModal(true)}
        onAddStaff={() => setShowAddStaffModal(true)}
        onCreateReport={() => setShowReportModal(true)}
        onSendNotification={() => setShowNotificationModal(true)}
      />

      {/* Toast Notification */}
      <Toast
        message={toast.message}
        type={toast.type}
        isVisible={toast.isVisible}
        onClose={hideToast}
      />
        </div>
      </div>
    </div>
  );
};
