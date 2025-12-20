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

  return (
    <div className="space-y-3 sm:space-y-4 md:space-y-5 lg:space-y-6">
      {/* Summary Cards */}
      <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-2 xl:grid-cols-4 gap-3 sm:gap-4 md:gap-5 lg:gap-6">
        <div
          onClick={() => setShowRevenueModal(true)}
          className="cursor-pointer transform transition-all hover:scale-[1.02] active:scale-[0.98] hover:shadow-lg"
        >
          <SummaryCard
            title="Total Revenue"
            value="$12,845"
            growth="+18.2%"
            isPrimary
          />
        </div>
        <div
          onClick={() => setShowActiveOrdersModal(true)}
          className="cursor-pointer transform transition-all hover:scale-[1.02] active:scale-[0.98] hover:shadow-lg"
        >
          <SummaryCard title="Active Orders" value={47} growth="+12.5%" />
        </div>
        <div
          onClick={() => setShowNewCustomersModal(true)}
          className="cursor-pointer transform transition-all hover:scale-[1.02] active:scale-[0.98] hover:shadow-lg"
        >
          <SummaryCard title="New Customers" value={58} growth="+8.3%" />
        </div>
        <div
          onClick={() => setShowDeliveryAnalyticsModal(true)}
          className="cursor-pointer transform transition-all hover:scale-[1.02] active:scale-[0.98] hover:shadow-lg"
        >
          <SummaryCard title="Avg. Delivery Time" value="28 min" growth="+12.5%" />
        </div>
      </div>

      {/* Order Status + Alert */}
      <div className="grid grid-cols-1 lg:grid-cols-3 gap-3 sm:gap-4 md:gap-5 lg:gap-6">
        <div className="lg:col-span-2 order-1 lg:order-1">
          <OrderStatusWidget onStatusClick={handleStatusClick} />
        </div>
        <div className="order-2 lg:order-2">
          <AlertCard onCta={() => setShowLateDeliveryModal(true)} />
        </div>
      </div>

      {/* Revenue Chart + Top Performers */}
      <div className="grid grid-cols-1 xl:grid-cols-3 gap-3 sm:gap-4 md:gap-5 lg:gap-6">
        <div className="xl:col-span-2 order-1">
          <RevenueChart />
        </div>
        <div className="order-2">
          <TopPerformers />
        </div>
      </div>

      {/* Recent Orders + Customer Satisfaction + Quick Actions */}
      <div className="grid grid-cols-1 xl:grid-cols-3 gap-3 sm:gap-4 md:gap-5 lg:gap-6">
        <div className="xl:col-span-2 order-1">
          <RecentOrders onViewAll={() => setShowAllRecentOrdersModal(true)} />
        </div>
        <div className="xl:col-span-1 order-2">
          <div className="space-y-3 sm:space-y-4 md:space-y-5 lg:space-y-6">
            <CustomerSatisfaction />
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
          <div className="grid grid-cols-1 sm:grid-cols-3 gap-3 sm:gap-4">
            <div className="text-center p-3 sm:p-4 bg-blue-50 rounded-lg sm:rounded-xl">
              <p className="text-xs sm:text-sm text-slate-600 mb-1">Daily</p>
              <p className="text-xl sm:text-2xl font-bold text-blue-600">$3,210</p>
            </div>
            <div className="text-center p-3 sm:p-4 bg-blue-50 rounded-lg sm:rounded-xl">
              <p className="text-xs sm:text-sm text-slate-600 mb-1">Weekly</p>
              <p className="text-xl sm:text-2xl font-bold text-blue-600">$8,940</p>
            </div>
            <div className="text-center p-3 sm:p-4 bg-blue-50 rounded-lg sm:rounded-xl">
              <p className="text-xs sm:text-sm text-slate-600 mb-1">Monthly</p>
              <p className="text-xl sm:text-2xl font-bold text-blue-600">$12,845</p>
            </div>
          </div>
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
