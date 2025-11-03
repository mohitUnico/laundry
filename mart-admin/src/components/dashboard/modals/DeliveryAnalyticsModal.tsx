import React from 'react';
import { Modal } from '@/components/common';
import { TrendingUp, TrendingDown, Clock, Target } from 'lucide-react';

interface DeliveryAnalyticsModalProps {
  isOpen: boolean;
  onClose: () => void;
}

export const DeliveryAnalyticsModal: React.FC<DeliveryAnalyticsModalProps> = ({ isOpen, onClose }) => {
  const metrics = [
    { label: 'Today Avg', value: '28 min', change: '+2 min', trend: 'down', color: 'red' },
    { label: 'Week Avg', value: '32 min', change: '-4 min', trend: 'up', color: 'emerald' },
    { label: 'Month Avg', value: '35 min', change: '-7 min', trend: 'up', color: 'emerald' },
  ];

  const recentDeliveries = [
    { order: 'ORD-001', customer: 'John Williams', time: '25 min', status: 'On Time' },
    { order: 'ORD-002', customer: 'Emma Davis', time: '22 min', status: 'On Time' },
    { order: 'ORD-003', customer: 'Michal Chen', time: '30 min', status: 'On Time' },
    { order: 'ORD-004', customer: 'Wednesday Adams', time: '35 min', status: 'Delayed' },
    { order: 'ORD-005', customer: 'Xavier', time: '20 min', status: 'Early' },
    { order: 'ORD-006', customer: 'Martin Luther', time: '28 min', status: 'On Time' },
  ];

  return (
    <Modal isOpen={isOpen} onClose={onClose} title="Delivery Analytics" size="xl">
      <div className="space-y-6">
        {/* Overview Cards */}
        <div className="grid grid-cols-3 gap-4">
          {metrics.map((metric) => (
            <div key={metric.label} className="bg-gradient-to-br from-blue-50 to-blue-100 rounded-xl p-4">
              <div className="flex items-center justify-between mb-2">
                <p className="text-sm font-medium text-slate-700">{metric.label}</p>
                <Clock size={18} className="text-blue-600" />
              </div>
              <p className="text-2xl font-bold text-slate-900 mb-1">{metric.value}</p>
              <div className="flex items-center gap-1">
                {metric.trend === 'up' ? (
                  <TrendingUp size={16} className="text-emerald-600" />
                ) : (
                  <TrendingDown size={16} className="text-red-600" />
                )}
                <span className={`text-sm font-medium ${metric.trend === 'up' ? 'text-emerald-600' : 'text-red-600'}`}>
                  {metric.change}
                </span>
              </div>
            </div>
          ))}
        </div>

        {/* Performance Chart */}
        <div className="bg-gradient-to-br from-purple-50 to-blue-50 rounded-xl p-6">
          <div className="flex items-center justify-between mb-4">
            <h4 className="text-lg font-semibold text-slate-900">Performance Trend</h4>
            <Target size={20} className="text-purple-600" />
          </div>
          <div className="h-48 bg-white/70 rounded-xl flex items-center justify-center border-2 border-dashed border-purple-200">
            <p className="text-slate-500 text-sm">Delivery Time Trend Chart</p>
          </div>
        </div>

        {/* Recent Deliveries */}
        <div>
          <h4 className="text-lg font-semibold text-slate-900 mb-4">Recent Deliveries</h4>
          <div className="overflow-x-auto">
            <table className="w-full">
              <thead className="bg-slate-50 border-b border-slate-200">
                <tr>
                  <th className="px-4 py-3 text-left text-sm font-semibold text-slate-700">Order ID</th>
                  <th className="px-4 py-3 text-left text-sm font-semibold text-slate-700">Customer</th>
                  <th className="px-4 py-3 text-left text-sm font-semibold text-slate-700">Time</th>
                  <th className="px-4 py-3 text-left text-sm font-semibold text-slate-700">Status</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-slate-100">
                {recentDeliveries.map((delivery) => {
                  const statusColors: { [key: string]: string } = {
                    'On Time': 'bg-emerald-50 text-emerald-700 border-emerald-200',
                    'Delayed': 'bg-red-50 text-red-700 border-red-200',
                    'Early': 'bg-blue-50 text-blue-700 border-blue-200',
                  };

                  return (
                    <tr key={delivery.order} className="hover:bg-slate-50 transition-colors">
                      <td className="px-4 py-3">
                        <span className="text-sm font-medium text-slate-900">{delivery.order}</span>
                      </td>
                      <td className="px-4 py-3">
                        <span className="text-sm text-slate-700">{delivery.customer}</span>
                      </td>
                      <td className="px-4 py-3">
                        <span className="text-sm font-semibold text-slate-900">{delivery.time}</span>
                      </td>
                      <td className="px-4 py-3">
                        <span className={`inline-flex items-center px-2.5 py-1 rounded-full text-xs font-medium border ${statusColors[delivery.status] || 'bg-gray-50 text-gray-700 border-gray-200'}`}>
                          {delivery.status}
                        </span>
                      </td>
                    </tr>
                  );
                })}
              </tbody>
            </table>
          </div>
        </div>

        {/* Key Insights */}
        <div className="bg-gradient-to-r from-emerald-50 to-blue-50 rounded-xl p-4 border border-emerald-200">
          <div className="flex items-start gap-3">
            <TrendingUp size={20} className="text-emerald-600 flex-shrink-0 mt-0.5" />
            <div>
              <h5 className="font-semibold text-slate-900 mb-1">Performance Insight</h5>
              <p className="text-sm text-slate-700">
                Average delivery time improved by 7 minutes this month. 92% of deliveries are on-time, 
                showing excellent operational efficiency.
              </p>
            </div>
          </div>
        </div>
      </div>
    </Modal>
  );
};

