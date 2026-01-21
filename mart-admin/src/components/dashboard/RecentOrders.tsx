import React from 'react';
import { ArrowUpRight } from 'lucide-react';
import { formatCurrency } from '@/utils/formatters';
import { formatTimeAgo } from '@/utils/formatters';

interface RecentOrder {
  id: string;
  customer: string;
  amount: number;
  status: string;
  timeIso: string;
}

interface RecentOrdersProps {
  onViewAll?: () => void;
  items?: RecentOrder[];
}

export const RecentOrders: React.FC<RecentOrdersProps> = ({ onViewAll, items = [] }) => {
  return (
    <div className="bg-white rounded-2xl p-4 sm:p-6 border border-slate-200">
      <div className="flex items-center justify-between mb-4 sm:mb-6">
        <h3 className="text-base sm:text-lg font-semibold text-slate-800">Recent Orders</h3>
        <button
          onClick={onViewAll}
          className={`transition-all ${
            onViewAll 
              ? 'cursor-pointer hover:text-slate-600 hover:scale-110 active:scale-100' 
              : ''
          }`}
          aria-label="View all orders"
        >
          <ArrowUpRight size={16} className="sm:w-5 sm:h-5 text-slate-400" />
        </button>
      </div>

      {/* Desktop Layout */}
      <div className="hidden md:block space-y-3">
        <div className="flex items-center gap-4 pb-2 border-b border-slate-100">
          <div className="flex-1 min-w-[220px]">
            <p className="text-[11px] font-semibold text-slate-500 uppercase tracking-wide">
              Order / Customer
            </p>
          </div>
          <div className="w-[120px] text-right">
            <p className="text-[11px] font-semibold text-slate-500 uppercase tracking-wide">
              Amount
            </p>
          </div>
          <div className="w-[140px] flex items-center justify-center">
            <p className="text-[11px] font-semibold text-slate-500 uppercase tracking-wide">
              Status
            </p>
          </div>
          <div className="w-[190px] text-right">
            <p className="text-[11px] font-semibold text-slate-500 uppercase tracking-wide">
              Created
            </p>
          </div>
        </div>
        {items.map((order) => (
          <div
            key={order.id}
            className="flex items-center gap-4 py-3 border-b border-slate-100 last:border-b-0"
          >
            <div className="flex-1 min-w-[220px]">
              <p className="font-semibold text-slate-900 mb-0.5 text-sm">{order.id}</p>
              <p className="text-xs text-slate-500">{order.customer}</p>
            </div>
            <div className="w-[120px] text-right">
              <p className="font-semibold text-slate-900 text-sm tabular-nums">
                {formatCurrency(order.amount)}
              </p>
            </div>
            <div className="w-[140px] flex items-center justify-center">
              <span
                className={`px-2 sm:px-3 py-1 rounded-full text-xs font-medium ${
                  order.status.toLowerCase().includes('delivered') || order.status.toLowerCase().includes('closed')
                    ? 'bg-green-50 text-green-700'
                    : 'bg-blue-50 text-blue-700'
                }`}
              >
                {order.status}
              </span>
            </div>
            <div className="w-[190px] text-right">
              <p className="text-xs sm:text-sm text-slate-600">{formatTimeAgo(order.timeIso)}</p>
            </div>
          </div>
        ))}
      </div>

      {/* Mobile Layout */}
      <div className="block md:hidden space-y-3">
        {items.map((order) => (
          <div
            key={order.id}
            className="border border-slate-200 rounded-xl p-3 space-y-2"
          >
            <div className="flex items-start justify-between">
              <div>
                <p className="font-semibold text-slate-900 text-sm">{order.id}</p>
                <p className="text-xs text-slate-500">{order.customer}</p>
              </div>
              <p className="font-semibold text-slate-900 text-sm">{formatCurrency(order.amount)}</p>
            </div>
            <div className="flex items-center justify-between pt-2 border-t border-slate-100">
              <span
                className={`px-2 py-1 rounded-full text-xs font-medium ${
                  order.status.toLowerCase().includes('delivered') || order.status.toLowerCase().includes('closed')
                    ? 'bg-green-50 text-green-700'
                    : 'bg-blue-50 text-blue-700'
                }`}
              >
                {order.status}
              </span>
              <p className="text-xs text-slate-600">{formatTimeAgo(order.timeIso)}</p>
            </div>
          </div>
        ))}
      </div>
    </div>
  );
};

