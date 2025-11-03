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
    <div className="flex w-full items-center justify-between gap-4">
      <div className="relative flex-1 max-w-[420px]">
        <Search size={16} className="absolute left-3 top-1/2 -translate-y-1/2 text-slate-400" />
        <input
          value={search}
          onChange={(e) => onSearchChange(e.target.value)}
          placeholder="Search by transaction ID, order ID or customer name..."
          className="w-full rounded-xl border border-slate-200 bg-white py-2.5 pl-9 pr-3 text-sm text-slate-700 placeholder:text-slate-400 focus:border-slate-300 focus:outline-none"
        />
      </div>
      <div className="flex items-center gap-3">
        <button className="inline-flex items-center gap-2 rounded-xl border border-slate-200 bg-white px-3 py-2 text-sm text-slate-700 hover:border-slate-300">
          <Calendar size={16} className="text-slate-500" />
          Last 30 days
        </button>
        <select
          value={method}
          onChange={(e) => onMethodChange(e.target.value)}
          className="rounded-xl border border-slate-200 bg-white px-3 py-2 text-sm text-slate-700 focus:outline-none focus:border-slate-300"
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
          className="rounded-xl border border-slate-200 bg-white px-3 py-2 text-sm text-slate-700 focus:outline-none focus:border-slate-300"
        >
          <option value="all">All Status</option>
          <option value="completed">Completed</option>
          <option value="pending">Pending</option>
          <option value="failed">Failed</option>
          <option value="refunded">Refunded</option>
        </select>
        <button className="inline-flex items-center gap-2 rounded-xl border border-slate-200 bg-white px-3 py-2 text-sm text-slate-700 hover:border-slate-300">
          <Download size={16} className="text-slate-500" />
          Export
        </button>
      </div>
    </div>
  );
};

