import React from 'react';
import { ArrowUpRight } from 'lucide-react';

interface RecentOrder {
  id: string;
  customer: string;
  amount: string;
  status: 'Pending' | 'In progress' | 'Delivered' | 'Out for delivery';
  time: string;
}

interface RecentOrdersProps {
  onViewAll?: () => void;
}

const orders: RecentOrder[] = [
  { id: 'ORD-2025-001', customer: 'John Williams', amount: '$45.99', status: 'In progress', time: '38 mins ago' },
  { id: 'ORD-2025-021', customer: 'Emma Davis', amount: '$89.50', status: 'In progress', time: '50 mins ago' },
  { id: 'ORD-2025-002', customer: 'Michael Brown', amount: '$32.00', status: 'Delivered', time: '1 hr ago' },
  { id: 'ORD-2025-054', customer: 'Oliver Johnson', amount: '$65.00', status: 'Delivered', time: '1:15 hr ago' },
];

export const RecentOrders: React.FC<RecentOrdersProps> = ({ onViewAll }) => {
  return (
    <div className="bg-white rounded-2xl p-4 sm:p-6 border border-slate-200">
      <div className="flex items-center justify-between mb-4 sm:mb-6">
        <h3 className="text-base sm:text-lg font-semibold text-slate-800">Recent Orders</h3>
        <button
          onClick={onViewAll}
          className={`transition-all ${
            onViewAll 
              ? 'cursor-pointer hover:text-slate-600 hover:scale-110 active:scale-100' 
              : ''
          }`}
          aria-label="View all orders"
        >
          <ArrowUpRight size={16} className="sm:w-5 sm:h-5 text-slate-400" />
        </button>
      </div>

      {/* Desktop Layout */}
      <div className="hidden md:block space-y-3">
        {orders.map((order) => (
          <div
            key={order.id}
            className="flex items-center gap-4 py-3 border-b border-slate-100 last:border-b-0"
          >
            <div className="w-[180px]">
              <p className="font-semibold text-slate-900 mb-0.5 text-sm">{order.id}</p>
              <p className="text-xs text-slate-500">{order.customer}</p>
            </div>
            <div className="flex-1 text-right">
              <p className="font-semibold text-slate-900 text-sm">{order.amount}</p>
            </div>
            <div className="flex items-center justify-center min-w-[120px]">
              <span
                className={`px-2 sm:px-3 py-1 rounded-full text-xs font-medium ${
                  order.status === 'Delivered'
                    ? 'bg-green-50 text-green-700'
                    : 'bg-blue-50 text-blue-700'
                }`}
              >
                {order.status}
              </span>
            </div>
            <div className="text-right min-w-[100px]">
              <p className="text-xs sm:text-sm text-slate-600">{order.time}</p>
            </div>
          </div>
        ))}
      </div>

      {/* Mobile Layout */}
      <div className="block md:hidden space-y-3">
        {orders.map((order) => (
          <div
            key={order.id}
            className="border border-slate-200 rounded-xl p-3 space-y-2"
          >
            <div className="flex items-start justify-between">
              <div>
                <p className="font-semibold text-slate-900 text-sm">{order.id}</p>
                <p className="text-xs text-slate-500">{order.customer}</p>
              </div>
              <p className="font-semibold text-slate-900 text-sm">{order.amount}</p>
            </div>
            <div className="flex items-center justify-between pt-2 border-t border-slate-100">
              <span
                className={`px-2 py-1 rounded-full text-xs font-medium ${
                  order.status === 'Delivered'
                    ? 'bg-green-50 text-green-700'
                    : 'bg-blue-50 text-blue-700'
                }`}
              >
                {order.status}
              </span>
              <p className="text-xs text-slate-600">{order.time}</p>
            </div>
          </div>
        ))}
      </div>
    </div>
  );
};

