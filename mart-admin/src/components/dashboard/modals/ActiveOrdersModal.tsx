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
      <div className="space-y-4">
        {/* Search and Export */}
        <div className="flex items-center gap-3">
          <div className="relative flex-1">
            <Search size={18} className="absolute left-3 top-1/2 -translate-y-1/2 text-slate-400" />
            <input
              type="text"
              placeholder="Search by order ID or customer name..."
              className="w-full pl-10 pr-4 py-2 border border-slate-200 rounded-xl focus:outline-none focus:ring-2 focus:ring-blue-500 focus:border-transparent text-sm"
            />
          </div>
          <button className="flex items-center gap-2 px-4 py-2 border border-slate-200 text-slate-700 rounded-xl hover:bg-slate-50 transition-colors">
            <Download size={18} />
            <span className="text-sm font-medium">Export</span>
          </button>
        </div>

        {/* Orders Table */}
        <div className="overflow-x-auto">
          <table className="w-full">
            <thead className="bg-slate-50 border-b border-slate-200">
              <tr>
                <th className="px-4 py-3 text-left text-sm font-semibold text-slate-700">Order ID</th>
                <th className="px-4 py-3 text-left text-sm font-semibold text-slate-700">Customer</th>
                <th className="px-4 py-3 text-left text-sm font-semibold text-slate-700">Amount</th>
                <th className="px-4 py-3 text-left text-sm font-semibold text-slate-700">Status</th>
                <th className="px-4 py-3 text-left text-sm font-semibold text-slate-700">Assigned Staff</th>
                <th className="px-4 py-3 text-left text-sm font-semibold text-slate-700">ETA</th>
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
                    <td className="px-4 py-3">
                      <span className="text-sm font-medium text-slate-900">{order.id}</span>
                    </td>
                    <td className="px-4 py-3">
                      <span className="text-sm text-slate-700">{order.customer}</span>
                    </td>
                    <td className="px-4 py-3">
                      <span className="text-sm font-semibold text-slate-900">{order.amount}</span>
                    </td>
                    <td className="px-4 py-3">
                      <span className={`inline-flex items-center px-2.5 py-1 rounded-full text-xs font-medium border ${statusColors[order.status] || 'bg-gray-50 text-gray-700 border-gray-200'}`}>
                        {order.status}
                      </span>
                    </td>
                    <td className="px-4 py-3">
                      <span className="text-sm text-slate-700">{order.staff}</span>
                    </td>
                    <td className="px-4 py-3">
                      <span className="text-sm text-slate-600">{order.eta}</span>
                    </td>
                  </tr>
                );
              })}
            </tbody>
          </table>
        </div>

        {/* Pagination */}
        <div className="flex items-center justify-between pt-4 border-t border-slate-200">
          <p className="text-sm text-slate-600">Showing 7 of 47 active orders</p>
          <div className="flex items-center gap-2">
            <button className="px-3 py-1.5 border border-slate-200 text-slate-700 rounded-lg hover:bg-slate-50 text-sm font-medium transition-colors">
              Previous
            </button>
            <button className="px-3 py-1.5 bg-blue-600 text-white rounded-lg text-sm font-medium transition-colors">
              1
            </button>
            <button className="px-3 py-1.5 border border-slate-200 text-slate-700 rounded-lg hover:bg-slate-50 text-sm font-medium transition-colors">
              2
            </button>
            <button className="px-3 py-1.5 border border-slate-200 text-slate-700 rounded-lg hover:bg-slate-50 text-sm font-medium transition-colors">
              Next
            </button>
          </div>
        </div>
      </div>
    </Modal>
  );
};

