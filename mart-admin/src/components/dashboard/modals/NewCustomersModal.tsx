import React from 'react';
import { Modal } from '@/components/common';
import { Search, Download, TrendingUp } from 'lucide-react';

interface NewCustomersModalProps {
  isOpen: boolean;
  onClose: () => void;
}

export const NewCustomersModal: React.FC<NewCustomersModalProps> = ({ isOpen, onClose }) => {
  const customers = [
    { name: 'Emma Wilson', joined: 'Today', orders: 2, total: '$89.50', status: 'Active' },
    { name: 'Michael Brown', joined: 'Today', orders: 1, total: '$32.00', status: 'Active' },
    { name: 'Olivia Davis', joined: 'Yesterday', orders: 3, total: '$125.00', status: 'Active' },
    { name: 'James Miller', joined: '2 days ago', orders: 1, total: '$45.99', status: 'Active' },
    { name: 'Sophia Garcia', joined: '2 days ago', orders: 2, total: '$78.50', status: 'Active' },
    { name: 'William Anderson', joined: '3 days ago', orders: 1, total: '$49.99', status: 'Active' },
    { name: 'Isabella Thompson', joined: '3 days ago', orders: 0, total: '$0.00', status: 'New' },
  ];

  return (
    <Modal isOpen={isOpen} onClose={onClose} title="New Customers" size="xl">
      <div className="space-y-4">
        {/* Header Stats */}
        <div className="grid grid-cols-4 gap-4">
          <div className="bg-blue-50 rounded-xl p-4 text-center">
            <p className="text-sm text-slate-600 mb-1">Total New</p>
            <p className="text-2xl font-bold text-blue-600">58</p>
          </div>
          <div className="bg-emerald-50 rounded-xl p-4 text-center">
            <p className="text-sm text-slate-600 mb-1">Active</p>
            <p className="text-2xl font-bold text-emerald-600">52</p>
          </div>
          <div className="bg-orange-50 rounded-xl p-4 text-center">
            <p className="text-sm text-slate-600 mb-1">Avg. Orders</p>
            <p className="text-2xl font-bold text-orange-600">1.8</p>
          </div>
          <div className="bg-purple-50 rounded-xl p-4 text-center">
            <p className="text-sm text-slate-600 mb-1">Growth</p>
            <div className="flex items-center justify-center gap-1">
              <TrendingUp size={20} className="text-purple-600" />
              <p className="text-2xl font-bold text-purple-600">+8.3%</p>
            </div>

          </div>

        </div>

        {/* Search and Export */}
        <div className="flex items-center gap-3">
          <div className="relative flex-1">
            <Search size={18} className="absolute left-3 top-1/2 -translate-y-1/2 text-slate-400" />
            <input
              type="text"
              placeholder="Search by customer name..."
              className="w-full pl-10 pr-4 py-2 border border-slate-200 rounded-xl focus:outline-none focus:ring-2 focus:ring-blue-500 focus:border-transparent text-sm"
            />
          </div>
          <button className="flex items-center gap-2 px-4 py-2 border border-slate-200 text-slate-700 rounded-xl hover:bg-slate-50 transition-colors">
            <Download size={18} />
            <span className="text-sm font-medium">Export</span>
          </button>
        </div>

        {/* Customers List */}
        <div className="overflow-x-auto">
          <table className="w-full">
            <thead className="bg-slate-50 border-b border-slate-200">
              <tr>
                <th className="px-4 py-3 text-left text-sm font-semibold text-slate-700">Customer Name</th>
                <th className="px-4 py-3 text-left text-sm font-semibold text-slate-700">Joined</th>
                <th className="px-4 py-3 text-left text-sm font-semibold text-slate-700">Orders</th>
                <th className="px-4 py-3 text-left text-sm font-semibold text-slate-700">Total Spent</th>
                <th className="px-4 py-3 text-left text-sm font-semibold text-slate-700">Status</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-slate-100">
              {customers.map((customer, index) => (
                <tr key={index} className="hover:bg-slate-50 transition-colors">
                  <td className="px-4 py-3">
                    <div className="flex items-center gap-3">
                      <div className="w-8 h-8 rounded-full bg-blue-100 flex items-center justify-center">
                        <span className="text-sm font-semibold text-blue-600">
                          {customer.name.split(' ').map(n => n[0]).join('')}
                        </span>
                      </div>
                      <span className="text-sm font-medium text-slate-900">{customer.name}</span>
                    </div>
                  </td>
                  <td className="px-4 py-3">
                    <span className="text-sm text-slate-700">{customer.joined}</span>
                  </td>
                  <td className="px-4 py-3">
                    <span className="text-sm font-semibold text-slate-900">{customer.orders}</span>
                  </td>
                  <td className="px-4 py-3">
                    <span className="text-sm font-semibold text-slate-900">{customer.total}</span>
                  </td>
                  <td className="px-4 py-3">
                    <span className={`inline-flex items-center px-2.5 py-1 rounded-full text-xs font-medium ${
                      customer.status === 'Active' 
                        ? 'bg-emerald-50 text-emerald-700 border border-emerald-200' 
                        : 'bg-slate-50 text-slate-700 border border-slate-200'
                    }`}>
                      {customer.status}
                    </span>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>

        {/* Pagination */}
        <div className="flex items-center justify-between pt-4 border-t border-slate-200">
          <p className="text-sm text-slate-600">Showing 7 of 58 new customers</p>
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



