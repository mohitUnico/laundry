import React from 'react';

interface StatsCardProps {
  title: string;
  value: string | number;
  dotColor?: string;
}

export const StatsCard: React.FC<StatsCardProps> = ({ title, value, dotColor }) => {
  return (
    <div className="bg-white rounded-2xl shadow-sm border border-slate-100 p-5">
      <div className="flex items-center justify-between mb-2">
        <div className="text-sm text-slate-500 font-medium">{title}</div>
        {dotColor && <span className="h-2 w-2 rounded-full" style={{ background: dotColor }} />}
      </div>
      <div className="text-2xl font-bold text-slate-900">{value}</div>
    </div>
  );
};


