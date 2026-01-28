import React, { useState, useEffect, useCallback } from 'react';
import { Modal } from '@/components/common';
import { Search, Download, Loader2 } from 'lucide-react';
import { adminManagementApi, AdminOrdersListItem } from '@/services/api/modules/adminManagementApi';
import { formatCurrency } from '@/utils/formatters';
import { formatTime } from '@/utils/formatters/dateFormatter';

interface ActiveOrdersModalProps {
  isOpen: boolean;
  onClose: () => void;
}

// "Active" (as used in UI modal) = everything except draft/closed/cancelled.
// This matches the Orders page expectation where "Delivered" is still shown.
const ACTIVE_STATUSES =
  'placed,pickup_assigned,picked_up,submitted_to_cm,received_by_collection,submitted_to_services,services_in_progress,services_completed,dispatch_assigned,out_for_delivery,payment_pending,delivered';

const formatStatus = (status: string | null): string => {
  if (!status) return 'Unknown';
  
  const statusMap: { [key: string]: string } = {
    placed: 'Placed',
    pickup_assigned: 'Pickup Assigned',
    picked_up: 'Picked Up',
    submitted_to_cm: 'Submitted to CM',
    received_by_collection: 'Received',
    submitted_to_services: 'In Service',
    services_in_progress: 'In Progress',
    services_completed: 'Services Completed',
    dispatch_assigned: 'Dispatch Assigned',
    out_for_delivery: 'Out for Delivery',
    payment_pending: 'Payment Pending',
    delivered: 'Delivered',
  };
  
  return statusMap[status] || status.replace(/_/g, ' ').replace(/\b\w/g, l => l.toUpperCase());
};

export const ActiveOrdersModal: React.FC<ActiveOrdersModalProps> = ({ isOpen, onClose }) => {
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [orders, setOrders] = useState<AdminOrdersListItem[]>([]);
  const [search, setSearch] = useState('');
  const [debouncedSearch, setDebouncedSearch] = useState('');
  const [page, setPage] = useState(1);
  const [pagination, setPagination] = useState({
    page: 1,
    limit: 20,
    total: 0,
    total_pages: 0,
    has_next: false,
    has_prev: false,
  });

  // Debounce search input (300ms delay)
  useEffect(() => {
    const timer = setTimeout(() => {
      setDebouncedSearch(search);
      setPage(1); // Reset to first page on search change
    }, 300);

    return () => clearTimeout(timer);
  }, [search]);

  // Fetch active orders
  const fetchOrders = useCallback(async () => {
    if (!isOpen) return;
    
    setLoading(true);
    setError(null);

    try {
      const response = await adminManagementApi.getAdminOrders({
        status: ACTIVE_STATUSES,
        search: debouncedSearch || undefined,
        page,
        limit: 20,
      });

      if (response.success && response.data) {
        setOrders(response.data.orders);
        setPagination(response.data.pagination);
      } else {
        setError('Failed to fetch active orders');
      }
    } catch (err: any) {
      console.error('Failed to fetch active orders:', err);
      const errorMessage = err?.response?.data?.message || 'Failed to load active orders. Please try again.';
      setError(errorMessage);
      setOrders([]);
    } finally {
      setLoading(false);
    }
  }, [isOpen, debouncedSearch, page]);

  useEffect(() => {
    fetchOrders();
  }, [fetchOrders]);

  const statusColors: { [key: string]: string } = {
    'In Progress': 'bg-blue-50 text-blue-700 border-blue-200',
    'Picked Up': 'bg-purple-50 text-purple-700 border-purple-200',
    'Out for Delivery': 'bg-emerald-50 text-emerald-700 border-emerald-200',
    'Placed': 'bg-yellow-50 text-yellow-700 border-yellow-200',
    'Pickup Assigned': 'bg-indigo-50 text-indigo-700 border-indigo-200',
    'Received': 'bg-slate-50 text-slate-700 border-slate-200',
    'In Service': 'bg-blue-50 text-blue-700 border-blue-200',
    'Dispatch Assigned': 'bg-cyan-50 text-cyan-700 border-cyan-200',
  };

  const formatAmount = (amount: string | number | null): string => {
    if (!amount) return '₹0';
    const numAmount = typeof amount === 'string' ? parseFloat(amount) : amount;
    return formatCurrency(numAmount);
  };

  return (
    <Modal isOpen={isOpen} onClose={onClose} title="Active Orders" size="xl">
      <div className="space-y-3 sm:space-y-4">
        {/* Search and Export */}
        <div className="flex flex-col sm:flex-row items-stretch sm:items-center gap-2 sm:gap-3">
          <div className="relative flex-1">
            <Search size={16} className="sm:w-[18px] sm:h-[18px] absolute left-2.5 sm:left-3 top-1/2 -translate-y-1/2 text-slate-400" />
            <input
              type="text"
              placeholder="Search orders..."
              value={search}
              onChange={(e) => setSearch(e.target.value)}
              className="w-full pl-8 sm:pl-10 pr-3 sm:pr-4 py-2 text-xs sm:text-sm border border-slate-200 rounded-lg sm:rounded-xl focus:outline-none focus:ring-2 focus:ring-blue-500 focus:border-transparent"
            />
          </div>
          <button className="flex items-center justify-center gap-1.5 sm:gap-2 px-3 sm:px-4 py-2 text-xs sm:text-sm border border-slate-200 text-slate-700 rounded-lg sm:rounded-xl hover:bg-slate-50 transition-colors">
            <Download size={16} className="sm:w-[18px] sm:h-[18px]" />
            <span className="font-medium">Export</span>
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

        {/* Mobile Card View */}
        {!loading && !error && (
          <>
            <div className="block sm:hidden space-y-2">
              {orders.length === 0 ? (
                <div className="text-center py-12">
                  <p className="text-slate-500 text-sm">No active orders found</p>
                </div>
              ) : (
                orders.map((order) => {
                  const displayStatus = formatStatus(order.status);
                  return (
                    <div key={order.order_number} className="border border-slate-200 rounded-lg p-3 space-y-2">
                      <div className="flex items-start justify-between">
                        <div className="flex-1 min-w-0">
                          <div className="text-sm font-medium text-slate-900">{order.order_number}</div>
                          <div className="text-xs text-slate-600 mt-0.5">{order.customer?.name || 'Unknown Customer'}</div>
                        </div>
                        <span className={`inline-flex items-center px-2 py-0.5 rounded-full text-[10px] font-medium border ml-2 flex-shrink-0 ${statusColors[displayStatus] || 'bg-gray-50 text-gray-700 border-gray-200'}`}>
                          {displayStatus}
                        </span>
                      </div>
                      <div className="grid grid-cols-2 gap-2 text-xs pt-1 border-t border-slate-100">
                        <div>
                          <span className="text-slate-500">Amount:</span>
                          <span className="text-slate-900 font-semibold ml-1">{formatAmount(order.amount)}</span>
                        </div>
                        <div>
                          <span className="text-slate-500">Staff:</span>
                          <span className="text-slate-700 ml-1 truncate">{order.delivery_boy?.name || '—'}</span>
                        </div>
                        <div className="col-span-2">
                          <span className="text-slate-500">ETA:</span>
                          <span className="text-slate-600 ml-1">{formatTime(order.estimated_delivery_time?.delivery_date) || '—'}</span>
                        </div>
                      </div>
                    </div>
                  );
                })
              )}
            </div>

            {/* Desktop Table View */}
            <div className="hidden sm:block overflow-x-auto">
              <table className="w-full min-w-[600px]">
                <thead className="bg-slate-50 border-b border-slate-200">
                  <tr>
                    <th className="px-3 sm:px-4 py-2 sm:py-3 text-left text-xs sm:text-sm font-semibold text-slate-700">Order ID</th>
                    <th className="px-3 sm:px-4 py-2 sm:py-3 text-left text-xs sm:text-sm font-semibold text-slate-700">Customer</th>
                    <th className="px-3 sm:px-4 py-2 sm:py-3 text-left text-xs sm:text-sm font-semibold text-slate-700">Amount</th>
                    <th className="px-3 sm:px-4 py-2 sm:py-3 text-left text-xs sm:text-sm font-semibold text-slate-700">Status</th>
                    <th className="px-3 sm:px-4 py-2 sm:py-3 text-left text-xs sm:text-sm font-semibold text-slate-700 hidden md:table-cell">Assigned Staff</th>
                    <th className="px-3 sm:px-4 py-2 sm:py-3 text-left text-xs sm:text-sm font-semibold text-slate-700">ETA</th>
                  </tr>
                </thead>
                <tbody className="divide-y divide-slate-100">
                  {orders.length === 0 ? (
                    <tr>
                      <td colSpan={6} className="px-6 py-12 text-center">
                        <p className="text-slate-500 text-sm">No active orders found</p>
                      </td>
                    </tr>
                  ) : (
                    orders.map((order) => {
                      const displayStatus = formatStatus(order.status);
                      return (
                        <tr key={order.order_number} className="hover:bg-slate-50 transition-colors">
                          <td className="px-3 sm:px-4 py-2 sm:py-3">
                            <span className="text-xs sm:text-sm font-medium text-slate-900">{order.order_number}</span>
                          </td>
                          <td className="px-3 sm:px-4 py-2 sm:py-3">
                            <span className="text-xs sm:text-sm text-slate-700">{order.customer?.name || 'Unknown Customer'}</span>
                          </td>
                          <td className="px-3 sm:px-4 py-2 sm:py-3">
                            <span className="text-xs sm:text-sm font-semibold text-slate-900">{formatAmount(order.amount)}</span>
                          </td>
                          <td className="px-3 sm:px-4 py-2 sm:py-3">
                            <span className={`inline-flex items-center px-2 sm:px-2.5 py-0.5 sm:py-1 rounded-full text-[10px] sm:text-xs font-medium border ${statusColors[displayStatus] || 'bg-gray-50 text-gray-700 border-gray-200'}`}>
                              {displayStatus}
                            </span>
                          </td>
                          <td className="px-3 sm:px-4 py-2 sm:py-3 hidden md:table-cell">
                            <span className="text-xs sm:text-sm text-slate-700">{order.delivery_boy?.name || '—'}</span>
                          </td>
                          <td className="px-3 sm:px-4 py-2 sm:py-3">
                            <span className="text-xs sm:text-sm text-slate-600">{formatTime(order.estimated_delivery_time?.delivery_date) || '—'}</span>
                          </td>
                        </tr>
                      );
                    })
                  )}
                </tbody>
              </table>
            </div>

            {/* Pagination */}
            {pagination.total > 0 && (
              <div className="flex flex-col sm:flex-row items-stretch sm:items-center justify-between gap-2 sm:gap-0 pt-3 sm:pt-4 border-t border-slate-200">
                <p className="text-xs sm:text-sm text-slate-600 text-center sm:text-left">
                  Showing {((pagination.page - 1) * pagination.limit) + 1} to {Math.min(pagination.page * pagination.limit, pagination.total)} of {pagination.total} active orders
                </p>
                <div className="flex items-center justify-center gap-1.5 sm:gap-2">
                  <button
                    onClick={() => setPage(prev => Math.max(1, prev - 1))}
                    disabled={!pagination.has_prev || loading}
                    className="px-2.5 sm:px-3 py-1.5 text-xs sm:text-sm border border-slate-200 text-slate-700 rounded-lg hover:bg-slate-50 font-medium transition-colors disabled:opacity-50 disabled:cursor-not-allowed"
                  >
                    Previous
                  </button>
                  {Array.from({ length: Math.min(5, pagination.total_pages) }, (_, i) => {
                    const pageNum = i + 1;
                    return (
                      <button
                        key={pageNum}
                        onClick={() => setPage(pageNum)}
                        disabled={loading}
                        className={`px-2.5 sm:px-3 py-1.5 text-xs sm:text-sm rounded-lg font-medium transition-colors disabled:opacity-50 disabled:cursor-not-allowed ${
                          pagination.page === pageNum
                            ? 'bg-blue-600 text-white'
                            : 'border border-slate-200 text-slate-700 hover:bg-slate-50'
                        }`}
                      >
                        {pageNum}
                      </button>
                    );
                  })}
                  <button
                    onClick={() => setPage(prev => Math.min(pagination.total_pages, prev + 1))}
                    disabled={!pagination.has_next || loading}
                    className="px-2.5 sm:px-3 py-1.5 text-xs sm:text-sm border border-slate-200 text-slate-700 rounded-lg hover:bg-slate-50 font-medium transition-colors disabled:opacity-50 disabled:cursor-not-allowed"
                  >
                    Next
                  </button>
                </div>
              </div>
            )}
          </>
        )}
      </div>
    </Modal>
  );
};

