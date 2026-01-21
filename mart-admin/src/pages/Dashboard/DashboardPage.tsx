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
import { dashboardApi } from '@/services/api/modules/dashboardApi';
import { useEffect, useCallback } from 'react';
import { Download, Loader2, Plus } from 'lucide-react';
import { useNavigate } from 'react-router-dom';
import { ROUTES } from '@/routes';
import { ExportDropdown } from '@/components/layout/Header/ExportDropdown';

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
  const [revenueData, setRevenueData] = useState<{
    daily: number;
    weekly: number;
    monthly: number;
  } | null>(null);

  const { data, error, loading, range, setRange, refresh } = useDashboard();

  // Fetch revenue data for different periods
  const fetchRevenueData = useCallback(async () => {
    if (!showRevenueModal) return;
    
    setRevenueLoading(true);
    setRevenueError(null);

    try {
      const now = new Date();
      
      // Daily: Today
      const todayStart = new Date(now.getFullYear(), now.getMonth(), now.getDate());
      const todayEnd = new Date(now.getFullYear(), now.getMonth(), now.getDate(), 23, 59, 59);
      
      // Weekly: Last 7 days
      const weekStart = new Date(now);
      weekStart.setDate(weekStart.getDate() - 7);
      
      // Monthly: Current month
      const monthStart = new Date(now.getFullYear(), now.getMonth(), 1);
      const monthEnd = new Date(now.getFullYear(), now.getMonth() + 1, 0, 23, 59, 59);

      const [dailyRes, weeklyRes, monthlyRes] = await Promise.all([
        dashboardApi.getAdminSummary({
          from: todayStart.toISOString(),
          to: todayEnd.toISOString(),
        }),
        dashboardApi.getAdminSummary({
          from: weekStart.toISOString(),
          to: now.toISOString(),
        }),
        dashboardApi.getAdminSummary({
          from: monthStart.toISOString(),
          to: monthEnd.toISOString(),
        }),
      ]);

      if (dailyRes.success && weeklyRes.success && monthlyRes.success) {
        setRevenueData({
          daily: dailyRes.data?.totalRevenue || 0,
          weekly: weeklyRes.data?.totalRevenue || 0,
          monthly: monthlyRes.data?.totalRevenue || 0,
        });
      } else {
        setRevenueError('Failed to fetch revenue data');
      }
    } catch (err: any) {
      console.error('Failed to fetch revenue data:', err);
      const errorMessage = err?.response?.data?.message || 'Failed to load revenue data. Please try again.';
      setRevenueError(errorMessage);
      setRevenueData(null);
    } finally {
      setRevenueLoading(false);
    }
  }, [showRevenueModal]);

  useEffect(() => {
    fetchRevenueData();
  }, [fetchRevenueData]);

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
          {/* Error Message */}
          {revenueError && (
            <div className="rounded-xl border border-red-200 bg-red-50 p-4 text-center">
              <div className="text-red-600 text-sm font-medium">{revenueError}</div>
              <button
                onClick={() => fetchRevenueData()}
                className="mt-2 text-xs text-red-600 underline hover:text-red-700"
              >
                Try again
              </button>
            </div>
          )}

          {/* Loading State */}
          {revenueLoading && !revenueData && (
            <div className="flex items-center justify-center py-12">
              <Loader2 className="animate-spin h-8 w-8 text-blue-600" />
            </div>
          )}

          {/* Revenue Cards */}
          {!revenueLoading && (
            <div className="grid grid-cols-1 sm:grid-cols-3 gap-3 sm:gap-4">
              <div className="text-center p-3 sm:p-4 bg-blue-50 rounded-lg sm:rounded-xl">
                <p className="text-xs sm:text-sm text-slate-600 mb-1">Daily</p>
                {revenueLoading ? (
                  <Loader2 className="animate-spin h-6 w-6 mx-auto text-blue-600" />
                ) : (
                  <p className="text-xl sm:text-2xl font-bold text-blue-600">
                    {formatCompactCurrency(revenueData?.daily || 0)}
                  </p>
                )}
              </div>
              <div className="text-center p-3 sm:p-4 bg-blue-50 rounded-lg sm:rounded-xl">
                <p className="text-xs sm:text-sm text-slate-600 mb-1">Weekly</p>
                {revenueLoading ? (
                  <Loader2 className="animate-spin h-6 w-6 mx-auto text-blue-600" />
                ) : (
                  <p className="text-xl sm:text-2xl font-bold text-blue-600">
                    {formatCompactCurrency(revenueData?.weekly || 0)}
                  </p>
                )}
              </div>
              <div className="text-center p-3 sm:p-4 bg-blue-50 rounded-lg sm:rounded-xl">
                <p className="text-xs sm:text-sm text-slate-600 mb-1">Monthly</p>
                {revenueLoading ? (
                  <Loader2 className="animate-spin h-6 w-6 mx-auto text-blue-600" />
                ) : (
                  <p className="text-xl sm:text-2xl font-bold text-blue-600">
                    {formatCompactCurrency(revenueData?.monthly || 0)}
                  </p>
                )}
              </div>
            </div>
          )}
          <div className="h-48 sm:h-56 md:h-64 bg-slate-50 rounded-lg sm:rounded-xl flex items-center justify-center">
            <p className="text-sm sm:text-base text-slate-500">Revenue Trend Chart</p>
          </div>
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
