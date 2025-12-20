import React from 'react';
import { Modal } from '@/components/common';
import { Search, Download } from 'lucide-react';

interface ActiveOrdersModalProps {
  isOpen: boolean;
  onClose: () => void;
}

export const ActiveOrdersModal: React.FC<ActiveOrdersModalProps> = ({ isOpen, onClose }) => {
  const orders = [
    { id: 'ORD-001', customer: 'John Williams', amount: '$49.99', status: 'In Progress', eta: '2:00 PM', staff: 'Marcus Chen' },
    { id: 'ORD-002', customer: 'Emma Davis', amount: '$59.99', status: 'Picked Up', eta: '3:00 PM', staff: 'Adam Richard' },
    { id: 'ORD-003', customer: 'Michal Chen', amount: '$49.99', status: 'In Progress', eta: '2:30 PM', staff: 'Lisa Mennu' },
    { id: 'ORD-004', customer: 'Wednesday Adams', amount: '$30.99', status: 'Out for Delivery', eta: '1:45 PM', staff: 'Aish Bachchan' },
    { id: 'ORD-005', customer: 'Xavier', amount: '$45.99', status: 'In Progress', eta: '2:15 PM', staff: 'Shikkar Dha' },
    { id: 'ORD-006', customer: 'Martin Luther', amount: '$49.99', status: 'Picked Up', eta: '3:30 PM', staff: 'Marcus Chen' },
    { id: 'ORD-007', customer: 'Sarah Connor', amount: '$75.50', status: 'In Progress', eta: '4:00 PM', staff: 'Adam Richard' },
  ];

  return (
    <Modal isOpen={isOpen} onClose={onClose} title="Active Orders" size="xl">
      <div className="space-y-3 sm:space-y-4">
        {/* Search and Export */}
        <div className="flex flex-col sm:flex-row items-stretch sm:items-center gap-2 sm:gap-3">
          <div className="relative flex-1">
            <Search size={16} className="sm:w-[18px] sm:h-[18px] absolute left-2.5 sm:left-3 top-1/2 -translate-y-1/2 text-slate-400" />
            <input
              type="text"
              placeholder="Search orders..."
              className="w-full pl-8 sm:pl-10 pr-3 sm:pr-4 py-2 text-xs sm:text-sm border border-slate-200 rounded-lg sm:rounded-xl focus:outline-none focus:ring-2 focus:ring-blue-500 focus:border-transparent"
            />
          </div>
          <button className="flex items-center justify-center gap-1.5 sm:gap-2 px-3 sm:px-4 py-2 text-xs sm:text-sm border border-slate-200 text-slate-700 rounded-lg sm:rounded-xl hover:bg-slate-50 transition-colors">
            <Download size={16} className="sm:w-[18px] sm:h-[18px]" />
            <span className="font-medium">Export</span>
          </button>
        </div>

        {/* Mobile Card View */}
        <div className="block sm:hidden space-y-2">
          {orders.map((order) => {
            const statusColors: { [key: string]: string } = {
              'In Progress': 'bg-blue-50 text-blue-700 border-blue-200',
              'Picked Up': 'bg-purple-50 text-purple-700 border-purple-200',
              'Out for Delivery': 'bg-emerald-50 text-emerald-700 border-emerald-200',
            };

            return (
              <div key={order.id} className="border border-slate-200 rounded-lg p-3 space-y-2">
                <div className="flex items-start justify-between">
                  <div className="flex-1 min-w-0">
                    <div className="text-sm font-medium text-slate-900">{order.id}</div>
                    <div className="text-xs text-slate-600 mt-0.5">{order.customer}</div>
                  </div>
                  <span className={`inline-flex items-center px-2 py-0.5 rounded-full text-[10px] font-medium border ml-2 flex-shrink-0 ${statusColors[order.status] || 'bg-gray-50 text-gray-700 border-gray-200'}`}>
                    {order.status}
                  </span>
                </div>
                <div className="grid grid-cols-2 gap-2 text-xs pt-1 border-t border-slate-100">
                  <div>
                    <span className="text-slate-500">Amount:</span>
                    <span className="text-slate-900 font-semibold ml-1">{order.amount}</span>
                  </div>
                  <div>
                    <span className="text-slate-500">Staff:</span>
                    <span className="text-slate-700 ml-1 truncate">{order.staff}</span>
                  </div>
                  <div className="col-span-2">
                    <span className="text-slate-500">ETA:</span>
                    <span className="text-slate-600 ml-1">{order.eta}</span>
                  </div>
                </div>
              </div>
            );
          })}
        </div>

        {/* Desktop Table View */}
        <div className="hidden sm:block overflow-x-auto">
          <table className="w-full min-w-[600px]">
            <thead className="bg-slate-50 border-b border-slate-200">
              <tr>
                <th className="px-3 sm:px-4 py-2 sm:py-3 text-left text-xs sm:text-sm font-semibold text-slate-700">Order ID</th>
                <th className="px-3 sm:px-4 py-2 sm:py-3 text-left text-xs sm:text-sm font-semibold text-slate-700">Customer</th>
                <th className="px-3 sm:px-4 py-2 sm:py-3 text-left text-xs sm:text-sm font-semibold text-slate-700">Amount</th>
                <th className="px-3 sm:px-4 py-2 sm:py-3 text-left text-xs sm:text-sm font-semibold text-slate-700">Status</th>
                <th className="px-3 sm:px-4 py-2 sm:py-3 text-left text-xs sm:text-sm font-semibold text-slate-700 hidden md:table-cell">Assigned Staff</th>
                <th className="px-3 sm:px-4 py-2 sm:py-3 text-left text-xs sm:text-sm font-semibold text-slate-700">ETA</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-slate-100">
              {orders.map((order) => {
                const statusColors: { [key: string]: string } = {
                  'In Progress': 'bg-blue-50 text-blue-700 border-blue-200',
                  'Picked Up': 'bg-purple-50 text-purple-700 border-purple-200',
                  'Out for Delivery': 'bg-emerald-50 text-emerald-700 border-emerald-200',
                };

                return (
                  <tr key={order.id} className="hover:bg-slate-50 transition-colors">
                    <td className="px-3 sm:px-4 py-2 sm:py-3">
                      <span className="text-xs sm:text-sm font-medium text-slate-900">{order.id}</span>
                    </td>
                    <td className="px-3 sm:px-4 py-2 sm:py-3">
                      <span className="text-xs sm:text-sm text-slate-700">{order.customer}</span>
                    </td>
                    <td className="px-3 sm:px-4 py-2 sm:py-3">
                      <span className="text-xs sm:text-sm font-semibold text-slate-900">{order.amount}</span>
                    </td>
                    <td className="px-3 sm:px-4 py-2 sm:py-3">
                      <span className={`inline-flex items-center px-2 sm:px-2.5 py-0.5 sm:py-1 rounded-full text-[10px] sm:text-xs font-medium border ${statusColors[order.status] || 'bg-gray-50 text-gray-700 border-gray-200'}`}>
                        {order.status}
                      </span>
                    </td>
                    <td className="px-3 sm:px-4 py-2 sm:py-3 hidden md:table-cell">
                      <span className="text-xs sm:text-sm text-slate-700">{order.staff}</span>
                    </td>
                    <td className="px-3 sm:px-4 py-2 sm:py-3">
                      <span className="text-xs sm:text-sm text-slate-600">{order.eta}</span>
                    </td>
                  </tr>
                );
              })}
            </tbody>
          </table>
        </div>

        {/* Pagination */}
        <div className="flex flex-col sm:flex-row items-stretch sm:items-center justify-between gap-2 sm:gap-0 pt-3 sm:pt-4 border-t border-slate-200">
          <p className="text-xs sm:text-sm text-slate-600 text-center sm:text-left">Showing 7 of 47 active orders</p>
          <div className="flex items-center justify-center gap-1.5 sm:gap-2">
            <button className="px-2.5 sm:px-3 py-1.5 text-xs sm:text-sm border border-slate-200 text-slate-700 rounded-lg hover:bg-slate-50 font-medium transition-colors">
              Previous
            </button>
            <button className="px-2.5 sm:px-3 py-1.5 text-xs sm:text-sm bg-blue-600 text-white rounded-lg font-medium transition-colors">
              1
            </button>
            <button className="px-2.5 sm:px-3 py-1.5 text-xs sm:text-sm border border-slate-200 text-slate-700 rounded-lg hover:bg-slate-50 font-medium transition-colors">
              2
            </button>
            <button className="px-2.5 sm:px-3 py-1.5 text-xs sm:text-sm border border-slate-200 text-slate-700 rounded-lg hover:bg-slate-50 font-medium transition-colors">
              Next
            </button>
          </div>
        </div>
      </div>
    </Modal>
  );
};

