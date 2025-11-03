import React from 'react';
import { OrderRow, OrderRowData } from './OrderRow';

export const OrderTable: React.FC<{ rows: OrderRowData[] }> = ({ rows }) => {
  return (
    <div className="rounded-2xl border border-slate-200 bg-white shadow-md">
      <table className="w-full table-fixed">
        <thead>
          <tr className="text-left text-slate-600 text-sm">
            <th className="px-6 py-3 w-40 whitespace-nowrap font-medium">Order #</th>
            <th className="px-6 py-3 w-[220px] whitespace-nowrap font-medium">Customer</th>
            <th className="px-6 py-3 w-[220px] whitespace-nowrap font-medium">Services</th>
            <th className="px-6 py-3 w-28 whitespace-nowrap font-medium">Amount</th>
            <th className="px-6 py-3 w-36 whitespace-nowrap font-medium">Status</th>
            <th className="px-6 py-3 w-[210px] whitespace-nowrap font-medium">Delivery Boy</th>
            <th className="px-6 py-3 w-36 whitespace-nowrap font-medium">Est. Delivery</th>
            <th className="px-6 py-3 w-24 whitespace-nowrap font-medium">Actions</th>
          </tr>
        </thead>
        <tbody>
          {rows.map((r) => (
            <OrderRow key={r.id} row={r} />
          ))}
        </tbody>
      </table>
    </div>
  );
};


