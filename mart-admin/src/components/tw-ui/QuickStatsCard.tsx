import React from 'react';

export const QuickStatsCard: React.FC = () => {
  return (
    <div className="rounded-2xl bg-indigo-700 text-white p-5 shadow-sm">
      <div className="text-sm font-semibold mb-3">Quick Stats</div>
      <div className="grid grid-cols-2 gap-y-2 text-sm">
        <div className="text-indigo-100">Most Popular</div>
        <div className="font-semibold text-right">Wash & Fold</div>
        <div className="text-indigo-100">Highest Revenue</div>
        <div className="font-semibold text-right">Dry Clean</div>
        <div className="text-indigo-100">Avg. Service Time</div>
        <div className="font-semibold text-right">28 Hours</div>
      </div>
    </div>
  );
};


