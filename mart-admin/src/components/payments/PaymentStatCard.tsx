import React from 'react';

interface PaymentStatCardProps {
  title: string;
  value: string | number;
  icon?: string;
}

export const PaymentStatCard: React.FC<PaymentStatCardProps> = ({ title, value, icon }) => {
  return (
    <div className="bg-white rounded-2xl border border-slate-100 shadow-sm p-5 flex items-center justify-between min-h-[92px]">
      <div>
        <div className="text-sm text-slate-500 font-medium">{title}</div>
        <div className="text-2xl font-bold text-slate-900 mt-1">{value}</div>
      </div>
      {icon && <div className="text-3xl">{icon}</div>}
    </div>
  );
};

