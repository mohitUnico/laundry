import React from 'react';
import { Search, Download, Calendar } from 'lucide-react';

interface PaymentFilterBarProps {
  search: string;
  onSearchChange: (v: string) => void;
  status: string;
  onStatusChange: (v: string) => void;
  method: string;
  onMethodChange: (v: string) => void;
}

export const PaymentFilterBar: React.FC<PaymentFilterBarProps> = ({ 
  search, 
  onSearchChange, 
  status, 
  onStatusChange,
  method,
  onMethodChange
}) => {
  return (
    <div className="flex flex-col sm:flex-row w-full items-stretch sm:items-center justify-between gap-3 sm:gap-4">
      <div className="relative flex-1 sm:max-w-md">
        <Search size={14} className="sm:w-4 sm:h-4 absolute left-2.5 sm:left-3 top-1/2 -translate-y-1/2 text-slate-400" />
        <input
          value={search}
          onChange={(e) => onSearchChange(e.target.value)}
          placeholder="Search transactions..."
          className="w-full rounded-lg sm:rounded-xl border border-slate-200 bg-white py-2 sm:py-2.5 pl-8 sm:pl-9 pr-3 text-xs sm:text-sm text-slate-700 placeholder:text-slate-400 focus:border-slate-300 focus:outline-none"
        />
      </div>
      <div className="flex items-center gap-2 sm:gap-3 flex-wrap">
        <button className="inline-flex items-center gap-1.5 sm:gap-2 rounded-lg sm:rounded-xl border border-slate-200 bg-white px-2 sm:px-3 py-1.5 sm:py-2 text-xs sm:text-sm text-slate-700 hover:border-slate-300 transition-colors">
          <Calendar size={14} className="sm:w-4 sm:h-4 text-slate-500" />
          <span className="hidden sm:inline">Last 30 days</span>
          <span className="sm:hidden">30d</span>
        </button>
        <select
          value={method}
          onChange={(e) => onMethodChange(e.target.value)}
          className="rounded-lg sm:rounded-xl border border-slate-200 bg-white px-2 sm:px-3 py-1.5 sm:py-2 text-xs sm:text-sm text-slate-700 focus:outline-none focus:ring-2 focus:ring-indigo-500 flex-1 sm:flex-none min-w-[100px]"
        >
          <option value="all">All Methods</option>
          <option value="card">Card</option>
          <option value="cod">COD</option>
          <option value="upi">UPI</option>
          <option value="wallet">Wallet</option>
        </select>
        <select
          value={status}
          onChange={(e) => onStatusChange(e.target.value)}
          className="rounded-lg sm:rounded-xl border border-slate-200 bg-white px-2 sm:px-3 py-1.5 sm:py-2 text-xs sm:text-sm text-slate-700 focus:outline-none focus:ring-2 focus:ring-indigo-500 flex-1 sm:flex-none min-w-[100px]"
        >
          <option value="all">All Status</option>
          <option value="completed">Completed</option>
          <option value="pending">Pending</option>
          <option value="failed">Failed</option>
          <option value="refunded">Refunded</option>
        </select>
        <button className="inline-flex items-center gap-1.5 sm:gap-2 rounded-lg sm:rounded-xl border border-slate-200 bg-white px-2 sm:px-3 py-1.5 sm:py-2 text-xs sm:text-sm text-slate-700 hover:border-slate-300 transition-colors">
          <Download size={14} className="sm:w-4 sm:h-4 text-slate-500" />
          <span className="hidden sm:inline">Export</span>
        </button>
      </div>
    </div>
  );
};

