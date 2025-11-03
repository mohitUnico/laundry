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
      <td className="px-6 py-4">
        <div className="text-sm font-medium text-slate-900">{row.id}</div>
      </td>
      <td className="px-6 py-4">
        <div className="text-sm text-slate-600">{row.orderId}</div>
      </td>
      <td className="px-6 py-4">
        <div className="text-sm font-medium text-slate-900">{row.customer}</div>
      </td>
      <td className="px-6 py-4">
        <div className="inline-flex items-center gap-2">
          <span className="text-xs px-2 py-1 rounded-md bg-slate-100 text-slate-700 font-medium">
            {row.method}
          </span>
        </div>
      </td>
      <td className="px-6 py-4">
        <div className="text-sm font-semibold text-slate-900 text-right">{row.amount}</div>
      </td>
      <td className="px-6 py-4">
        <span className={`inline-flex items-center px-2.5 py-1 rounded-full text-xs font-medium ${row.statusColor}`}>
          {row.status}
        </span>
      </td>
      <td className="px-6 py-4">
        <div className="text-sm text-slate-600">{row.date}</div>
      </td>
      <td className="px-6 py-4">
        <div className="flex items-center gap-2">
          <button className="p-1.5 rounded-lg hover:bg-slate-200 text-slate-600 hover:text-slate-900 transition-colors">
            <Eye size={16} />
          </button>
          <button className="p-1.5 rounded-lg hover:bg-slate-200 text-slate-600 hover:text-slate-900 transition-colors">
            <MoreVertical size={16} />
          </button>
        </div>
      </td>
    </tr>
  );
};

