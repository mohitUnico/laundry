import React, { useState, useEffect, useCallback } from 'react';
import { Modal } from '@/components/common';
import { Search, Download, TrendingUp, Loader2 } from 'lucide-react';
import { adminManagementApi, AdminCustomersListItem } from '@/services/api/modules/adminManagementApi';
import { formatCurrency } from '@/utils/formatters';
import { formatRelativeDate } from '@/utils/formatters/dateFormatter';

interface NewCustomersModalProps {
  isOpen: boolean;
  onClose: () => void;
}

export const NewCustomersModal: React.FC<NewCustomersModalProps> = ({ isOpen, onClose }) => {
  const [loading, setLoading] = useState(false);
  const [kpisLoading, setKpisLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [customers, setCustomers] = useState<AdminCustomersListItem[]>([]);
  const [search, setSearch] = useState('');
  const [debouncedSearch, setDebouncedSearch] = useState('');
  const [page, setPage] = useState(1);
  const [kpis, setKpis] = useState({
    totalCustomers: 0,
    activeCustomers: 0,
    averageOrdersPerCustomer: 0,
    growth: 0,
  });
  const [pagination, setPagination] = useState({
    page: 1,
    limit: 20,
    total: 0,
    total_pages: 0,
    has_next: false,
    has_prev: false,
  });

  // Calculate date range for last 30 days
  const getDateRange = useCallback(() => {
    const to = new Date();
    const from = new Date();
    from.setDate(from.getDate() - 30);
    return {
      from: from.toISOString(),
      to: to.toISOString(),
    };
  }, []);

  // Debounce search input (300ms delay)
  useEffect(() => {
    const timer = setTimeout(() => {
      setDebouncedSearch(search);
      setPage(1); // Reset to first page on search change
    }, 300);

    return () => clearTimeout(timer);
  }, [search]);

  // Fetch customer summary (KPIs)
  const fetchSummary = useCallback(async () => {
    if (!isOpen) return;
    
    setKpisLoading(true);
    try {
      const dateRange = getDateRange();
      const response = await adminManagementApi.getAdminCustomersSummary({
        from: dateRange.from,
        to: dateRange.to,
      });

      if (response.success && response.data) {
        setKpis({
          totalCustomers: response.data.totalCustomers,
          activeCustomers: response.data.activeCustomers,
          averageOrdersPerCustomer: response.data.averageOrdersPerCustomer,
          growth: 8.3, // Mock value - can be calculated from backend if needed
        });
      }
    } catch (err) {
      console.error('Failed to fetch customer summary:', err);
      // Don't set error state for summary, just log it
    } finally {
      setKpisLoading(false);
    }
  }, [isOpen, getDateRange]);

  // Fetch customers list
  const fetchCustomers = useCallback(async () => {
    if (!isOpen) return;
    
    setLoading(true);
    setError(null);

    try {
      const dateRange = getDateRange();
      const response = await adminManagementApi.getAdminCustomers({
        from: dateRange.from,
        to: dateRange.to,
        search: debouncedSearch || undefined,
        page,
        limit: 20,
      });

      if (response.success && response.data) {
        setCustomers(response.data.customers);
        setPagination(response.data.pagination);
      } else {
        setError('Failed to fetch customers');
      }
    } catch (err: any) {
      console.error('Failed to fetch customers:', err);
      const errorMessage = err?.response?.data?.message || 'Failed to load customers. Please try again.';
      setError(errorMessage);
      setCustomers([]);
    } finally {
      setLoading(false);
    }
  }, [isOpen, debouncedSearch, page, getDateRange]);

  useEffect(() => {
    fetchSummary();
  }, [fetchSummary]);

  useEffect(() => {
    fetchCustomers();
  }, [fetchCustomers]);

  return (
    <Modal isOpen={isOpen} onClose={onClose} title="New Customers" size="xl">
      <div className="space-y-4">
        {/* Header Stats */}
        <div className="grid grid-cols-4 gap-4">
          <div className="bg-blue-50 rounded-xl p-4 text-center">
            <p className="text-sm text-slate-600 mb-1">Total New</p>
            {kpisLoading ? (
              <Loader2 className="animate-spin h-6 w-6 mx-auto text-blue-600" />
            ) : (
              <p className="text-2xl font-bold text-blue-600">{kpis.totalCustomers}</p>
            )}
          </div>
          <div className="bg-emerald-50 rounded-xl p-4 text-center">
            <p className="text-sm text-slate-600 mb-1">Active</p>
            {kpisLoading ? (
              <Loader2 className="animate-spin h-6 w-6 mx-auto text-emerald-600" />
            ) : (
              <p className="text-2xl font-bold text-emerald-600">{kpis.activeCustomers}</p>
            )}
          </div>
          <div className="bg-orange-50 rounded-xl p-4 text-center">
            <p className="text-sm text-slate-600 mb-1">Avg. Orders</p>
            {kpisLoading ? (
              <Loader2 className="animate-spin h-6 w-6 mx-auto text-orange-600" />
            ) : (
              <p className="text-2xl font-bold text-orange-600">{kpis.averageOrdersPerCustomer.toFixed(1)}</p>
            )}
          </div>
          <div className="bg-purple-50 rounded-xl p-4 text-center">
            <p className="text-sm text-slate-600 mb-1">Growth</p>
            <div className="flex items-center justify-center gap-1">
              <TrendingUp size={20} className="text-purple-600" />
              {kpisLoading ? (
                <Loader2 className="animate-spin h-6 w-6 text-purple-600" />
              ) : (
                <p className="text-2xl font-bold text-purple-600">+{kpis.growth.toFixed(1)}%</p>
              )}
            </div>
          </div>
        </div>

        {/* Search and Export */}
        <div className="flex items-center gap-3">
          <div className="relative flex-1">
            <Search size={18} className="absolute left-3 top-1/2 -translate-y-1/2 text-slate-400" />
            <input
              type="text"
              placeholder="Search by customer name..."
              value={search}
              onChange={(e) => setSearch(e.target.value)}
              className="w-full pl-10 pr-4 py-2 border border-slate-200 rounded-xl focus:outline-none focus:ring-2 focus:ring-blue-500 focus:border-transparent text-sm"
            />
          </div>
          <button className="flex items-center gap-2 px-4 py-2 border border-slate-200 text-slate-700 rounded-xl hover:bg-slate-50 transition-colors">
            <Download size={18} />
            <span className="text-sm font-medium">Export</span>
          </button>
        </div>

        {/* Error Message */}
        {error && (
          <div className="rounded-xl border border-red-200 bg-red-50 p-4 text-center">
            <div className="text-red-600 text-sm font-medium">{error}</div>
            <button
              onClick={() => fetchCustomers()}
              className="mt-2 text-xs text-red-600 underline hover:text-red-700"
            >
              Try again
            </button>
          </div>
        )}

        {/* Loading State */}
        {loading && customers.length === 0 && (
          <div className="flex items-center justify-center py-12">
            <Loader2 className="animate-spin h-8 w-8 text-blue-600" />
          </div>
        )}

        {/* Customers List */}
        {!loading && !error && (
          <>
            <div className="overflow-x-auto">
              <table className="w-full">
                <thead className="bg-slate-50 border-b border-slate-200">
                  <tr>
                    <th className="px-4 py-3 text-left text-sm font-semibold text-slate-700">Customer Name</th>
                    <th className="px-4 py-3 text-left text-sm font-semibold text-slate-700">Joined</th>
                    <th className="px-4 py-3 text-left text-sm font-semibold text-slate-700">Orders</th>
                    <th className="px-4 py-3 text-left text-sm font-semibold text-slate-700">Total Spent</th>
                    <th className="px-4 py-3 text-left text-sm font-semibold text-slate-700">Status</th>
                  </tr>
                </thead>
                <tbody className="divide-y divide-slate-100">
                  {customers.length === 0 ? (
                    <tr>
                      <td colSpan={5} className="px-6 py-12 text-center">
                        <p className="text-slate-500 text-sm">No new customers found</p>
                      </td>
                    </tr>
                  ) : (
                    customers.map((customer) => {
                      // Calculate total spent from orders (mock for now, backend may provide this)
                      const totalSpent = 0; // Can be calculated from customer orders if available
                      const isActive = customer.totalOrdersCount > 0;
                      
                      return (
                        <tr key={customer.customerId} className="hover:bg-slate-50 transition-colors">
                          <td className="px-4 py-3">
                            <div className="flex items-center gap-3">
                              <div className="w-8 h-8 rounded-full bg-blue-100 flex items-center justify-center">
                                <span className="text-sm font-semibold text-blue-600">
                                  {customer.name.split(' ').map(n => n[0]).join('').substring(0, 2).toUpperCase()}
                                </span>
                              </div>
                              <span className="text-sm font-medium text-slate-900">{customer.name}</span>
                            </div>
                          </td>
                          <td className="px-4 py-3">
                            <span className="text-sm text-slate-700">
                              {formatRelativeDate((customer as any).createdAt || (customer as any).created_at || null)}
                            </span>
                          </td>
                          <td className="px-4 py-3">
                            <span className="text-sm font-semibold text-slate-900">{customer.totalOrdersCount}</span>
                          </td>
                          <td className="px-4 py-3">
                            <span className="text-sm font-semibold text-slate-900">{formatCurrency(totalSpent)}</span>
                          </td>
                          <td className="px-4 py-3">
                            <span className={`inline-flex items-center px-2.5 py-1 rounded-full text-xs font-medium ${
                              isActive 
                                ? 'bg-emerald-50 text-emerald-700 border border-emerald-200' 
                                : 'bg-slate-50 text-slate-700 border border-slate-200'
                            }`}>
                              {isActive ? 'Active' : 'New'}
                            </span>
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
              <div className="flex items-center justify-between pt-4 border-t border-slate-200">
                <p className="text-sm text-slate-600">
                  Showing {((pagination.page - 1) * pagination.limit) + 1} to {Math.min(pagination.page * pagination.limit, pagination.total)} of {pagination.total} new customers
                </p>
                <div className="flex items-center gap-2">
                  <button
                    onClick={() => setPage(prev => Math.max(1, prev - 1))}
                    disabled={!pagination.has_prev || loading}
                    className="px-3 py-1.5 border border-slate-200 text-slate-700 rounded-lg hover:bg-slate-50 text-sm font-medium transition-colors disabled:opacity-50 disabled:cursor-not-allowed"
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
                        className={`px-3 py-1.5 rounded-lg text-sm font-medium transition-colors disabled:opacity-50 disabled:cursor-not-allowed ${
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
                    className="px-3 py-1.5 border border-slate-200 text-slate-700 rounded-lg hover:bg-slate-50 text-sm font-medium transition-colors disabled:opacity-50 disabled:cursor-not-allowed"
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



