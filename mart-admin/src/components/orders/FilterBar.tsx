import React, { useRef } from 'react';
import { CalendarDays, Download, Search, X } from 'lucide-react';

interface FilterBarProps {
  search: string;
  onSearchChange: (v: string) => void;
  status: string;
  onStatusChange: (v: string) => void;
  dateFilter: string | null;
  onDateChange: (date: string | null) => void;
}

export const FilterBar: React.FC<FilterBarProps> = ({ 
  search, 
  onSearchChange, 
  status, 
  onStatusChange,
  dateFilter,
  onDateChange,
}) => {
  const dateInputRef = useRef<HTMLInputElement>(null);

  const handleDateChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    const value = e.target.value;
    if (value) {
      onDateChange(value);
    } else {
      onDateChange(null);
    }
  };

  const clearDateFilter = (e: React.MouseEvent) => {
    e.stopPropagation();
    onDateChange(null);
    // Clear the date input value
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
    <div className="flex flex-col sm:flex-row w-full items-stretch sm:items-center justify-between gap-3 sm:gap-4">
      <div className="relative flex-1 sm:max-w-md">
        <Search size={14} className="sm:w-4 sm:h-4 absolute left-2.5 sm:left-3 top-1/2 -translate-y-1/2 text-slate-400" />
        <input
          type="text"
          value={search}
          onChange={(e) => onSearchChange(e.target.value)}
          placeholder="Search orders..."
          className="w-full rounded-lg sm:rounded-xl border border-slate-200 bg-white py-2 sm:py-2.5 pl-8 sm:pl-9 pr-3 text-xs sm:text-sm text-slate-700 placeholder:text-slate-400 focus:border-slate-300 focus:outline-none"
        />
      </div>
      <div className="flex items-center gap-2 sm:gap-3 flex-wrap">
        <div className="relative inline-flex items-center">
          <label className="relative inline-flex items-center cursor-pointer">
            <input
              ref={dateInputRef}
              type="date"
              value={dateFilter || ''}
              onChange={handleDateChange}
              className="sr-only"
            />
            <div
              onClick={() => {
                // Trigger date picker
                if (dateInputRef.current) {
                  // Try modern showPicker() API first (Chrome/Edge)
                  if ('showPicker' in dateInputRef.current && typeof (dateInputRef.current as any).showPicker === 'function') {
                    try {
                      (dateInputRef.current as any).showPicker();
                    } catch (err) {
                      // Fallback to click if showPicker fails
                      dateInputRef.current.click();
                    }
                  } else {
                    // Fallback for browsers that don't support showPicker
                    dateInputRef.current.click();
                  }
                }
              }}
              className={`inline-flex items-center gap-1.5 sm:gap-2 rounded-lg sm:rounded-xl border bg-white px-2 sm:px-3 py-1.5 sm:py-2 text-xs sm:text-sm text-slate-700 transition-colors cursor-pointer ${
                dateFilter ? 'border-indigo-500 bg-indigo-50' : 'border-slate-200 hover:border-slate-300'
              }`}
            >
              <CalendarDays size={14} className="sm:w-4 sm:h-4 text-slate-500" />
              <span className="hidden sm:inline">{displayDate}</span>
              <span className="sm:hidden text-xs">{new Date(displayDate).toLocaleDateString('en-US', { month: 'short', day: 'numeric' })}</span>
              {dateFilter && (
                <X 
                  size={12} 
                  className="sm:w-3.5 sm:h-3.5 text-slate-400 hover:text-slate-600" 
                  onClick={(e) => {
                    e.stopPropagation();
                    clearDateFilter(e);
                  }}
                />
              )}
            </div>
          </label>
        </div>
        <select
          value={status}
          onChange={(e) => onStatusChange(e.target.value)}
          className="rounded-lg sm:rounded-xl border border-slate-200 bg-white px-2 sm:px-3 py-1.5 sm:py-2 text-xs sm:text-sm text-slate-700 focus:outline-none focus:ring-2 focus:ring-indigo-500 flex-1 sm:flex-none min-w-[100px]"
        >
          <option value="all">All Status</option>
          <option value="pickup">Pending</option>
          <option value="in_process">In Progress</option>
          <option value="out_for_delivery">Out for Delivery</option>
          <option value="delivered">Delivered</option>
          <option value="ready">Ready</option>
        </select>
        <button className="inline-flex items-center gap-1.5 sm:gap-2 rounded-lg sm:rounded-xl border border-slate-200 bg-white px-2 sm:px-3 py-1.5 sm:py-2 text-xs sm:text-sm text-slate-700 hover:border-slate-300 transition-colors">
          <Download size={14} className="sm:w-4 sm:h-4 text-slate-500" />
          <span className="hidden sm:inline">Export</span>
        </button>
      </div>
    </div>
  );
};


