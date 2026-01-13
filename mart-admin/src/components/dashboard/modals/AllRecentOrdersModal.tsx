import React, { useState, useEffect, useCallback } from 'react';
import { Modal } from '@/components/common';
import { Search, Download, ChevronLeft, ChevronRight, Loader2 } from 'lucide-react';
import { dashboardApi, AdminDashboardRecentOrder } from '@/services/api/modules/dashboardApi';
import { formatCurrency } from '@/utils/formatters';
import { formatTimeFromSeconds } from '@/utils/formatters/dateFormatter';

interface AllRecentOrdersModalProps {
  isOpen: boolean;
  onClose: () => void;
}

export const AllRecentOrdersModal: React.FC<AllRecentOrdersModalProps> = ({ isOpen, onClose }) => {
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [orders, setOrders] = useState<AdminDashboardRecentOrder[]>([]);
  const [searchTerm, setSearchTerm] = useState('');
  const [debouncedSearch, setDebouncedSearch] = useState('');

  // Debounce search input (300ms delay)
  useEffect(() => {
    const timer = setTimeout(() => {
      setDebouncedSearch(searchTerm);
    }, 300);

    return () => clearTimeout(timer);
  }, [searchTerm]);

  // Fetch recent orders
  const fetchOrders = useCallback(async () => {
    if (!isOpen) return;
    
    setLoading(true);
    setError(null);

    try {
      const response = await dashboardApi.getAdminRecentOrders({ limit: 100 });

      if (response.success && response.data) {
        let filteredOrders = response.data;
        
        // Client-side search filtering
        if (debouncedSearch) {
          filteredOrders = filteredOrders.filter(order =>
            order.orderNumber.toLowerCase().includes(debouncedSearch.toLowerCase()) ||
            (order.customerName && order.customerName.toLowerCase().includes(debouncedSearch.toLowerCase()))
          );
        }
        
        setOrders(filteredOrders);
      } else {
        setError('Failed to fetch recent orders');
      }
    } catch (err: any) {
      console.error('Failed to fetch recent orders:', err);
      const errorMessage = err?.response?.data?.message || 'Failed to load recent orders. Please try again.';
      setError(errorMessage);
      setOrders([]);
    } finally {
      setLoading(false);
    }
  }, [isOpen, debouncedSearch]);

  useEffect(() => {
    fetchOrders();
  }, [fetchOrders]);

  const getStatusColor = (status: string | null): string => {
    if (!status) return 'bg-gray-100 text-gray-800';
    
    switch (status.toLowerCase()) {
      case 'pending':
      case 'placed':
        return 'bg-yellow-100 text-yellow-800';
      case 'in progress':
      case 'services_in_progress':
      case 'submitted_to_services':
        return 'bg-blue-100 text-blue-800';
      case 'out for delivery':
      case 'out_for_delivery':
        return 'bg-cyan-100 text-cyan-800';
      case 'delivered':
      case 'closed':
        return 'bg-green-100 text-green-800';
      default:
        return 'bg-gray-100 text-gray-800';
    }
  };

  const formatAmount = (amount: string | null | undefined): string => {
    if (!amount) return '₹0';
    const numAmount = parseFloat(amount);
    return formatCurrency(numAmount);
  };

  const formatTimeElapsed = (order: AdminDashboardRecentOrder): string => {
    if (order.timeElapsedSeconds !== null && order.timeElapsedSeconds !== undefined) {
      return formatTimeFromSeconds(order.timeElapsedSeconds);
    }
    if (order.createdAt) {
      return formatTimeFromSeconds(Math.floor((Date.now() - new Date(order.createdAt).getTime()) / 1000));
    }
    return 'N/A';
  };

  const handleExport = () => {
    // Simulate export
    console.log('Exporting all recent orders...');
  };

  return (
    <Modal isOpen={isOpen} onClose={onClose} title="All Recent Orders" size="xl">
      <div className="space-y-4">
        {/* Search and Export */}
        <div className="flex gap-3">
          <div className="flex-1 relative">
            <Search className="absolute left-3 top-1/2 transform -translate-y-1/2 text-slate-400" size={18} />
            <input
              type="text"
              placeholder="Search by Order ID or Customer name..."
              value={searchTerm}
              onChange={(e) => setSearchTerm(e.target.value)}
              className="w-full pl-10 pr-4 py-2 border border-slate-200 rounded-xl focus:outline-none focus:ring-2 focus:ring-blue-500"
            />
          </div>
          <button
            onClick={handleExport}
            className="px-4 py-2 border border-slate-300 text-slate-700 rounded-xl hover:bg-slate-50 flex items-center gap-2 transition-colors"
          >
            <Download size={18} />
            Export
          </button>
        </div>

        {/* Error Message */}
        {error && (
          <div className="rounded-xl border border-red-200 bg-red-50 p-4 text-center">
            <div className="text-red-600 text-sm font-medium">{error}</div>
            <button
              onClick={() => fetchOrders()}
              className="mt-2 text-xs text-red-600 underline hover:text-red-700"
            >
              Try again
            </button>
          </div>
        )}

        {/* Loading State */}
        {loading && orders.length === 0 && (
          <div className="flex items-center justify-center py-12">
            <Loader2 className="animate-spin h-8 w-8 text-blue-600" />
          </div>
        )}

        {/* Orders Table */}
        {!loading && !error && (
          <>
            <div className="border border-slate-200 rounded-xl overflow-hidden">
              <div className="overflow-x-auto">
                <table className="w-full">
                  <thead className="bg-slate-50 border-b border-slate-200">
                    <tr>
                      <th className="px-4 py-3 text-left text-xs font-semibold text-slate-700 uppercase tracking-wider">
                        Order ID
                      </th>
                      <th className="px-4 py-3 text-left text-xs font-semibold text-slate-700 uppercase tracking-wider">
                        Customer
                      </th>
                      <th className="px-4 py-3 text-left text-xs font-semibold text-slate-700 uppercase tracking-wider">
                        Amount
                      </th>
                      <th className="px-4 py-3 text-left text-xs font-semibold text-slate-700 uppercase tracking-wider">
                        Assigned Staff
                      </th>
                      <th className="px-4 py-3 text-left text-xs font-semibold text-slate-700 uppercase tracking-wider">
                        Status
                      </th>
                      <th className="px-4 py-3 text-left text-xs font-semibold text-slate-700 uppercase tracking-wider">
                        Time
                      </th>
                      <th className="px-4 py-3 text-left text-xs font-semibold text-slate-700 uppercase tracking-wider">
                        Actions
                      </th>
                    </tr>
                  </thead>
                  <tbody className="divide-y divide-slate-200">
                    {orders.length === 0 ? (
                      <tr>
                        <td colSpan={7} className="px-6 py-12 text-center">
                          <p className="text-slate-500">No orders found</p>
                        </td>
                      </tr>
                    ) : (
                      orders.map((order) => (
                        <tr key={order.orderNumber} className="hover:bg-slate-50 transition-colors">
                          <td className="px-4 py-3 text-sm font-medium text-slate-900">
                            {order.orderNumber}
                          </td>
                          <td className="px-4 py-3 text-sm text-slate-700">
                            {order.customerName || 'Unknown Customer'}
                          </td>
                          <td className="px-4 py-3 text-sm font-semibold text-slate-900">
                            {formatAmount(order.amount)}
                          </td>
                          <td className="px-4 py-3 text-sm text-slate-700">
                            {order.deliveryStaffName || '—'}
                          </td>
                          <td className="px-4 py-3">
                            <span className={`px-2.5 py-1 rounded-full text-xs font-medium ${getStatusColor(order.status)}`}>
                              {order.status || 'Unknown'}
                            </span>
                          </td>
                          <td className="px-4 py-3 text-sm text-slate-600">
                            {formatTimeElapsed(order)}
                          </td>
                          <td className="px-4 py-3 text-sm">
                            <button className="text-blue-600 hover:text-blue-700 font-medium">
                              View
                            </button>
                          </td>
                        </tr>
                      ))
                    )}
                  </tbody>
                </table>
              </div>
            </div>

            {/* Results Count */}
            {orders.length > 0 && (
              <div className="text-sm text-slate-600 text-center">
                Showing {orders.length} recent order{orders.length !== 1 ? 's' : ''}
              </div>
            )}
          </>
        )}
      </div>
    </Modal>
  );
};


