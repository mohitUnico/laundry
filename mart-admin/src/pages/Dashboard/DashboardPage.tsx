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
import { Download } from 'lucide-react';
import { useDashboard } from '@/hooks/api';
import { formatCompactCurrency } from '@/utils/formatters';
import { dashboardApi } from '@/services/api/modules/dashboardApi';
import { useEffect, useCallback } from 'react';
import { Loader2 } from 'lucide-react';

export const DashboardPage: React.FC = () => {
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
  const [revenueLoading, setRevenueLoading] = useState(false);
  const [revenueError, setRevenueError] = useState<string | null>(null);
  const [revenueData, setRevenueData] = useState<{
    daily: number;
    weekly: number;
    monthly: number;
  } | null>(null);

  const { data, loading, error, range, setRange, refresh } = useDashboard();

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

  const handleExportReport = () => {
    showToast('Report exported successfully!', 'success');
  };

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

  const summary = data.summary;
  const orderStatus = data.orderStatus;
  const trend = data.revenueTrend || [];
  const satisfaction = data.customerSatisfaction;

  const summaryTotalRevenue = summary ? formatCompactCurrency(summary.totalRevenue || 0) : '—';
  const summaryActiveOrders = orderStatus
    ? orderStatus.pending + orderStatus.inProgress + orderStatus.outForDelivery
    : null;
  const summaryNewCustomers = summary ? summary.newCustomers : null;
  const summaryAvgDelivery = summary ? `${summary.averageDeliveryTime} min` : '—';

  // Admin dashboard doesn't provide growth deltas; keep UI consistent with "—"
  const summaryRevenueGrowth = '—';
  const summaryOrdersGrowth = '—';
  const summaryCustomersGrowth = '—';
  const summaryDeliveryGrowth = '—';

  const statusItems = orderStatus
    ? [
        { label: 'Pending', count: orderStatus.pending, color: '#facc15' },
        { label: 'In progress', count: orderStatus.inProgress, color: '#60a5fa' },
        { label: 'Out for delivery', count: orderStatus.outForDelivery, color: '#22d3ee' },
        { label: 'Completed today', count: orderStatus.completedToday, color: '#34d399' },
      ]
    : undefined;

  const recentOrdersItems =
    (data.recentOrders || []).map((o) => ({
      id: o.orderNumber,
      customer: o.customerName || 'Unknown Customer',
      amount: Number.parseFloat(o.amount) || 0,
      status: o.status || 'unknown',
      timeIso: o.createdAt || new Date().toISOString(),
    })) || [];

  const topPerformersItems =
    (data.topPerformers || []).map((p) => ({
      name: p.deliveryStaffName,
      deliveries: p.totalDeliveries,
      rating: p.rating,
      avatarUrl: null,
    })) || [];

  const chartPoints = trend
    .filter((p) => p.date)
    .map((p) => ({
      label: p.date as string,
      totalRevenue: p.totalRevenue,
      totalOrders: p.totalOrders,
    }));

  const trendTotals = trend.reduce(
    (acc, p) => {
      acc.totalRevenue += p.totalRevenue || 0;
      acc.totalOrders += p.totalOrders || 0;
      return acc;
    },
    { totalRevenue: 0, totalOrders: 0 }
  );

  const handleRangeChange = (nextRange: '7d' | '30d') => {
    setRange(nextRange);
  };

  const handleRefresh = async () => {
    await refresh();
    showToast('Dashboard refreshed', 'success');
  };

  const handleRetry = async () => {
    await refresh();
  };

  return (
    <div className="space-y-3 sm:space-y-4 md:space-y-5 lg:space-y-6">
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
          <SummaryCard title="Active Orders" value={summaryActiveOrders ?? '—'} growth={summaryOrdersGrowth} />
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
          <OrderStatusWidget items={statusItems} onStatusClick={handleStatusClick} />
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
          <RecentOrders items={recentOrdersItems} onViewAll={() => setShowAllRecentOrdersModal(true)} />
        </div>
        <div className="xl:col-span-1 order-2">
          <div className="space-y-3 sm:space-y-4 md:space-y-5 lg:space-y-6">
            <CustomerSatisfaction
              value={satisfaction?.overallPercentage ?? 0}
              fiveStars={satisfaction?.distribution?.fiveStar ?? 0}
              fourStars={satisfaction?.distribution?.fourStar ?? 0}
              lessThanThree={satisfaction?.distribution?.lessThanThree ?? 0}
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
  );
};
