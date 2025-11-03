import React from 'react';

interface NotificationStatCardProps {
  title: string;
  value: string | number;
  sub?: string;
}

export const NotificationStatCard: React.FC<NotificationStatCardProps> = ({ title, value, sub }) => {
  return (
    <div className="bg-white rounded-2xl border border-slate-100 shadow-sm p-5 min-h-[96px]">
      <div className="text-sm text-slate-600 font-medium">{title}</div>
      <div className="text-2xl font-bold text-slate-900 mt-1">{value}</div>
      {sub && <div className="text-[11px] mt-1 text-emerald-600">{sub}</div>}
    </div>
  );
};


