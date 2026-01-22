import React, { useCallback, useEffect, useMemo, useRef, useState } from 'react';
import { Download, Search, CalendarDays, Star, Eye, Mail, X, Loader2, Plus, TrendingUp, Award } from 'lucide-react';
import { customersApi, AdminCustomer } from '../../services/api/modules/customersApi';
import { AddCustomerModal } from '@/components/dashboard/modals';
import { ViewCustomerModal, type ViewCustomerModalCustomer } from '@/components/customers/modals/ViewCustomerModal';
import { useNavigate } from 'react-router-dom';

type CustomerRow = {
  customerId: string;
  name: string;
  avatar?: string;
  email: string;
  phone: string;
  address: string;
  orders: number;
  rating: number | null;
  joined: string;
  isActive: boolean;
};

// NOTE: Header and Sidebar are provided by the app's MainLayout.

export const CustomersPage: React.FC = () => {
  const navigate = useNavigate();
  const [search, setSearch] = useState('');
  const [debouncedSearch, setDebouncedSearch] = useState('');
  const [dateFilter, setDateFilter] = useState<string | null>(null);
  const [statusFilter, setStatusFilter] = useState<string>('all');
  const [page, setPage] = useState(1);
  const [limit] = useState(20);
  
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [customers, setCustomers] = useState<AdminCustomer[]>([]);
  const [kpis, setKpis] = useState({
    totalCustomers: 0,
    activeCustomers: 0,
    avgOrders: 0,
    thisMonthGrowth: 0, // Mock value for now
  });
  const [showAddCustomerModal, setShowAddCustomerModal] = useState(false);
  const [isViewCustomerOpen, setIsViewCustomerOpen] = useState(false);
  const [selectedCustomer, setSelectedCustomer] = useState<ViewCustomerModalCustomer | undefined>(undefined);
  // Pagination state (currently not displayed in UI, but available for future use)
  const [, setPagination] = useState({
    page: 1,
    limit: 20,
    total: 0,
    total_pages: 0,
    has_next: false,
    has_prev: false,
  });

  const dateInputRef = useRef<HTMLInputElement>(null);

  // Debounce search input (300ms delay)
  useEffect(() => {
    const timer = setTimeout(() => {
      setDebouncedSearch(search);
      setPage(1); // Reset to first page on search change
    }, 300);

    return () => clearTimeout(timer);
  }, [search]);

  // Convert date filter to ISO date range for backend
  const getDateRange = useCallback((dateStr: string | null) => {
    if (!dateStr) return { from: undefined, to: undefined };
    
    // Parse YYYY-MM-DD format
    const dateParts = dateStr.split('-');
    if (dateParts.length !== 3) return { from: undefined, to: undefined };
    
    const year = Number(dateParts[0]);
    const month = Number(dateParts[1]);
    
    if (isNaN(year) || isNaN(month)) return { from: undefined, to: undefined };
    
    // Create date range for the selected month
    const fromDate = new Date(year, month - 1, 1);
    const toDate = new Date(year, month, 0, 23, 59, 59, 999); // Last day of month
    
    return {
      from: fromDate.toISOString(),
      to: toDate.toISOString(),
    };
  }, []);

  // Fetch customer summary (KPIs)
  const fetchSummary = useCallback(async () => {
    try {
      const dateRange = getDateRange(dateFilter);
      const isActive = statusFilter === 'all' ? undefined : statusFilter === 'active';
      
      const response = await customersApi.getCustomerSummary({
        from: dateRange.from,
        to: dateRange.to,
        isActive,
      });

      if (response.success && response.data) {
        setKpis({
          totalCustomers: response.data.totalCustomers,
          activeCustomers: response.data.activeCustomers,
          avgOrders: Math.round(response.data.averageOrdersPerCustomer),
          thisMonthGrowth: 12.5, // Mock value - can be calculated from backend if needed
        });
      }
    } catch (err) {
      console.error('Failed to fetch customer summary:', err);
      // Don't set error state for summary, just log it
    }
  }, [dateFilter, statusFilter, getDateRange]);

  // Fetch customers list
  const fetchCustomers = useCallback(async () => {
    setLoading(true);
    setError(null);

    try {
      const dateRange = getDateRange(dateFilter);
      const isActive = statusFilter === 'all' ? undefined : statusFilter === 'active';
      
      const response = await customersApi.getCustomers({
        page,
        limit,
        search: debouncedSearch || undefined,
        from: dateRange.from,
        to: dateRange.to,
        isActive,
      });

      if (response.success && response.data) {
        setCustomers(response.data.customers);
        setPagination(response.data.pagination);
      } else {
        setError('Failed to fetch customers');
      }
    } catch (err: any) {
      console.error('Failed to fetch customers:', err);
      
      // Provide more helpful error messages
      let errorMessage = 'Failed to load customers. Please try again.';
      
      if (err?.code === 'ECONNREFUSED' || err?.message?.includes('ECONNREFUSED')) {
        errorMessage = 'Cannot connect to backend server. Please ensure the backend is running on port 5000.';
      } else if (err?.response?.status === 500) {
        errorMessage = 'Server error. Please try again later.';
      } else if (err?.response?.status === 401) {
        errorMessage = 'Authentication required. Please log in again.';
      } else if (err?.response?.data?.message) {
        errorMessage = err.response.data.message;
      } else if (err?.message) {
        errorMessage = err.message;
      }
      
      setError(errorMessage);
      setCustomers([]);
    } finally {
      setLoading(false);
    }
  }, [page, limit, debouncedSearch, dateFilter, statusFilter, getDateRange]);

  // Fetch data on mount and when filters change
  useEffect(() => {
    fetchCustomers();
  }, [fetchCustomers]);

  useEffect(() => {
    fetchSummary();
  }, [fetchSummary]);

  // Format customer joined date
  const formatJoinedDate = useCallback((createdAt: string | null | undefined): string => {
    if (!createdAt) return 'N/A';
    
    try {
      const date = new Date(createdAt);
      const month = date.toLocaleString('default', { month: 'short' });
      const year = date.getFullYear();
      return `Joined ${month}, ${year}`;
    } catch {
      return 'N/A';
    }
  }, []);

  // Map API response to UI format
  const filteredRows = useMemo(() => {
    return customers.map((customer): CustomerRow => {
      return {
        customerId: customer.customerId,
        name: customer.name,
        email: customer.contact.email,
        phone: customer.contact.phone || 'N/A',
        address: customer.primaryAddress?.fullAddress || 'No address',
        orders: customer.totalOrdersCount,
        rating: customer.rating,
        joined: formatJoinedDate(customer.createdAt),
        isActive: true, // Backend doesn't return isActive in current response, defaulting to true
      };
    });
  }, [customers, formatJoinedDate]);

  const openCustomerProfile = useCallback(
    (customerId: string) => {
      const c = customers.find((x) => x.customerId === customerId);
      if (!c) return;
      setSelectedCustomer({
        customerId: c.customerId,
        name: c.name,
        email: c.contact.email,
        phone: c.contact.phone,
        address: c.primaryAddress?.fullAddress || null,
        totalOrders: c.totalOrdersCount,
        rating: c.rating,
        joinedText: formatJoinedDate(c.createdAt),
      });
      setIsViewCustomerOpen(true);
    },
    [customers, formatJoinedDate]
  );

  const closeCustomerProfile = () => {
    setIsViewCustomerOpen(false);
    setSelectedCustomer(undefined);
  };

  const handleViewOrders = (c: ViewCustomerModalCustomer) => {
    const q = encodeURIComponent(c.name);
    navigate(`/orders?search=${q}`);
    closeCustomerProfile();
  };

  const handleDateChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    const value = e.target.value;
    if (value) {
      setDateFilter(value);
      setPage(1); // Reset to first page on date filter change
    } else {
      setDateFilter(null);
      setPage(1);
    }
  };

  const clearDateFilter = (e: React.MouseEvent) => {
    e.stopPropagation();
    setDateFilter(null);
    setPage(1);
    if (dateInputRef.current) {
      dateInputRef.current.value = '';
    }
  };

  const handleStatusFilterChange = (e: React.ChangeEvent<HTMLSelectElement>) => {
    setStatusFilter(e.target.value);
    setPage(1); // Reset to first page on status filter change
  };

  const formatDisplayDate = (date: Date): string => {
    const day = date.getDate().toString().padStart(2, '0');
    const month = date.toLocaleString('default', { month: 'short' });
    const year = date.getFullYear();
    return `${day}-${month}-${year}`;
  };

  const displayDate = dateFilter 
    ? formatDisplayDate(new Date(dateFilter))
    : formatDisplayDate(new Date());

  return (
    <div className="w-full">
      <div className="mx-auto mt-1 sm:mt-2 w-full max-w-[1320px] rounded-2xl border border-slate-200 bg-white p-4 sm:p-6 md:p-7 shadow-sm">
        <main className="space-y-4 sm:space-y-5 md:space-y-6">
          {/* Header */}
          <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-3 sm:gap-4">
            <div>
              <h1 className="text-xl sm:text-2xl font-semibold text-slate-900">Customer Management</h1>
              <p className="mt-1 text-xs sm:text-sm text-slate-500">Manage and view all customer information</p>
            </div>
            <button
              onClick={() => setShowAddCustomerModal(true)}
              className="inline-flex items-center justify-center gap-2 rounded-full bg-indigo-700 px-4 sm:px-5 py-2.5 text-xs sm:text-sm font-medium text-white shadow-sm hover:bg-indigo-600 transition-colors w-full sm:w-auto"
            >
              <Plus size={18} /> <span>Add Customer</span>
            </button>
          </div>

          {/* KPI Cards */}
          <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-3 sm:gap-4 md:gap-5 lg:gap-6">
            <div className="rounded-2xl border border-slate-200 bg-white p-5 shadow-sm">
              <div className="flex items-center justify-between text-sm text-slate-800 font-medium">
                <span>Total Customers</span>
                <TrendingUp className="h-4 w-4 text-indigo-700" />
              </div>
              <div className="mt-2 flex items-end justify-between">
                <div className="text-3xl font-bold text-slate-900">
                  {loading ? <Loader2 className="animate-spin h-6 w-6" /> : kpis.totalCustomers}
                </div>
                <div className="text-xs text-indigo-700 font-medium">+{kpis.thisMonthGrowth}% this month</div>
              </div>
            </div>

            <div className="rounded-2xl border border-slate-200 bg-white p-5 shadow-sm">
              <div className="flex items-center justify-between text-sm text-slate-800 font-medium">
                <span>Active Customers</span>
                <span className="h-2 w-2 rounded-full bg-emerald-500" />
              </div>
              <div className="mt-2 text-3xl font-bold text-slate-900">
                {loading ? <Loader2 className="animate-spin h-6 w-6" /> : kpis.activeCustomers}
              </div>
            </div>

            <div className="rounded-2xl border border-slate-200 bg-white p-5 shadow-sm">
              <div className="flex items-center justify-between text-sm text-slate-800 font-medium">
                <span>Avg. Orders</span>
                <Award className="h-4 w-4 text-indigo-700" />
              </div>
              <div className="mt-2 text-3xl font-bold text-slate-900">
                {loading ? <Loader2 className="animate-spin h-6 w-6" /> : kpis.avgOrders}
              </div>
            </div>
          </div>

          {/* Toolbar */}
          <div className="rounded-2xl border border-slate-200 bg-white p-4 shadow-sm">
            <div className="flex flex-col sm:flex-row items-stretch sm:items-center justify-between gap-3 sm:gap-4">
              <div className="relative flex-1 sm:max-w-md">
                <Search size={16} className="absolute left-3 top-1/2 -translate-y-1/2 text-slate-400" />
                <input 
                  type="text"
                  value={search}
                  onChange={(e) => setSearch(e.target.value)}
                  className="w-full rounded-xl border border-slate-200 bg-white h-10 pl-9 pr-3 text-sm placeholder:text-slate-400 focus:border-slate-300 focus:outline-none" 
                  placeholder="Search by order number or customer name..."
                />
              </div>
              <div className="flex items-center gap-2 sm:gap-3 flex-wrap">
                <div className="relative inline-flex">
                  {/* Visual button - for display only */}
                  <div
                    className={`inline-flex items-center gap-2 rounded-xl border bg-white px-3 py-2 text-sm text-slate-700 transition-colors pointer-events-none ${
                      dateFilter ? 'border-indigo-500 bg-indigo-50' : 'border-slate-200'
                    }`}
                  >
                    <CalendarDays size={14} className="sm:w-4 sm:h-4 text-slate-500" />
                    <span>{displayDate}</span>
                    {dateFilter && (
                      <X size={12} className="sm:w-3.5 sm:h-3.5 text-slate-400" />
                    )}
                  </div>
                  
                  {/* Hidden but interactive date input overlaying the button */}
                  <input
                    ref={dateInputRef}
                    type="date"
                    value={dateFilter || ''}
                    onChange={handleDateChange}
                    className="absolute inset-0 w-full h-full opacity-0 cursor-pointer"
                    style={{
                      position: 'absolute',
                      top: 0,
                      left: 0,
                      width: '100%',
                      height: '100%',
                      opacity: 0,
                      cursor: 'pointer',
                      zIndex: 10,
                      fontSize: '16px', // Prevent zoom on iOS
                      padding: 0,
                      margin: 0,
                      border: 'none',
                      background: 'transparent',
                      WebkitAppearance: 'none',
                      MozAppearance: 'textfield',
                    }}
                    onClick={(e) => {
                      e.stopPropagation();
                      // Ensure the picker opens on click
                      if (dateInputRef.current) {
                        setTimeout(() => {
                          if (dateInputRef.current && 'showPicker' in HTMLInputElement.prototype) {
                            try {
                              (dateInputRef.current as any).showPicker();
                            } catch (err) {
                              // showPicker may fail in some contexts, click should still work
                            }
                          }
                        }, 0);
                      }
                    }}
                    onFocus={() => {
                      // Try to show picker when focused
                      if (dateInputRef.current && 'showPicker' in HTMLInputElement.prototype) {
                        try {
                          (dateInputRef.current as any).showPicker();
                        } catch (err) {
                          // showPicker may fail in some contexts, that's okay
                        }
                      }
                    }}
                    aria-label="Select date to filter customers"
                  />
                  
                  {/* Clear button overlay - only when date is selected */}
                  {dateFilter && (
                    <button
                      type="button"
                      onClick={(e) => {
                        e.stopPropagation();
                        e.preventDefault();
                        clearDateFilter(e);
                      }}
                      className="absolute right-2 top-1/2 -translate-y-1/2 z-20 p-1 hover:bg-slate-100 rounded"
                      aria-label="Clear date filter"
                      style={{ pointerEvents: 'auto' }}
                    >
                      <X size={14} className="text-slate-400 hover:text-slate-600" />
                    </button>
                  )}
                </div>
                <select 
                  value={statusFilter}
                  onChange={handleStatusFilterChange}
                  className="rounded-xl border border-slate-200 bg-white px-3 py-2 text-sm text-slate-700 focus:outline-none focus:ring-2 focus:ring-indigo-500"
                >
                  <option value="all">All Customers</option>
                  <option value="active">Active Customers</option>
                  <option value="inactive">Inactive Customers</option>
                </select>
                <button className="inline-flex items-center gap-2 rounded-xl border border-slate-200 bg-white px-3 py-2 text-sm text-slate-700 hover:bg-slate-50 transition-colors">
                  <Download size={16} className="text-slate-500"/> <span>Export</span>
                </button>
              </div>
            </div>
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

          {/* Mobile Card View */}
          <div className="block sm:hidden space-y-3">
            {loading && filteredRows.length === 0 ? (
              <div className="rounded-xl border border-slate-200 bg-white shadow-sm p-8 text-center">
                <Loader2 className="animate-spin h-8 w-8 mx-auto text-indigo-600" />
                <div className="text-slate-500 text-sm mt-2">Loading customers...</div>
              </div>
            ) : filteredRows.length === 0 ? (
              <div className="rounded-xl border border-slate-200 bg-white shadow-sm p-8 text-center">
                <div className="text-slate-400 text-sm">No customers found</div>
                <div className="text-xs text-slate-500 mt-1">Try adjusting your search or filters</div>
              </div>
            ) : (
              filteredRows.map((r, index) => (
                <div key={`${r.email}-${index}`} className="rounded-xl border border-slate-200 bg-white shadow-sm p-3 space-y-2 hover:bg-slate-50/50 transition-colors">
                <div className="flex items-start justify-between">
                  <div className="flex items-center gap-2.5 flex-1 min-w-0">
                    <div className="h-10 w-10 rounded-full bg-slate-300 flex-shrink-0" />
                    <div className="flex-1 min-w-0">
                      <div className="font-medium text-sm text-slate-900 truncate">{r.name}</div>
                      <div className="text-[10px] text-slate-500 mt-0.5">{r.joined}</div>
                    </div>
                  </div>
                  <div className="flex items-center gap-2 ml-2">
                    <button className="text-slate-400 hover:text-blue-600 transition-colors p-1" aria-label="View customer">
                      <Eye size={16} />
                    </button>
                    <button className="text-slate-400 hover:text-blue-600 transition-colors p-1" aria-label="Email customer">
                      <Mail size={16} />
                    </button>
                  </div>
                </div>
                
                <div className="space-y-1.5 pt-1 border-t border-slate-100">
                  <div className="flex items-center gap-2 text-xs">
                    <span className="text-slate-500 min-w-[60px]">Email:</span>
                    <span className="text-slate-700 truncate flex-1">{r.email}</span>
                  </div>
                  <div className="flex items-center gap-2 text-xs">
                    <span className="text-slate-500 min-w-[60px]">Phone:</span>
                    <span className="text-slate-700">{r.phone}</span>
                  </div>
                  <div className="flex items-center gap-2 text-xs">
                    <span className="text-slate-500 min-w-[60px]">Address:</span>
                    <span className="text-slate-600 truncate flex-1">{r.address}</span>
                  </div>
                </div>

                <div className="flex items-center justify-between pt-1.5 border-t border-slate-100">
                  <div className="flex items-center gap-4">
                    <div className="text-xs">
                      <span className="text-slate-500">Orders:</span>
                      <span className="text-slate-900 font-medium ml-1">{r.orders}</span>
                    </div>
                    <div className="inline-flex items-center gap-1 text-xs">
                      <Star size={12} className="text-amber-400 fill-amber-400"/>
                      <span className="text-slate-700 font-medium">{r.rating ?? 'N/A'}</span>
                    </div>
                  </div>
                  {r.isActive ? (
                    <span className="inline-flex items-center gap-1 px-2 py-0.5 rounded-full bg-emerald-50 text-emerald-700 text-[10px] font-medium">
                      <span className="h-1.5 w-1.5 rounded-full bg-emerald-500"></span>
                      Active
                    </span>
                  ) : (
                    <span className="inline-flex items-center gap-1 px-2 py-0.5 rounded-full bg-slate-100 text-slate-600 text-[10px] font-medium">
                      Inactive
                    </span>
                  )}
                </div>
              </div>
              ))
            )}
          </div>

          {/* Desktop Table View (Figma layout) */}
          <div className="hidden sm:block rounded-2xl border border-slate-200 bg-white shadow-sm overflow-hidden">
            <div className="overflow-x-auto">
              <table className="w-full min-w-[900px]">
                <thead>
                  <tr className="text-left text-slate-900 text-sm bg-white border-b border-slate-200">
                    <th className="px-6 py-4">Customer</th>
                    <th className="px-6 py-4">Contact</th>
                    <th className="px-6 py-4">Address</th>
                    <th className="px-6 py-4 text-center">Total Orders</th>
                    <th className="px-6 py-4 text-center">Rating</th>
                    <th className="px-6 py-4 text-center">Actions</th>
                  </tr>
                </thead>
                <tbody>
                  {loading && filteredRows.length === 0 ? (
                    <tr>
                      <td colSpan={6} className="px-6 py-12 text-center">
                        <Loader2 className="animate-spin h-8 w-8 mx-auto text-indigo-600" />
                        <div className="text-slate-500 text-sm mt-2">Loading customers...</div>
                      </td>
                    </tr>
                  ) : filteredRows.length === 0 ? (
                    <tr>
                      <td colSpan={6} className="px-6 py-12 text-center">
                        <div className="text-slate-400 text-sm">No customers found</div>
                        <div className="text-xs text-slate-500 mt-1">Try adjusting your search or filters</div>
                      </td>
                    </tr>
                  ) : (
                    filteredRows.map((r, index) => (
                      <tr key={`${r.email}-${index}`} className="border-b border-slate-200">
                        <td className="px-6 py-4">
                          <div className="flex items-center gap-3">
                            <div className="h-10 w-10 rounded-full bg-slate-200 overflow-hidden flex-shrink-0" />
                            <div className="min-w-0">
                              <div className="font-medium text-sm text-slate-900 truncate">{r.name}</div>
                              <div className="text-xs text-slate-500">{r.joined}</div>
                            </div>
                          </div>
                        </td>
                        <td className="px-6 py-4">
                          <div className="text-sm text-slate-900 truncate">{r.email}</div>
                          <div className="text-xs text-slate-500">{r.phone}</div>
                        </td>
                        <td className="px-6 py-4">
                          <div className="text-sm text-slate-600 truncate max-w-[360px]">{r.address}</div>
                        </td>
                        <td className="px-6 py-4 text-center text-sm text-slate-900">{r.orders}</td>
                        <td className="px-6 py-4 text-center">
                          <div className="inline-flex items-center gap-1 text-sm text-slate-900">
                            <Star size={14} className="text-amber-400 fill-amber-400" />
                            <span>{r.rating ?? 'N/A'}</span>
                          </div>
                        </td>
                        <td className="px-6 py-4">
                          <div className="flex items-center justify-center gap-4">
                            <button
                              className="text-slate-900 hover:text-indigo-700 transition-colors"
                              aria-label="View customer"
                              onClick={() => openCustomerProfile(r.customerId)}
                            >
                              <Eye size={18} />
                            </button>
                            <button
                              className="text-slate-900 hover:text-indigo-700 transition-colors"
                              aria-label="Email customer"
                              onClick={() => {
                                window.location.href = `mailto:${r.email}`;
                              }}
                            >
                              <Mail size={18} />
                            </button>
                          </div>
                        </td>
                      </tr>
                    ))
                  )}
                </tbody>
              </table>
            </div>
          </div>
        </main>
      </div>

      <ViewCustomerModal
        isOpen={isViewCustomerOpen}
        onClose={closeCustomerProfile}
        customer={selectedCustomer}
        onViewOrders={handleViewOrders}
      />

      <AddCustomerModal
        isOpen={showAddCustomerModal}
        onClose={() => setShowAddCustomerModal(false)}
        onSuccess={() => {
          // Refresh customer list and summary after successful creation
          fetchCustomers();
          fetchSummary();
        }}
      />
    </div>
  );
};
