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
    <div className="flex w-full items-center justify-between">
      <div className="relative w-[420px]">
        <Search size={16} className="absolute left-3 top-1/2 -translate-y-1/2 text-slate-400" />
        <input
          type="text"
          value={search}
          onChange={(e) => onSearchChange(e.target.value)}
          placeholder="Search by order number or customer name..."
          className="w-full rounded-xl border border-slate-200 bg-white py-2.5 pl-9 pr-3 text-sm text-slate-700 placeholder:text-slate-400 focus:border-slate-300 focus:outline-none"
        />
      </div>
      <div className="flex items-center gap-3">
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
              className={`inline-flex items-center gap-2 rounded-xl border bg-white px-3 py-2 text-sm text-slate-700 transition-colors cursor-pointer ${
                dateFilter ? 'border-indigo-500 bg-indigo-50' : 'border-slate-200 hover:border-slate-300'
              }`}
            >
              <CalendarDays size={16} className="text-slate-500" />
              <span>{displayDate}</span>
              {dateFilter && (
                <X 
                  size={14} 
                  className="text-slate-400 hover:text-slate-600" 
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
          className="rounded-xl border border-slate-200 bg-white px-3 py-2 text-sm text-slate-700"
        >
          <option value="all">All Status</option>
          <option value="pickup">Pending</option>
          <option value="in_process">In Progress</option>
          <option value="out_for_delivery">Out for Delivery</option>
          <option value="delivered">Delivered</option>
          <option value="ready">Ready</option>
        </select>
        <button className="inline-flex items-center gap-2 rounded-xl border border-slate-200 bg-white px-3 py-2 text-sm text-slate-700 hover:border-slate-300">
          <Download size={16} className="text-slate-500" />
          Export
        </button>
      </div>
    </div>
  );
};


