import React from 'react';
import { ArrowUpRight } from 'lucide-react';

interface SummaryCardProps {
  title: string;
  value: number | string;
  onClick?: () => void;
  isSelected?: boolean;
}

export const SummaryCard: React.FC<SummaryCardProps> = ({ title, value, onClick, isSelected = false }) => {
  return (
    <div
      onClick={onClick}
      className={`rounded-2xl border p-6 shadow-md transition-transform duration-150 hover:-translate-y-0.5 ${
        isSelected
          ? 'border-indigo-500 bg-indigo-50 shadow-lg'
          : 'border-slate-200 bg-white'
      } ${
        onClick ? 'cursor-pointer hover:shadow-lg' : ''
      }`}
    >
      <div className="flex items-center justify-between">
        <p className={`text-sm font-medium ${isSelected ? 'text-indigo-700' : 'text-slate-700'}`}>{title}</p>
        <div className={`grid h-8 w-8 place-items-center rounded-full ${
          isSelected ? 'bg-indigo-500 text-white' : 'bg-indigo-50 text-indigo-600'
        }`}>
          <ArrowUpRight size={16} />
        </div>
      </div>
      <div className={`mt-3 text-3xl font-bold ${isSelected ? 'text-indigo-900' : 'text-slate-900'}`}>
        {value}
      </div>
    </div>
  );
};


