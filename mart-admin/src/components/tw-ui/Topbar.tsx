import React from 'react';

export const Topbar: React.FC = () => {
  return (
    <header className="bg-white rounded-2xl shadow-sm border border-slate-100 px-4 sm:px-6 py-3 grid grid-cols-[auto_1fr_auto_auto] gap-3 items-center">
      <button aria-label="search" className="p-2 rounded-lg hover:bg-slate-50">
        <span className="block h-5 w-5 bg-slate-300 rounded" />
      </button>
      <div>
        <input
          type="text"
          placeholder="Search orders, Customers, Services..."
          className="w-full min-w-[420px] bg-slate-50 border border-slate-200 rounded-full px-4 py-2 text-sm outline-none focus:ring-2 focus:ring-indigo-200"
        />
      </div>
      <button aria-label="filter" className="p-2 rounded-lg hover:bg-slate-50 border border-slate-200">
        <span className="block h-5 w-5 bg-slate-300 rounded" />
      </button>
      <div className="flex items-center gap-3 pl-2">
        <div className="h-9 w-9 rounded-full bg-slate-200" />
        <div className="text-right leading-4">
          <div className="text-xs text-slate-500">Hey, Welcome!</div>
          <div className="text-sm font-semibold text-slate-800">Michael Jackson</div>
        </div>
      </div>
    </header>
  );
};


