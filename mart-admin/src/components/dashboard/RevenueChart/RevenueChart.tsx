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
import { formatCompactCurrency } from '@/utils/formatters';

type RangeOption = '7d' | '30d';

export type RevenueChartPoint = {
  label: string;
  totalRevenue: number;
  totalOrders: number;
};

interface RevenueChartProps {
  range: RangeOption;
  onRangeChange?: (range: RangeOption) => void;
  points?: RevenueChartPoint[];
  totalRevenue?: number;
  totalOrders?: number;
}

export const RevenueChart: React.FC<RevenueChartProps> = ({
  range,
  onRangeChange,
  points = [],
  totalRevenue = 0,
  totalOrders = 0,
}) => {
  const chartData = points.map((p) => ({
    name: p.label,
    value: p.totalRevenue,
  }));

  const avgOrderValue = totalOrders > 0 ? totalRevenue / totalOrders : 0;

  return (
    <div className="bg-white rounded-[24px] p-4 sm:p-6 border border-[#E2E8F0] shadow-[0_1px_2px_rgba(15,23,42,0.06)]">
      <div className="flex flex-col sm:flex-row items-start sm:items-center justify-between mb-4 sm:mb-6 gap-3 sm:gap-0">
        <h3 className="text-base sm:text-lg font-semibold text-[#0F172A]">Revenue Trend</h3>
        <div className="relative w-full sm:w-auto">
          <select
            value={range}
            onChange={(e) => onRangeChange?.(e.target.value as RangeOption)}
            className="appearance-none bg-white border border-[#E2E8F0] rounded-full px-3 sm:px-4 py-1.5 sm:py-2 pr-7 sm:pr-8 text-xs sm:text-sm text-[#0F172A] focus:outline-none focus:ring-2 focus:ring-[#2F47FF]/15 focus:border-[#2F47FF] w-full"
          >
            <option value="7d">Last 7 days</option>
            <option value="30d">Last 30 days</option>
          </select>
          <ChevronDown
            size={14}
            className="absolute right-2 sm:right-3 top-1/2 -translate-y-1/2 text-[#94A3B8] pointer-events-none"
          />
        </div>
      </div>

      <div className="h-48 sm:h-64 mb-4">
        <ResponsiveContainer width="100%" height="100%">
          <BarChart data={chartData} barSize={20}>
            <defs>
              <pattern id="diagonalHatch" patternUnits="userSpaceOnUse" width="4" height="4">
                <path d="M0,4 l4,-4 M-2,2 l4,-4 M2,6 l4,-4" stroke="#94a3b8" strokeWidth="1"/>
              </pattern>
            </defs>
            <YAxis
              axisLine={false}
              tickLine={false}
              tick={{ fill: '#64748b', fontSize: 10 }}
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
                border: '1px solid #E2E8F0',
                borderRadius: '8px',
                boxShadow: '0 8px 30px rgba(15,23,42,0.10)',
                fontSize: '12px',
              }}
            />
            <Bar dataKey="value" radius={[10, 10, 0, 0]} fill="#2F47FF" opacity={0.85} />
          </BarChart>
        </ResponsiveContainer>
      </div>

      <div className="grid grid-cols-3 gap-2 sm:gap-4 pt-4 border-t border-[#F1F5F9]">
        <div>
          <p className="text-xs sm:text-sm text-[#64748B] mb-1">Total Revenue</p>
          <p className="text-base sm:text-lg font-semibold text-[#2F47FF]">{formatCompactCurrency(totalRevenue)}</p>
        </div>
        <div>
          <p className="text-xs sm:text-sm text-[#64748B] mb-1">Avg. order Value</p>
          <p className="text-base sm:text-lg font-semibold text-[#2F47FF]">{formatCompactCurrency(avgOrderValue)}</p>
        </div>
        <div>
          <p className="text-xs sm:text-sm text-[#64748B] mb-1">Total Orders</p>
          <p className="text-base sm:text-lg font-semibold text-[#2F47FF] tabular-nums">{totalOrders}</p>
        </div>
      </div>
    </div>
  );
};


