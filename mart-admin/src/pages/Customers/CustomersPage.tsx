import React, { useMemo, useRef, useState } from 'react';
import { Download, Search, UserRound, CalendarDays, Star, Eye, Mail, X } from 'lucide-react';

type CustomerRow = {
  name: string;
  avatar?: string;
  email: string;
  phone: string;
  address: string;
  orders: number;
  rating: number;
  joined: string;
  joinedDate: string; // ISO date string for filtering
  isActive: boolean;
};

// Sample customers with various dates
const allCustomers: CustomerRow[] = [
  { name: 'Tony Stark', email: 'tonystark@gmail.com', phone: '+91 86549 54695', address: '742 Stark Tower Ave, Manhattan, NY 10001', orders: 49, rating: 4.9, joined: 'Joined Mar, 2024', joinedDate: '2024-03-15', isActive: true },
  { name: 'Thor Odinson', email: 'thorodinson@gmail.com', phone: '+91 86549 45689', address: '7 Bilrost Lane, New Asgard, OK 73044', orders: 43, rating: 4.8, joined: 'Joined Apr, 2024', joinedDate: '2024-04-20', isActive: true },
  { name: 'Natasha', email: 'natasha@gmail.com', phone: '+91 86549 87945', address: '22 Shadow Street, Arlington, VA 22201', orders: 39, rating: 4.9, joined: 'Joined June, 2024', joinedDate: '2024-06-10', isActive: true },
  { name: 'Clint Barton', email: 'clintbarton@gmail.com', phone: '+91 86549 23456', address: '315 Archers Way, Waverly, IA 50677', orders: 37, rating: 4.2, joined: 'Joined July, 2024', joinedDate: '2024-07-05', isActive: true },
  { name: 'Bruce Banner', email: 'brucebanner@gmail.com', phone: '+91 86549 45654', address: '888 Gamma Drive, Berkeley, CA 94704', orders: 32, rating: 4.5, joined: 'Joined Aug, 2024', joinedDate: '2024-08-12', isActive: true },
  { name: 'Peter Parker', email: 'peterparker@gmail.com', phone: '+91 86549 12654', address: '20 Queens Plaza, Queens, NY 11101', orders: 30, rating: 4.8, joined: 'Joined Aug, 2024', joinedDate: '2024-08-25', isActive: true },
  // October 24, 2025 customers for testing
  { name: 'Steve Rogers', email: 'steverogers@gmail.com', phone: '+91 86549 78901', address: '123 Shield Avenue, Brooklyn, NY 11201', orders: 52, rating: 5.0, joined: 'Joined Oct, 2025', joinedDate: '2025-10-24', isActive: true },
  { name: 'Wanda Maximoff', email: 'wandamaximoff@gmail.com', phone: '+91 86549 23478', address: '456 Vision Street, Sokovia, SO 12345', orders: 28, rating: 4.7, joined: 'Joined Oct, 2025', joinedDate: '2025-10-24', isActive: true },
  { name: 'Sam Wilson', email: 'samwilson@gmail.com', phone: '+91 86549 56789', address: '789 Falcon Way, Washington, DC 20001', orders: 45, rating: 4.6, joined: 'Joined Oct, 2025', joinedDate: '2025-10-24', isActive: false },
  { name: 'Bucky Barnes', email: 'buckybarnes@gmail.com', phone: '+91 86549 34567', address: '321 Winter Soldier Lane, Brooklyn, NY 11202', orders: 38, rating: 4.4, joined: 'Joined Oct, 2025', joinedDate: '2025-10-24', isActive: true },
  // November 3, 2025 customers for testing
  { name: 'Carol Danvers', email: 'caroldanvers@gmail.com', phone: '+91 86549 11111', address: '999 Cosmic Drive, Los Angeles, CA 90001', orders: 60, rating: 4.9, joined: 'Joined Nov, 2025', joinedDate: '2025-11-03', isActive: true },
  { name: 'Scott Lang', email: 'scottlang@gmail.com', phone: '+91 86549 22222', address: '777 Ant-Man Street, San Francisco, CA 94102', orders: 41, rating: 4.6, joined: 'Joined Nov, 2025', joinedDate: '2025-11-03', isActive: true },
  { name: 'Hope van Dyne', email: 'hopevandyne@gmail.com', phone: '+91 86549 33333', address: '555 Wasp Avenue, San Francisco, CA 94103', orders: 44, rating: 4.8, joined: 'Joined Nov, 2025', joinedDate: '2025-11-03', isActive: true },
  { name: 'T\'Challa', email: 'tchalla@gmail.com', phone: '+91 86549 44444', address: '333 Wakanda Boulevard, Wakanda, WA 98001', orders: 56, rating: 5.0, joined: 'Joined Nov, 2025', joinedDate: '2025-11-03', isActive: true },
  { name: 'Stephen Strange', email: 'stephenstrange@gmail.com', phone: '+91 86549 55555', address: '177A Bleecker Street, New York, NY 10012', orders: 48, rating: 4.7, joined: 'Joined Nov, 2025', joinedDate: '2025-11-03', isActive: false },
];

// NOTE: Header and Sidebar are provided by the app's MainLayout.

export const CustomersPage: React.FC = () => {
  const [search, setSearch] = useState('');
  const [dateFilter, setDateFilter] = useState<string | null>(null);
  const [statusFilter, setStatusFilter] = useState<string>('all');
  const dateInputRef = useRef<HTMLInputElement>(null);

  // Calculate KPIs dynamically
  const kpis = useMemo(() => {
    const totalCustomers = allCustomers.length;
    const activeCustomers = allCustomers.filter(c => c.isActive).length;
    const totalOrders = allCustomers.reduce((sum, c) => sum + c.orders, 0);
    const avgOrders = totalCustomers > 0 ? Math.round(totalOrders / totalCustomers) : 0;
    
    // Calculate growth percentage (mock calculation - you can make this dynamic based on previous month)
    const thisMonthGrowth = 12.5;

    return {
      totalCustomers,
      activeCustomers,
      avgOrders,
      thisMonthGrowth,
    };
  }, []);

  // Filter customers
  const filteredRows = useMemo(() => {
    const term = search.toLowerCase();
    return allCustomers.filter((customer) => {
      // Search filter - matches customer name, email, phone, or address
      const matchesTerm = !term || 
        customer.name.toLowerCase().includes(term) ||
        customer.email.toLowerCase().includes(term) ||
        customer.phone.includes(term) ||
        customer.address.toLowerCase().includes(term);
      
      // Date filter - matches customers who joined in the selected month/year
      let matchesDate = true;
      if (dateFilter) {
        // Parse the filter date (YYYY-MM-DD format from date input)
        const dateParts = dateFilter.split('-');
        if (dateParts.length === 3) {
          const filterYear = Number(dateParts[0]);
          const filterMonth = Number(dateParts[1]);
          
          if (!isNaN(filterYear) && !isNaN(filterMonth)) {
            // Parse customer joined date
            const customerDateStr = customer.joinedDate; // Format: 'YYYY-MM-DD'
            const customerDateParts = customerDateStr.split('-');
            
            if (customerDateParts.length === 3) {
              const customerYear = Number(customerDateParts[0]);
              const customerMonth = Number(customerDateParts[1]);
              
              if (!isNaN(customerYear) && !isNaN(customerMonth)) {
                // Compare by month and year only (not specific day)
                matchesDate = 
                  customerYear === filterYear &&
                  customerMonth === filterMonth;
              } else {
                matchesDate = false;
              }
            } else {
              matchesDate = false;
            }
          }
        }
      }
      
      // Status filter
      let matchesStatus = true;
      if (statusFilter === 'active') {
        matchesStatus = customer.isActive;
      } else if (statusFilter === 'inactive') {
        matchesStatus = !customer.isActive;
      }
      
      return matchesTerm && matchesDate && matchesStatus;
    });
  }, [search, dateFilter, statusFilter]);

  const handleDateChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    const value = e.target.value;
    if (value) {
      setDateFilter(value);
    } else {
      setDateFilter(null);
    }
  };

  const clearDateFilter = (e: React.MouseEvent) => {
    e.stopPropagation();
    setDateFilter(null);
    if (dateInputRef.current) {
      dateInputRef.current.value = '';
    }
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
    <div className="min-h-screen bg-slate-50">
      <div className="mx-auto max-w-[1200px] px-3 sm:px-4 md:px-6 lg:px-8 py-4 sm:py-5 md:py-6">
        <main className="space-y-4 sm:space-y-5 md:space-y-6">
          <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-3 sm:gap-4">
            <div>
              <h1 className="text-xl sm:text-2xl font-semibold text-slate-900">Customer Management</h1>
              <p className="mt-1 text-xs sm:text-sm text-slate-500">Manage and view all customer information</p>
            </div>
            <button className="inline-flex items-center justify-center gap-2 rounded-lg sm:rounded-xl bg-indigo-600 px-3 sm:px-4 py-2 text-xs sm:text-sm font-medium text-white shadow-md hover:bg-indigo-700 transition-colors w-full sm:w-auto">
              <UserRound size={16} /> <span>Add Customer</span>
            </button>
          </div>

          {/* KPI Cards */}
          <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-3 sm:gap-4 md:gap-5 lg:gap-6">
            <div>
              <div className="rounded-xl sm:rounded-2xl border border-slate-200 bg-white p-4 sm:p-5 md:p-6 shadow-md">
                <div className="flex items-center justify-between text-xs sm:text-sm text-slate-700">Total Customers <span className="text-slate-400"/></div>
                <div className="mt-2 flex items-end justify-between">
                  <div className="text-2xl sm:text-3xl font-bold text-slate-900">{kpis.totalCustomers}</div>
                  <div className="text-xs text-indigo-600 font-medium">+{kpis.thisMonthGrowth}% this month</div>
                </div>
              </div>
            </div>
            <div>
              <div className="rounded-xl sm:rounded-2xl border border-slate-200 bg-white p-4 sm:p-5 md:p-6 shadow-md">
                <div className="flex items-center justify-between text-xs sm:text-sm text-slate-700">Active Customers <span className="h-2 w-2 rounded-full bg-emerald-500"/></div>
                <div className="mt-2 text-2xl sm:text-3xl font-bold text-slate-900">{kpis.activeCustomers}</div>
              </div>
            </div>
            <div>
              <div className="rounded-xl sm:rounded-2xl border border-slate-200 bg-white p-4 sm:p-5 md:p-6 shadow-md">
                <div className="flex items-center justify-between text-xs sm:text-sm text-slate-700">Avg. Orders <span className="text-slate-400"/></div>
                <div className="mt-2 text-2xl sm:text-3xl font-bold text-slate-900">{kpis.avgOrders}</div>
              </div>
            </div>
          </div>

          {/* Toolbar */}
          <div className="rounded-xl sm:rounded-2xl border border-slate-200 bg-white p-3 sm:p-4 shadow-md">
            <div className="flex flex-col sm:flex-row items-stretch sm:items-center justify-between gap-3 sm:gap-4">
              <div className="relative flex-1 sm:max-w-md">
                <Search size={16} className="absolute left-3 top-1/2 -translate-y-1/2 text-slate-400" />
                <input 
                  type="text"
                  value={search}
                  onChange={(e) => setSearch(e.target.value)}
                  className="w-full rounded-lg sm:rounded-xl border border-slate-200 bg-white h-9 sm:h-10 pl-9 pr-3 text-xs sm:text-sm placeholder:text-slate-400 focus:border-slate-300 focus:outline-none" 
                  placeholder="Search customers..."
                />
              </div>
              <div className="flex items-center gap-2 sm:gap-3 flex-wrap">
                <div className="relative inline-flex">
                  {/* Visual button - for display only */}
                  <div
                    className={`inline-flex items-center gap-1.5 sm:gap-2 rounded-lg sm:rounded-xl border bg-white px-2 sm:px-3 py-1.5 sm:py-2 text-xs sm:text-sm text-slate-700 transition-colors pointer-events-none ${
                      dateFilter ? 'border-indigo-500 bg-indigo-50' : 'border-slate-200'
                    }`}
                  >
                    <CalendarDays size={14} className="sm:w-4 sm:h-4 text-slate-500" />
                    <span className="hidden sm:inline">{displayDate}</span>
                    <span className="sm:hidden text-xs">{new Date(displayDate).toLocaleDateString('en-US', { month: 'short', day: 'numeric' })}</span>
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
                  onChange={(e) => setStatusFilter(e.target.value)}
                  className="rounded-lg sm:rounded-xl border border-slate-200 bg-white px-2 sm:px-3 py-1.5 sm:py-2 text-xs sm:text-sm text-slate-700 focus:outline-none focus:ring-2 focus:ring-indigo-500"
                >
                  <option value="all">All Customers</option>
                  <option value="active">Active Customers</option>
                  <option value="inactive">Inactive Customers</option>
                </select>
                <button className="inline-flex items-center gap-1.5 sm:gap-2 rounded-lg sm:rounded-xl border border-slate-200 bg-white px-2 sm:px-3 py-1.5 sm:py-2 text-xs sm:text-sm text-slate-700 hover:bg-slate-50 transition-colors">
                  <Download size={14} className="sm:w-4 sm:h-4 text-slate-500"/> <span className="hidden sm:inline">Export</span>
                </button>
              </div>
            </div>
          </div>

          {/* Mobile Card View */}
          <div className="block sm:hidden space-y-3">
            {filteredRows.length === 0 ? (
              <div className="rounded-xl border border-slate-200 bg-white shadow-sm p-8 text-center">
                <div className="text-slate-400 text-sm">No customers found</div>
                <div className="text-xs text-slate-500 mt-1">Try adjusting your search or filters</div>
              </div>
            ) : (
              filteredRows.map((r) => (
                <div key={r.email} className="rounded-xl border border-slate-200 bg-white shadow-sm p-3 space-y-2 hover:bg-slate-50/50 transition-colors">
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
                      <span className="text-slate-700 font-medium">{r.rating}</span>
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

          {/* Desktop Table View */}
          <div className="hidden sm:block rounded-xl sm:rounded-2xl border border-slate-200 bg-white shadow-md overflow-hidden">
            <div className="overflow-x-auto">
              <table className="w-full min-w-[800px]">
                <thead>
                  <tr className="text-left text-slate-600 text-xs sm:text-sm bg-slate-50">
                    <th className="px-3 sm:px-4 md:px-6 py-2 sm:py-3 min-w-[180px] sm:min-w-[260px]">Customer</th>
                    <th className="px-3 sm:px-4 md:px-6 py-2 sm:py-3 min-w-[180px] sm:min-w-[260px]">Contact</th>
                    <th className="px-3 sm:px-4 md:px-6 py-2 sm:py-3 min-w-[200px] sm:min-w-[300px] hidden md:table-cell">Address</th>
                    <th className="px-3 sm:px-4 md:px-6 py-2 sm:py-3 min-w-[80px]">Orders</th>
                    <th className="px-3 sm:px-4 md:px-6 py-2 sm:py-3 min-w-[80px]">Rating</th>
                    <th className="px-3 sm:px-4 md:px-6 py-2 sm:py-3 min-w-[80px]">Actions</th>
                  </tr>
                </thead>
                <tbody>
                  {filteredRows.length === 0 ? (
                    <tr>
                      <td colSpan={6} className="px-6 py-12 text-center">
                        <div className="text-slate-400 text-sm">No customers found</div>
                        <div className="text-xs text-slate-500 mt-1">Try adjusting your search or filters</div>
                      </td>
                    </tr>
                  ) : (
                    filteredRows.map((r) => (
                      <tr key={r.email} className="border-t border-slate-200 hover:bg-slate-50/60 transition-colors">
                      <td className="px-3 sm:px-4 md:px-6 py-3 sm:py-4">
                        <div className="flex items-center gap-2 sm:gap-3">
                          <div className="h-7 w-7 sm:h-8 sm:w-8 rounded-full bg-slate-300 flex-shrink-0" />
                          <div className="min-w-0">
                            <div className="font-medium text-xs sm:text-sm text-slate-900 truncate">{r.name}</div>
                            <div className="text-[10px] sm:text-xs text-slate-500">{r.joined}</div>
                          </div>
                        </div>
                      </td>
                      <td className="px-3 sm:px-4 md:px-6 py-3 sm:py-4">
                        <div className="text-xs sm:text-sm text-slate-700 truncate">{r.email}</div>
                        <div className="text-[10px] sm:text-xs text-slate-500">{r.phone}</div>
                      </td>
                      <td className="px-3 sm:px-4 md:px-6 py-3 sm:py-4 text-xs sm:text-sm text-slate-600 hidden md:table-cell">
                        <div className="truncate max-w-[300px]">{r.address}</div>
                      </td>
                      <td className="px-3 sm:px-4 md:px-6 py-3 sm:py-4 text-xs sm:text-sm text-slate-700">{r.orders}</td>
                      <td className="px-3 sm:px-4 md:px-6 py-3 sm:py-4">
                        <div className="inline-flex items-center gap-1 text-slate-700 text-xs sm:text-sm">
                          <Star size={12} className="sm:w-3.5 sm:h-3.5 text-amber-400 fill-amber-400"/> {r.rating}
                        </div>
                      </td>
                      <td className="px-3 sm:px-4 md:px-6 py-3 sm:py-4">
                        <div className="flex items-center gap-2 sm:gap-3">
                          <button className="text-slate-400 hover:text-blue-600 transition-colors" aria-label="View customer">
                            <Eye size={16} className="sm:w-[18px] sm:h-[18px]"/>
                          </button>
                          <button className="text-slate-400 hover:text-blue-600 transition-colors" aria-label="Email customer">
                            <Mail size={16} className="sm:w-[18px] sm:h-[18px]"/>
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
    </div>
  );
};
