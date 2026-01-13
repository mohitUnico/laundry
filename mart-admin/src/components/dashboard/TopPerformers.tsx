import React from 'react';
import { Star } from 'lucide-react';

export interface TopPerformerItem {
  name: string;
  deliveries: number;
  rating: number;
  avatarUrl?: string | null;
}

export const TopPerformers: React.FC<{ items?: TopPerformerItem[] }> = ({ items = [] }) => {
  return (
    <div className="bg-white rounded-2xl p-4 sm:p-6 border border-slate-200">
      <h3 className="text-base sm:text-lg font-semibold text-slate-800 mb-4 sm:mb-6">Top Performers</h3>

      <div className="space-y-3 sm:space-y-5">
        {items.map((performer) => (
          <div key={performer.name} className="flex items-center justify-between">
            <div className="flex items-center gap-2 sm:gap-3 min-w-0 flex-1">
              {performer.avatarUrl ? (
                <img
                  src={performer.avatarUrl}
                  alt={performer.name}
                  className="w-8 h-8 sm:w-10 sm:h-10 rounded-full flex-shrink-0"
                />
              ) : (
                <div className="w-8 h-8 sm:w-10 sm:h-10 rounded-full flex-shrink-0 bg-slate-100 text-slate-700 flex items-center justify-center font-semibold">
                  {performer.name?.charAt(0) || 'U'}
                </div>
              )}
              <div className="min-w-0">
                <p className="font-semibold text-slate-800 text-sm sm:text-base truncate">{performer.name}</p>
                <p className="text-xs sm:text-sm text-slate-500">
                  {performer.deliveries} Deliveries
                </p>
              </div>
            </div>
            <div className="flex items-center gap-1 text-amber-500 flex-shrink-0 ml-2">
              <Star size={16} className="sm:w-5 sm:h-5" fill="currentColor" />
              <span className="font-semibold text-sm sm:text-base">{performer.rating}</span>
            </div>
          </div>
        ))}
      </div>
    </div>
  );
};

