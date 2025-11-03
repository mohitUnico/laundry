import React from 'react';
import { PaymentRow, PaymentRowData } from './PaymentRow';

export const PaymentTable: React.FC<{ rows: PaymentRowData[] }> = ({ rows }) => {
  return (
    <div className="overflow-x-auto">
      <table className="w-full">
        <thead>
          <tr className="text-left text-slate-600 text-sm border-b border-slate-200">
            <th className="px-6 py-4 whitespace-nowrap font-medium">Transaction ID</th>
            <th className="px-6 py-4 whitespace-nowrap font-medium">Order ID</th>
            <th className="px-6 py-4 whitespace-nowrap font-medium">Customer</th>
            <th className="px-6 py-4 whitespace-nowrap font-medium">Method</th>
            <th className="px-6 py-4 whitespace-nowrap font-medium text-right">Amount</th>
            <th className="px-6 py-4 whitespace-nowrap font-medium">Status</th>
            <th className="px-6 py-4 whitespace-nowrap font-medium">Date</th>
            <th className="px-6 py-4 whitespace-nowrap font-medium">Actions</th>
          </tr>
        </thead>
        <tbody>
          {rows.length === 0 ? (
            <tr>
              <td colSpan={8} className="px-6 py-12 text-center text-slate-500">
                No transactions found
              </td>
            </tr>
          ) : (
            rows.map((row) => (
              <PaymentRow key={row.id} row={row} />
            ))
          )}
        </tbody>
      </table>
    </div>
  );
};

