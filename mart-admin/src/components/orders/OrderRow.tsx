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

export const OrderRow: React.FC<{ row: OrderRowData }> = ({ row }) => {
  const getInitials = (name: string) => {
    const parts = name.trim().split(' ').filter(Boolean);
    if (parts.length === 0) return '';
    if (parts.length === 1) return parts[0]!.charAt(0).toUpperCase();
    return (parts[0]!.charAt(0) + parts[1]!.charAt(0)).toUpperCase();
  };

  return (
    <tr className="border-b border-slate-200 last:border-b-0">
      <td className="px-6 py-5 font-semibold text-slate-900 w-40">{row.id}</td>
      <td className="px-6 py-5 w-[220px]">
        <div className="text-slate-900 font-medium">{row.customer}</div>
        <div className="text-xs text-slate-500">@ {row.address}</div>
      </td>
      <td className="px-6 py-5 text-slate-500 text-sm w-[220px]">{row.services}</td>
      <td className="px-6 py-5 text-slate-900 w-28">{row.amount}</td>
      <td className={`px-6 py-5 text-sm font-medium w-36 ${statusClasses(row.status)}`}>{row.status}</td>
      <td className="px-6 py-5 w-[210px]">
        {row.deliveryBoy === 'Assign' ? (
          <div className="flex items-center gap-3">
            <div className="flex -space-x-2">
              <div className="h-7 w-7 rounded-full border border-white bg-slate-200" />
              <div className="h-7 w-7 rounded-full border border-white bg-slate-300" />
              <div className="h-7 w-7 rounded-full border border-white bg-slate-400" />
            </div>
            <button type="button" className="text-indigo-600 text-sm font-medium hover:text-indigo-700 hover:underline cursor-pointer">Assign</button>
          </div>
        ) : (
          (() => {
            const d = row.deliveryBoy as Exclude<typeof row.deliveryBoy, 'Assign'>;
            return (
              <div className="flex items-center gap-2">
                {d.avatarUrl ? (
                  <img src={d.avatarUrl} alt={d.name} className="h-7 w-7 rounded-full object-cover" />
                ) : (
                  <div className="h-7 w-7 rounded-full bg-gradient-to-br from-slate-200 to-slate-300 text-slate-700 grid place-items-center text-xs font-semibold">
                    {getInitials(d.name)}
                  </div>
                )}
                <span className="text-slate-700 text-sm">{d.name}</span>
              </div>
            );
          })()
        )}
      </td>
      <td className="px-6 py-5 text-slate-600 text-sm w-36">
        <div className="inline-flex items-center gap-1"><Clock size={14} /> {row.eta}</div>
      </td>
      <td className="px-6 py-5 w-24">
        <div className="flex items-center gap-3 justify-start">
          <button className="text-slate-400 hover:text-blue-600"><Eye size={18} /></button>
          <button className="text-slate-400 hover:text-blue-600"><PencilLine size={18} /></button>
        </div>
      </td>
    </tr>
  );
};


