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
      return 'text-blue-600';
    case 'In Progress':
      return 'text-indigo-600';
    case 'Pending':
      return 'text-orange-600';
    case 'Out for Delivery':
      return 'text-amber-600';
    case 'Delivered':
      return 'text-emerald-600';
  }
}

export const OrderRow: React.FC<{
  row: OrderRowData;
  onView?: (orderId: string) => void;
  onEdit?: (orderId: string) => void;
}> = ({ row, onView, onEdit }) => {
  const getInitials = (name: string) => {
    const parts = name.trim().split(' ').filter(Boolean);
    if (parts.length === 0) return '';
    if (parts.length === 1) return parts[0]!.charAt(0).toUpperCase();
    return (parts[0]!.charAt(0) + parts[1]!.charAt(0)).toUpperCase();
  };

  return (
    <tr className="border-b border-slate-200 last:border-b-0 hover:bg-slate-50/50 transition-colors">
      <td className="px-3 sm:px-4 md:px-6 py-3 sm:py-4 md:py-5 font-semibold text-xs sm:text-sm text-slate-900">
        <div className="truncate" title={row.id}>
          {row.id}
        </div>
      </td>
      <td className="px-3 sm:px-4 md:px-6 py-3 sm:py-4 md:py-5">
        <div className="text-slate-900 font-medium text-xs sm:text-sm">{row.customer}</div>
        <div className="text-[10px] sm:text-xs text-slate-500 mt-0.5 truncate max-w-[200px]">@ {row.address}</div>
      </td>
      <td className="px-3 sm:px-4 md:px-6 py-3 sm:py-4 md:py-5 text-slate-500 text-xs sm:text-sm hidden md:table-cell">
        <div className="truncate" title={row.services}>
          {row.services}
        </div>
      </td>
      <td className="px-3 sm:px-4 md:px-6 py-3 sm:py-4 md:py-5 text-slate-900 text-xs sm:text-sm font-medium">{row.amount}</td>
      <td className={`px-3 sm:px-4 md:px-6 py-3 sm:py-4 md:py-5 text-xs sm:text-sm font-medium ${statusClasses(row.status)}`}>{row.status}</td>
      <td className="px-3 sm:px-4 md:px-6 py-3 sm:py-4 md:py-5 hidden lg:table-cell">
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
      <td className="px-3 sm:px-4 md:px-6 py-3 sm:py-4 md:py-5 text-slate-600 text-xs sm:text-sm hidden xl:table-cell">
        <div className="inline-flex items-center gap-1"><Clock size={12} className="sm:w-3.5 sm:h-3.5" /> <span>{row.eta}</span></div>
      </td>
      <td className="px-3 sm:px-4 md:px-6 py-3 sm:py-4 md:py-5">
        <div className="flex items-center gap-2 sm:gap-3 justify-start">
          <button
            type="button"
            onClick={() => onView?.(row.id)}
            disabled={!onView}
            className={`transition-colors ${
              onView ? 'text-slate-400 hover:text-blue-600' : 'text-slate-300 cursor-not-allowed'
            }`}
            aria-label="View order"
          >
            <Eye size={16} className="sm:w-[18px] sm:h-[18px]" />
          </button>
          <button
            type="button"
            onClick={() => onEdit?.(row.id)}
            disabled={!onEdit}
            className={`transition-colors ${
              onEdit ? 'text-slate-400 hover:text-blue-600' : 'text-slate-300 cursor-not-allowed'
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


