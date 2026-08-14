import React from 'react';
import { Clock, Eye, PencilLine } from 'lucide-react';

export interface OrderRowData {
  id: string;
  customer: string;
  address: string;
  services: string;
  amount: string;
  status: 'Picked Up' | 'In Progress' | 'Pending' | 'Out for Delivery' | 'Delivered';
  deliveryBoy: { name: string; avatarUrl?: string } | 'Assign';
  eta: string;
}

function statusClasses(status: OrderRowData['status']) {
  switch (status) {
    case 'Picked Up':
      return 'text-blue-700 bg-blue-50 border-blue-200';
    case 'In Progress':
      return 'text-indigo-700 bg-indigo-50 border-indigo-200';
    case 'Pending':
      return 'text-orange-700 bg-orange-50 border-orange-200';
    case 'Out for Delivery':
      return 'text-amber-700 bg-amber-50 border-amber-200';
    case 'Delivered':
      return 'text-emerald-700 bg-emerald-50 border-emerald-200';
  }
}


export const OrderRow: React.FC<{
  row: OrderRowData;
  onView?: (orderId: string) => void;
  onEdit?: (orderId: string) => void;
}> = ({ row, onView, onEdit }) => {
  const formatOrderId = (id: string) => {
    const s = (id || '').trim();
    if (s.length <= 14) return s || '—';
    return `${s.slice(0, 8)}…${s.slice(-4)}`;
  };

  const getInitials = (name: string) => {
    const parts = name.trim().split(' ').filter(Boolean);
    if (parts.length === 0) return '';
    if (parts.length === 1) return parts[0]!.charAt(0).toUpperCase();
    return (parts[0]!.charAt(0) + parts[1]!.charAt(0)).toUpperCase();
  };

  return (
    <tr className="border-b border-slate-200 last:border-b-0 hover:bg-slate-50/50 transition-colors">
      <td className="px-3 sm:px-4 md:px-4 py-3 sm:py-4 md:py-5 font-semibold text-xs sm:text-sm text-slate-900">
        <div className="truncate" title={row.id}>
          {formatOrderId(row.id)}
        </div>
      </td>
      <td className="px-3 sm:px-4 md:px-4 py-3 sm:py-4 md:py-5">
        <div className="min-w-0">
          <div className="text-slate-900 font-medium text-xs sm:text-sm truncate">{row.customer}</div>
          <div className="text-[10px] sm:text-xs text-slate-500 mt-0.5 truncate">@ {row.address}</div>
        </div>
      </td>
      <td className="px-3 sm:px-4 md:px-4 py-3 sm:py-4 md:py-5 text-slate-500 text-xs sm:text-sm hidden lg:table-cell">
        <div className="truncate" title={row.services}>
          {row.services}
        </div>
      </td>
      <td className="px-3 sm:px-4 md:px-4 py-3 sm:py-4 md:py-5 text-slate-900 text-xs sm:text-sm font-semibold tabular-nums text-right whitespace-nowrap">
        {row.amount}
      </td>
      <td className="px-3 sm:px-4 md:px-4 py-3 sm:py-4 md:py-5 text-xs sm:text-sm">
        <span
          className={`inline-flex items-center rounded-full border px-2.5 py-1 font-semibold leading-none whitespace-nowrap ${statusClasses(
            row.status
          )}`}
        >
          {row.status}
        </span>
      </td>
      <td className="px-3 sm:px-4 md:px-4 py-3 sm:py-4 md:py-5 hidden xl:table-cell">
        {row.deliveryBoy === 'Assign' ? (
          <div className="flex items-center gap-2 sm:gap-3">
            <div className="flex -space-x-1.5 sm:-space-x-2">
              <div className="h-6 w-6 sm:h-7 sm:w-7 rounded-full border border-white bg-slate-200" />
              <div className="h-6 w-6 sm:h-7 sm:w-7 rounded-full border border-white bg-slate-300" />
              <div className="h-6 w-6 sm:h-7 sm:w-7 rounded-full border border-white bg-slate-400" />
            </div>
            <button type="button" className="text-indigo-600 text-xs sm:text-sm font-medium hover:text-indigo-700 hover:underline cursor-pointer">Assign</button>
          </div>
        ) : (
          (() => {
            const d = row.deliveryBoy as Exclude<typeof row.deliveryBoy, 'Assign'>;
            return (
              <div className="flex items-center gap-1.5 sm:gap-2">
                {d.avatarUrl ? (
                  <img src={d.avatarUrl} alt={d.name} className="h-6 w-6 sm:h-7 sm:w-7 rounded-full object-cover" />
                ) : (
                  <div className="h-6 w-6 sm:h-7 sm:w-7 rounded-full bg-gradient-to-br from-slate-200 to-slate-300 text-slate-700 grid place-items-center text-[10px] sm:text-xs font-semibold">
                    {getInitials(d.name)}
                  </div>
                )}
                <span className="text-slate-700 text-xs sm:text-sm truncate max-w-[120px]">{d.name}</span>
              </div>
            );
          })()
        )}
      </td>
      <td className="px-3 sm:px-4 md:px-4 py-3 sm:py-4 md:py-5 text-slate-600 text-xs sm:text-sm hidden 2xl:table-cell">
        <div className="inline-flex items-center gap-1"><Clock size={12} className="sm:w-3.5 sm:h-3.5" /> <span>{row.eta}</span></div>
      </td>
      <td className="px-3 sm:px-4 md:px-4 py-3 sm:py-4 md:py-5">
        <div className="flex items-center justify-center gap-2">
          <button
            type="button"
            onClick={() => onView?.(row.id)}
            disabled={!onView}
            className={`inline-flex h-9 w-9 items-center justify-center rounded-lg border border-slate-200 bg-white transition-colors focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-indigo-500/50 ${
              onView
                ? 'text-slate-500 hover:text-blue-700 hover:bg-blue-50 hover:border-blue-200'
                : 'text-slate-300 cursor-not-allowed opacity-60'
            }`}
            aria-label="View order"
          >
            <Eye size={16} className="sm:w-[18px] sm:h-[18px]" />
          </button>
          <button
            type="button"
            onClick={() => onEdit?.(row.id)}
            disabled={!onEdit}
            className={`inline-flex h-9 w-9 items-center justify-center rounded-lg border border-slate-200 bg-white transition-colors focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-indigo-500/50 ${
              onEdit
                ? 'text-slate-500 hover:text-indigo-700 hover:bg-indigo-50 hover:border-indigo-200'
                : 'text-slate-300 cursor-not-allowed opacity-60'
            }`}
            aria-label="Edit order"
          >
            <PencilLine size={16} className="sm:w-[18px] sm:h-[18px]" />
          </button>
        </div>
      </td>
    </tr>
  );
};


