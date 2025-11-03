import React from 'react';
import { ArrowUpRight, TrendingUp } from 'lucide-react';

interface SummaryCardProps {
  title: string;
  value: string | number;
  growth: string;
  isPrimary?: boolean;
}

export const SummaryCard: React.FC<SummaryCardProps> = ({
  title,
  value,
  growth,
  isPrimary = false,
}) => {
  if (isPrimary) {
    return (
      <div className="bg-gradient-to-r from-blue-900 to-blue-600 rounded-2xl p-4 sm:p-6 text-white relative overflow-hidden">
        <div className="relative z-10">
          <p className="text-xs sm:text-sm text-white/90 mb-1">{title}</p>
          <h3 className="text-2xl sm:text-3xl font-bold mb-2">{value}</h3>
          <div className="flex items-center gap-1 text-xs sm:text-sm text-white/90">
            <TrendingUp size={14} className="sm:w-4 sm:h-4" />
            <span className="truncate">{growth} from last month</span>
          </div>
        </div>
        <div className="absolute top-3 right-3 sm:top-4 sm:right-4 z-10">
          <div className="w-8 h-8 sm:w-10 sm:h-10 rounded-full bg-white/20 flex items-center justify-center">
            <ArrowUpRight size={16} className="sm:w-5 sm:h-5 text-white" />
          </div>
        </div>
      </div>
    );
  }

  return (
    <div className="bg-white rounded-2xl p-4 sm:p-6 border border-slate-200 hover:shadow-md transition-shadow">
      <div className="flex items-start justify-between">
        <div className="flex-1 min-w-0 pr-2">
          <p className="text-xs sm:text-sm text-slate-600 mb-1">{title}</p>
          <h3 className="text-2xl sm:text-3xl font-bold text-slate-900 mb-2">{value}</h3>
          <div className="flex items-center gap-1 text-xs sm:text-sm text-blue-600 font-medium">
            <TrendingUp size={14} className="sm:w-4 sm:h-4 flex-shrink-0" />
            <span className="truncate">{growth}</span>
          </div>
        </div>
        <div className="w-8 h-8 sm:w-10 sm:h-10 rounded-full bg-white border-2 border-blue-100 flex items-center justify-center flex-shrink-0">
          <ArrowUpRight size={16} className="sm:w-5 sm:h-5 text-blue-600" />
        </div>
      </div>
    </div>
  );
};

