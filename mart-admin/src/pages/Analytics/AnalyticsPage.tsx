import React from 'react';
import {
  ComposedChart,
  Bar,
  Line,
  XAxis,
  YAxis,
  Tooltip,
  ResponsiveContainer,
  CartesianGrid,
} from 'recharts';

const data = [
  { name: 'Jan', bar: 20, line: 22 },
  { name: 'Feb', bar: 80, line: 82 },
  { name: 'Mar', bar: 45, line: 48 },
  { name: 'Apr', bar: 50, line: 52 },
  { name: 'May', bar: 35, line: 36 },
  { name: 'Jun', bar: 10, line: 12 },
  { name: 'Jul', bar: 25, line: 27 },
  { name: 'Aug', bar: 40, line: 42 },
  { name: 'Sep', bar: 15, line: 16 },
  { name: 'Oct', bar: 22, line: 24 },
  { name: 'Nov', bar: 50, line: 52 },
  { name: 'Dec', bar: 90, line: 92 },
];

const MetricCard: React.FC<{
  title: string;
  value: string | number;
  change: string;
  positive?: boolean;
}> = ({ title, value, change, positive = true }) => {
  return (
    <div className="bg-white rounded-2xl shadow-sm border border-gray-200 p-6">
      <div className="flex items-start justify-between">
        <div className="text-sm font-medium text-slate-600">{title}</div>
        <div className={`text-xs font-semibold ${positive ? 'text-[#16A34A]' : 'text-[#DC2626]'}`}>{change}</div>
      </div>
      <div className="mt-2 text-2xl font-semibold text-[#111827]">
        <span className="text-[#111827]">{typeof value === 'number' ? value : value}</span>
      </div>
      <div className="mt-2 text-xs text-slate-500">Last 30 days</div>
    </div>
  );
};

export const AnalyticsPage: React.FC = () => {
  return (
    <div className="px-8 lg:px-10 py-6 bg-[#F9FAFB] space-y-8">
      {/* Header */}
      <div>
        <h1 className="text-2xl font-bold text-[#111827]">Report & Analytics</h1>
        <p className="text-sm text-slate-500 mt-1">Comprehensive business insights and performance metrics.</p>
      </div>

      {/* Metrics Grid */}
      <div className="grid grid-cols-1 sm:grid-cols-2 xl:grid-cols-4 gap-8">
        <MetricCard title="Total Revenue" value="$47845.00" change="+18%" positive />
        <MetricCard title="Total Orders" value={856} change="+12%" positive />
        <MetricCard title="New Customers" value={147} change="+8.3%" positive />
        <MetricCard title="Avg. Order Value" value="$76.99" change="+5%" positive />
      </div>

      {/* Revenue by Month */}
      <div className="grid grid-cols-1 gap-8">
        <div className="bg-white rounded-2xl shadow-sm border border-gray-200 p-6">
          <div className="flex items-center justify-between mb-4">
            <h2 className="text-sm font-semibold text-[#111827]">Revenue by Month</h2>
            <button className="inline-flex items-center gap-2 text-sm border border-gray-200 rounded-lg px-3 py-1.5 text-slate-700 hover:bg-slate-50">
              Last 7 days
              <svg className="w-4 h-4" viewBox="0 0 20 20" fill="currentColor">
                <path fillRule="evenodd" d="M5.23 7.21a.75.75 0 011.06.02L10 10.94l3.71-3.71a.75.75 0 111.06 1.06l-4.24 4.24a.75.75 0 01-1.06 0L5.25 8.29a.75.75 0 01-.02-1.06z" clipRule="evenodd" />
              </svg>
            </button>
          </div>
          <div className="h-[340px]">
            <ResponsiveContainer width="100%" height="100%">
              <ComposedChart data={data} margin={{ top: 10, right: 10, left: 0, bottom: 0 }}>
                <CartesianGrid stroke="#E5E7EB" vertical={false} />
                <XAxis dataKey="name" tick={{ fill: '#6B7280', fontSize: 12 }} axisLine={{ stroke: '#E5E7EB' }} tickLine={false} />
                <YAxis tick={{ fill: '#6B7280', fontSize: 12 }} axisLine={{ stroke: '#E5E7EB' }} tickLine={false} />
                <Tooltip cursor={{ fill: 'rgba(99,102,241,0.08)' }} contentStyle={{ borderRadius: 12, borderColor: '#E5E7EB' }} />
                <Bar dataKey="bar" radius={[8, 8, 0, 0]} fill="url(#barGradient)" barSize={20} />
                <Line type="monotone" dataKey="line" stroke="#F87171" strokeWidth={3} dot={{ r: 3, fill: '#ffffff', stroke: '#F87171', strokeWidth: 2 }} activeDot={{ r: 4 }} />
                <defs>
                  <linearGradient id="barGradient" x1="0" y1="0" x2="0" y2="1">
                    <stop offset="0%" stopColor="#6366F1" />
                    <stop offset="100%" stopColor="#C7D2FE" />
                  </linearGradient>
                </defs>
              </ComposedChart>
            </ResponsiveContainer>
          </div>
        </div>
      </div>
    </div>
  );
};

export default AnalyticsPage;


