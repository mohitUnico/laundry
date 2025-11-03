import React from 'react';
import {
  BarChart,
  Bar,
  XAxis,
  YAxis,
  ResponsiveContainer,
  Tooltip,
} from 'recharts';
import { ChevronDown } from 'lucide-react';

const data = [
  { name: 'Sun', value: 75000 },
  { name: 'Mon', value: 68000 },
  { name: 'Tue', value: 85000 },
  { name: 'Wed', value: 65000 },
  { name: 'Thu', value: 0 },
  { name: 'Fri', value: 0 },
  { name: 'Sat', value: 0 },
];

export const RevenueChart: React.FC = () => {
  return (
    <div className="bg-white rounded-2xl p-4 sm:p-6 border border-slate-200">
      <div className="flex flex-col sm:flex-row items-start sm:items-center justify-between mb-4 sm:mb-6 gap-3 sm:gap-0">
        <h3 className="text-base sm:text-lg font-semibold text-slate-800">Revenue Trend</h3>
        <div className="relative w-full sm:w-auto">
          <select className="appearance-none bg-white border border-slate-200 rounded-full px-3 sm:px-4 py-1.5 sm:py-2 pr-7 sm:pr-8 text-xs sm:text-sm text-slate-700 focus:outline-none focus:ring-2 focus:ring-blue-500/20 focus:border-blue-500 w-full">
            <option>Last 7 days</option>
            <option>Last 30 days</option>
          </select>
          <ChevronDown
            size={14}
            className="absolute right-2 sm:right-3 top-1/2 -translate-y-1/2 text-slate-400 pointer-events-none"
          />
        </div>
      </div>

      <div className="h-48 sm:h-64 mb-4">
        <ResponsiveContainer width="100%" height="100%">
          <BarChart data={data} barSize={20}>
            <defs>
              <pattern id="diagonalHatch" patternUnits="userSpaceOnUse" width="4" height="4">
                <path d="M0,4 l4,-4 M-2,2 l4,-4 M2,6 l4,-4" stroke="#94a3b8" strokeWidth="1"/>
              </pattern>
            </defs>
            <YAxis
              axisLine={false}
              tickLine={false}
              tick={{ fill: '#64748b', fontSize: 10 }}
              domain={[0, 100000]}
              ticks={[20000, 40000, 60000, 80000, 100000]}
            />
            <XAxis
              dataKey="name"
              axisLine={false}
              tickLine={false}
              tick={{ fill: '#64748b', fontSize: 10 }}
            />
            <Tooltip
              cursor={{ fill: 'rgba(148,163,184,0.15)' }}
              contentStyle={{
                backgroundColor: 'white',
                border: '1px solid #e2e8f0',
                borderRadius: '8px',
                boxShadow: '0 4px 6px rgba(0,0,0,0.1)',
                fontSize: '12px',
              }}
            />
            <Bar dataKey="value" radius={[8, 8, 0, 0]} fill="#2563EB" opacity={0.8} />
          </BarChart>
        </ResponsiveContainer>
      </div>

      <div className="grid grid-cols-3 gap-2 sm:gap-4 pt-4 border-t border-slate-100">
        <div>
          <p className="text-xs sm:text-sm text-slate-600 mb-1">Total Revenue</p>
          <p className="text-base sm:text-lg font-semibold text-blue-600">$20,845</p>
        </div>
        <div>
          <p className="text-xs sm:text-sm text-slate-600 mb-1">Avg. order Value</p>
          <p className="text-base sm:text-lg font-semibold text-blue-600">$54.3</p>
        </div>
        <div>
          <p className="text-xs sm:text-sm text-slate-600 mb-1">Total Orders</p>
          <p className="text-base sm:text-lg font-semibold text-blue-600">237</p>
        </div>
      </div>
    </div>
  );
};


