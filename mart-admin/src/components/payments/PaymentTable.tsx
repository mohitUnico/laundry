import React from 'react';
import { PaymentRow, PaymentRowData } from './PaymentRow';

export const PaymentTable: React.FC<{ rows: PaymentRowData[] }> = ({ rows }) => {
  return (
    <>
      {/* Mobile Card View */}
      <div className="block sm:hidden space-y-3">
        {rows.length === 0 ? (
          <div className="rounded-xl border border-slate-200 bg-white shadow-sm p-8 text-center">
            <div className="text-slate-400 text-sm">No transactions found</div>
            <div className="text-xs text-slate-500 mt-1">Try adjusting your search or filters</div>
          </div>
        ) : (
          rows.map((row) => (
            <div key={row.id} className="rounded-xl border border-slate-200 bg-white shadow-sm p-3 space-y-2 hover:bg-slate-50/50 transition-colors">
              <div className="flex items-start justify-between">
                <div className="flex-1 min-w-0">
                  <div className="font-semibold text-sm text-slate-900 truncate">{row.id}</div>
                  <div className="text-xs text-slate-600 mt-0.5">{row.orderId}</div>
                </div>
                <div className="flex items-center gap-2 ml-2">
                  <button className="text-slate-400 hover:text-blue-600 transition-colors p-1" aria-label="View transaction">
                    <svg className="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                      <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M15 12a3 3 0 11-6 0 3 3 0 016 0z" />
                      <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M2.458 12C3.732 7.943 7.523 5 12 5c4.478 0 8.268 2.943 9.542 7-1.274 4.057-5.064 7-9.542 7-4.477 0-8.268-2.943-9.542-7z" />
                    </svg>
                  </button>
                  <button className="text-slate-400 hover:text-blue-600 transition-colors p-1" aria-label="More options">
                    <svg className="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                      <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M12 5v.01M12 12v.01M12 19v.01M12 6a1 1 0 110-2 1 1 0 010 2zm0 7a1 1 0 110-2 1 1 0 010 2zm0 7a1 1 0 110-2 1 1 0 010 2z" />
                    </svg>
                  </button>
                </div>
              </div>
              
              <div className="space-y-1.5 pt-1 border-t border-slate-100">
                <div className="flex items-center justify-between text-xs">
                  <span className="text-slate-500">Customer:</span>
                  <span className="text-slate-700 font-medium truncate flex-1 ml-2 text-right">{row.customer}</span>
                </div>
                <div className="flex items-center justify-between text-xs">
                  <span className="text-slate-500">Method:</span>
                  <span className="text-xs px-2 py-0.5 rounded-md bg-slate-100 text-slate-700 font-medium ml-2">
                    {row.method}
                  </span>
                </div>
                <div className="flex items-center justify-between text-xs">
                  <span className="text-slate-500">Date:</span>
                  <span className="text-slate-600 ml-2">{row.date}</span>
                </div>
              </div>

              <div className="flex items-center justify-between pt-1.5 border-t border-slate-100">
                <div className="text-sm">
                  <span className="text-slate-500">Amount:</span>
                  <span className="text-slate-900 font-semibold ml-1">{row.amount}</span>
                </div>
                <span className={`inline-flex items-center px-2 py-0.5 rounded-full text-[10px] font-medium ${row.statusColor}`}>
                  {row.status}
                </span>
              </div>
            </div>
          ))
        )}
      </div>

      {/* Desktop Table View */}
      <div className="hidden sm:block overflow-x-auto">
        <table className="w-full min-w-[800px]">
          <thead>
            <tr className="text-left text-slate-600 text-xs sm:text-sm border-b border-slate-200 bg-slate-50">
              <th className="px-3 sm:px-4 md:px-6 py-2 sm:py-3 whitespace-nowrap font-medium min-w-[140px]">Transaction ID</th>
              <th className="px-3 sm:px-4 md:px-6 py-2 sm:py-3 whitespace-nowrap font-medium min-w-[120px]">Order ID</th>
              <th className="px-3 sm:px-4 md:px-6 py-2 sm:py-3 whitespace-nowrap font-medium min-w-[150px]">Customer</th>
              <th className="px-3 sm:px-4 md:px-6 py-2 sm:py-3 whitespace-nowrap font-medium min-w-[100px] hidden md:table-cell">Method</th>
              <th className="px-3 sm:px-4 md:px-6 py-2 sm:py-3 whitespace-nowrap font-medium text-right min-w-[100px]">Amount</th>
              <th className="px-3 sm:px-4 md:px-6 py-2 sm:py-3 whitespace-nowrap font-medium min-w-[100px]">Status</th>
              <th className="px-3 sm:px-4 md:px-6 py-2 sm:py-3 whitespace-nowrap font-medium min-w-[100px] hidden lg:table-cell">Date</th>
              <th className="px-3 sm:px-4 md:px-6 py-2 sm:py-3 whitespace-nowrap font-medium min-w-[80px]">Actions</th>
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
    </>
  );
};

