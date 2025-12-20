import React from 'react';
import { OrderRow, OrderRowData } from './OrderRow';

export const OrderTable: React.FC<{ rows: OrderRowData[] }> = ({ rows }) => {
  return (
    <div className="rounded-xl sm:rounded-2xl border border-slate-200 bg-white shadow-md overflow-hidden">
      {/* Mobile Card View */}
      <div className="block sm:hidden divide-y divide-slate-200">
        {rows.map((r) => (
          <div key={r.id} className="p-3 space-y-2 hover:bg-slate-50 transition-colors">
            <div className="flex items-start justify-between">
              <div className="flex-1 min-w-0">
                <div className="font-semibold text-sm text-slate-900 truncate">{r.id}</div>
                <div className="text-xs sm:text-sm font-medium text-slate-900 mt-0.5">{r.customer}</div>
                <div className="text-[10px] sm:text-xs text-slate-500 mt-0.5 truncate">@ {r.address}</div>
              </div>
              <div className="flex items-center gap-2 ml-2">
                <button className="text-slate-400 hover:text-blue-600 transition-colors" aria-label="View order">
                  <svg className="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M15 12a3 3 0 11-6 0 3 3 0 016 0z" />
                    <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M2.458 12C3.732 7.943 7.523 5 12 5c4.478 0 8.268 2.943 9.542 7-1.274 4.057-5.064 7-9.542 7-4.477 0-8.268-2.943-9.542-7z" />
                  </svg>
                </button>
                <button className="text-slate-400 hover:text-blue-600 transition-colors" aria-label="Edit order">
                  <svg className="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M11 5H6a2 2 0 00-2 2v11a2 2 0 002 2h11a2 2 0 002-2v-5m-1.414-9.414a2 2 0 112.828 2.828L11.828 15H9v-2.828l8.586-8.586z" />
                  </svg>
                </button>
              </div>
            </div>
            <div className="grid grid-cols-2 gap-2 text-xs">
              <div>
                <span className="text-slate-500">Services:</span>
                <span className="text-slate-700 ml-1 truncate block">{r.services}</span>
              </div>
              <div>
                <span className="text-slate-500">Amount:</span>
                <span className="text-slate-900 font-medium ml-1">{r.amount}</span>
              </div>
              <div>
                <span className="text-slate-500">Status:</span>
                <span className={`ml-1 font-medium ${r.status === 'Delivered' ? 'text-emerald-600' : r.status === 'Out for Delivery' ? 'text-amber-600' : r.status === 'In Progress' ? 'text-indigo-600' : r.status === 'Picked Up' ? 'text-blue-600' : 'text-orange-600'}`}>
                  {r.status}
                </span>
              </div>
              <div>
                <span className="text-slate-500">ETA:</span>
                <span className="text-slate-700 ml-1">{r.eta}</span>
              </div>
            </div>
            <div className="pt-1">
              <span className="text-slate-500 text-xs">Delivery:</span>
              {r.deliveryBoy === 'Assign' ? (
                <button type="button" className="text-indigo-600 text-xs font-medium hover:text-indigo-700 hover:underline ml-1">
                  Assign
                </button>
              ) : (
                <span className="text-slate-700 text-xs ml-1">{r.deliveryBoy.name}</span>
              )}
            </div>
          </div>
        ))}
      </div>

      {/* Desktop Table View */}
      <div className="hidden sm:block overflow-x-auto">
        <table className="w-full min-w-[800px]">
          <thead>
            <tr className="text-left text-slate-600 text-xs sm:text-sm bg-slate-50">
              <th className="px-3 sm:px-4 md:px-6 py-2 sm:py-3 min-w-[120px] whitespace-nowrap font-medium">Order #</th>
              <th className="px-3 sm:px-4 md:px-6 py-2 sm:py-3 min-w-[180px] sm:min-w-[220px] whitespace-nowrap font-medium">Customer</th>
              <th className="px-3 sm:px-4 md:px-6 py-2 sm:py-3 min-w-[150px] sm:min-w-[220px] whitespace-nowrap font-medium hidden md:table-cell">Services</th>
              <th className="px-3 sm:px-4 md:px-6 py-2 sm:py-3 min-w-[80px] whitespace-nowrap font-medium">Amount</th>
              <th className="px-3 sm:px-4 md:px-6 py-2 sm:py-3 min-w-[100px] sm:min-w-[120px] whitespace-nowrap font-medium">Status</th>
              <th className="px-3 sm:px-4 md:px-6 py-2 sm:py-3 min-w-[140px] sm:min-w-[180px] whitespace-nowrap font-medium hidden lg:table-cell">Delivery Boy</th>
              <th className="px-3 sm:px-4 md:px-6 py-2 sm:py-3 min-w-[100px] sm:min-w-[120px] whitespace-nowrap font-medium hidden xl:table-cell">Est. Delivery</th>
              <th className="px-3 sm:px-4 md:px-6 py-2 sm:py-3 min-w-[80px] whitespace-nowrap font-medium">Actions</th>
            </tr>
          </thead>
          <tbody>
            {rows.map((r) => (
              <OrderRow key={r.id} row={r} />
            ))}
          </tbody>
        </table>
      </div>
    </div>
  );
};


