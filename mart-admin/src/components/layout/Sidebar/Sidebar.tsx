import React from 'react';
import { NavLink } from 'react-router-dom';
import { ROUTES } from '@/routes/routeConfig';
import {
  LayoutDashboard,
  Package,
  Users,
  Bike,
  DollarSign,
  ClipboardList,
  Sparkles,
  BarChart2,
  MessageSquare,
  Settings,
} from 'lucide-react';

interface SidebarItem {
  label: string;
  path: string;
  icon: React.ReactNode;
}

const sidebarConfig: SidebarItem[] = [
  { label: 'Dashboard', path: ROUTES.DASHBOARD, icon: <LayoutDashboard size={20} /> },
  { label: 'Orders', path: ROUTES.ORDERS, icon: <Package size={20} /> },
  { label: 'Customers', path: ROUTES.CUSTOMERS, icon: <Users size={20} /> },
  { label: 'Delivery Staff', path: ROUTES.DELIVERY_STAFF, icon: <Bike size={20} /> },
  { label: 'Services', path: ROUTES.SERVICES, icon: <ClipboardList size={20} /> },
  { label: 'Promotions', path: ROUTES.PROMOTIONS, icon: <Sparkles size={20} /> },
  { label: 'Payments', path: ROUTES.PAYMENTS, icon: <DollarSign size={20} /> },
  { label: 'Analytics', path: ROUTES.ANALYTICS, icon: <BarChart2 size={20} /> },
  { label: 'Notification', path: ROUTES.NOTIFICATIONS, icon: <MessageSquare size={20} /> },
  { label: 'Settings', path: ROUTES.SETTINGS, icon: <Settings size={20} /> },
];

interface SidebarProps {
  isOpen: boolean;
  onClose: () => void;
}

export const Sidebar: React.FC<SidebarProps> = ({ isOpen, onClose }) => {
  return (
    <aside
      className={`fixed left-0 top-0 h-screen w-[288px] z-50 transition-transform duration-300 ease-in-out px-3 sm:px-4 py-3 sm:py-4 lg:static lg:h-full lg:w-[288px] lg:translate-x-0 lg:px-0 lg:py-0 ${
        isOpen ? 'translate-x-0' : '-translate-x-full'
      }`}
      aria-label="Main navigation"
    >
      <div className="h-full w-full rounded-[24px] bg-white border border-[#E2E8F0] shadow-[0_1px_2px_rgba(15,23,42,0.06)] overflow-hidden flex flex-col">
        <div className="px-5 py-5 flex-shrink-0">
          <div className="text-[11px] font-medium text-[#64748B] uppercase tracking-wider mb-4">
            MENU
          </div>
          <div className="flex flex-col gap-1">
            {sidebarConfig.map((item) => (
              <NavLink
                key={item.path}
                to={item.path}
                onClick={() => {
                  if (window.innerWidth < 1024) {
                    onClose();
                  }
                }}
                className={({ isActive }) =>
                  `relative flex items-center gap-3 px-4 py-3 rounded-[16px] transition-colors ${
                    isActive
                      ? 'bg-[#EEF2FF] text-[#2F47FF]'
                      : 'text-[#64748B] hover:bg-white/70'
                  }`
                }
              >
                {({ isActive }) => (
                  <>
                    {isActive && (
                      <span
                        aria-hidden="true"
                        className="absolute left-0 top-1/2 -translate-y-1/2 h-6 w-1.5 rounded-full bg-[#2F47FF]"
                      />
                    )}
                    <span
                      className={`flex-shrink-0 ${
                        isActive ? 'text-[#2F47FF]' : 'text-[#94A3B8]'
                      }`}
                    >
                      {item.icon}
                    </span>
                    <span className="text-sm font-medium truncate">{item.label}</span>
                  </>
                )}
              </NavLink>
            ))}
          </div>
        </div>
        <div className="flex-1" />
      </div>
    </aside>
  );
};
