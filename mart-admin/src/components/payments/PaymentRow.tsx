import React from 'react';
import { Eye, MoreVertical } from 'lucide-react';

export interface PaymentRowData {
  id: string;
  orderId: string;
  customer: string;
  method: string;
  amount: string;
  status: string;
  statusColor: string;
  date: string;
}

interface PaymentRowProps {
  row: PaymentRowData;
}

export const PaymentRow: React.FC<PaymentRowProps> = ({ row }) => {
  return (
    <tr className="border-b border-slate-100 hover:bg-slate-50 transition-colors">
      <td className="px-3 sm:px-4 md:px-6 py-3 sm:py-4">
        <div className="text-xs sm:text-sm font-medium text-slate-900">{row.id}</div>
      </td>
      <td className="px-3 sm:px-4 md:px-6 py-3 sm:py-4">
        <div className="text-xs sm:text-sm text-slate-600">{row.orderId}</div>
      </td>
      <td className="px-3 sm:px-4 md:px-6 py-3 sm:py-4">
        <div className="text-xs sm:text-sm font-medium text-slate-900 truncate max-w-[150px]">{row.customer}</div>
      </td>
      <td className="px-3 sm:px-4 md:px-6 py-3 sm:py-4 hidden md:table-cell">
        <div className="inline-flex items-center gap-2">
          <span className="text-[10px] sm:text-xs px-2 py-0.5 sm:py-1 rounded-md bg-slate-100 text-slate-700 font-medium">
            {row.method}
          </span>
        </div>
      </td>
      <td className="px-3 sm:px-4 md:px-6 py-3 sm:py-4">
        <div className="text-xs sm:text-sm font-semibold text-slate-900 text-right">{row.amount}</div>
      </td>
      <td className="px-3 sm:px-4 md:px-6 py-3 sm:py-4">
        <span className={`inline-flex items-center px-2 sm:px-2.5 py-0.5 sm:py-1 rounded-full text-[10px] sm:text-xs font-medium ${row.statusColor}`}>
          {row.status}
        </span>
      </td>
      <td className="px-3 sm:px-4 md:px-6 py-3 sm:py-4 hidden lg:table-cell">
        <div className="text-xs sm:text-sm text-slate-600">{row.date}</div>
      </td>
      <td className="px-3 sm:px-4 md:px-6 py-3 sm:py-4">
        <div className="flex items-center gap-1.5 sm:gap-2">
          <button className="p-1 sm:p-1.5 rounded-lg hover:bg-slate-200 text-slate-600 hover:text-slate-900 transition-colors" aria-label="View transaction">
            <Eye size={14} className="sm:w-4 sm:h-4" />
          </button>
          <button className="p-1 sm:p-1.5 rounded-lg hover:bg-slate-200 text-slate-600 hover:text-slate-900 transition-colors" aria-label="More options">
            <MoreVertical size={14} className="sm:w-4 sm:h-4" />
          </button>
        </div>
      </td>
    </tr>
  );
};

