import React from 'react';

interface NavItem {
  label: string;
  active?: boolean;
}

const NAV_ITEMS: NavItem[] = [
  { label: 'Dashboard' },
  { label: 'Orders' },
  { label: 'Customers' },
  { label: 'Delivery Staff' },
  { label: 'Payments' },
  { label: 'Services', active: true },
  { label: 'Promotions' },
  { label: 'Analytics' },
  { label: 'Notifications' },
  { label: 'Settings' },
];

export const Sidebar: React.FC = () => {
  return (
    <aside className="sticky top-0 h-screen w-64 bg-white border-r border-slate-100 py-6 px-4 hidden lg:block">
      <div className="text-xs uppercase tracking-wider text-slate-400 px-2 mb-4">Menu</div>
      <nav className="space-y-1">
        {NAV_ITEMS.map((item) => (
          <button
            key={item.label}
            className={
              'w-full flex items-center gap-3 rounded-lg px-3 py-2 text-slate-700 hover:bg-slate-50 ' +
              (item.active ? 'bg-indigo-50 text-indigo-700 font-semibold' : '')
            }
          >
            <span className="h-5 w-5 rounded-md bg-slate-200" />
            <span className="text-sm">{item.label}</span>
          </button>
        ))}
      </nav>
    </aside>
  );
};


