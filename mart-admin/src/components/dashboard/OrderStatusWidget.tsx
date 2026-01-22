import React from 'react';
import { ArrowUpRight } from 'lucide-react';

interface StatusItem {
  label: string;
  count: number;
  color: string;
}

interface OrderStatusWidgetProps {
  onStatusClick?: (status: string) => void;
  items?: StatusItem[];
  loading?: boolean;
}

export const OrderStatusWidget: React.FC<OrderStatusWidgetProps> = ({ onStatusClick, items, loading }) => {
  const statuses = items && items.length > 0 ? items : [];

  const handleClick = (label: string) => {
    if (onStatusClick) {
      onStatusClick(label);
    }
  };

  return (
    <div className="bg-white rounded-[24px] p-4 sm:p-6 border border-[#E2E8F0] shadow-[0_1px_2px_rgba(15,23,42,0.06)]">
      <div className="flex items-center justify-between mb-4">
        <h3 className="text-base sm:text-lg font-semibold text-[#0F172A]">Order Status</h3>
        <ArrowUpRight size={16} className="sm:w-5 sm:h-5 text-[#94A3B8]" />
      </div>
      <div className="grid grid-cols-2 gap-2 sm:gap-3">
        {loading
          ? Array.from({ length: 4 }).map((_, idx) => (
              <div
                key={`status-skeleton-${idx}`}
                className="rounded-[16px] border border-[#E2E8F0] px-3 sm:px-4 py-2.5 sm:py-3 bg-white flex items-center justify-between"
              >
                <div className="flex items-center gap-2 min-w-0">
                  <span className="h-2.5 w-2.5 rounded-full bg-slate-200 flex-shrink-0" />
                  <span className="h-3 w-24 bg-slate-200 rounded" />
                </div>
                <span className="h-4 w-8 bg-slate-200 rounded" />
              </div>
            ))
          : statuses.map((status) => (
              <div
                key={status.label}
                onClick={() => handleClick(status.label)}
                className={`rounded-[16px] border border-[#E2E8F0] px-3 sm:px-4 py-2.5 sm:py-3 bg-white flex items-center justify-between transition-all ${
                  onStatusClick
                    ? 'cursor-pointer hover:shadow-[0_8px_30px_rgba(15,23,42,0.10)] hover:border-[#CBD5E1]'
                    : ''
                }`}
              >
                <div className="flex items-center gap-1.5 sm:gap-2 min-w-0">
                  <span
                    className="h-2 w-2 sm:h-2.5 sm:w-2.5 rounded-full flex-shrink-0"
                    style={{ backgroundColor: status.color }}
                  />
                  <span className="text-xs sm:text-sm text-[#0F172A] truncate">{status.label}</span>
                </div>
                <span className="text-base sm:text-lg font-semibold text-[#0F172A] flex-shrink-0 ml-2 tabular-nums">
                  {status.count}
                </span>
              </div>
            ))}
      </div>
      {!loading && statuses.length === 0 ? (
        <p className="mt-3 text-xs sm:text-sm text-[#64748B]">No status data available.</p>
      ) : null}
    </div>
  );
};

