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
      <div className="bg-gradient-to-r from-[#1F35FF] to-[#2F47FF] rounded-[24px] p-4 sm:p-6 text-white relative overflow-hidden shadow-[0_10px_30px_rgba(47,71,255,0.18)]">
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
    <div className="bg-white rounded-[24px] p-4 sm:p-6 border border-[#E2E8F0] shadow-[0_1px_2px_rgba(15,23,42,0.06)] hover:shadow-[0_8px_30px_rgba(15,23,42,0.10)] transition-shadow">
      <div className="flex items-start justify-between">
        <div className="flex-1 min-w-0 pr-2">
          <p className="text-xs sm:text-sm text-[#64748B] mb-1">{title}</p>
          <h3 className="text-2xl sm:text-3xl font-bold text-[#0F172A] mb-2">{value}</h3>
          <div className="flex items-center gap-1 text-xs sm:text-sm text-[#2F47FF] font-medium">
            <TrendingUp size={14} className="sm:w-4 sm:h-4 flex-shrink-0" />
            <span className="truncate">{growth}</span>
          </div>
        </div>
        <div className="w-8 h-8 sm:w-10 sm:h-10 rounded-full bg-white border border-[#E2E8F0] flex items-center justify-center flex-shrink-0">
          <ArrowUpRight size={16} className="sm:w-5 sm:h-5 text-[#2F47FF]" />
        </div>
      </div>
    </div>
  );
};

