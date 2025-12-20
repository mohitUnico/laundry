import React from 'react';

interface PaymentStatCardProps {
  title: string;
  value: string | number;
  icon?: string;
}

export const PaymentStatCard: React.FC<PaymentStatCardProps> = ({ title, value, icon }) => {
  return (
    <div className="bg-white rounded-xl sm:rounded-2xl border border-slate-100 shadow-sm p-4 sm:p-5 flex items-center justify-between min-h-[80px] sm:min-h-[92px]">
      <div className="flex-1 min-w-0">
        <div className="text-xs sm:text-sm text-slate-500 font-medium truncate">{title}</div>
        <div className="text-xl sm:text-2xl font-bold text-slate-900 mt-1 truncate">{value}</div>
      </div>
      {icon && <div className="text-2xl sm:text-3xl ml-2 flex-shrink-0">{icon}</div>}
    </div>
  );
};

