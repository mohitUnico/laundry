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
      className={`fixed left-0 top-0 h-screen w-64 bg-white border-r border-slate-200 flex flex-col z-50 transition-transform duration-300 ease-in-out ${
        isOpen ? 'translate-x-0' : '-translate-x-full lg:translate-x-0'
      }`}
    >
      <div className="p-6 border-b border-slate-200">
        <h2 className="text-lg font-semibold text-slate-800">Laundry Mart</h2>
      </div>
      <nav className="flex-1 p-4 overflow-y-auto">
        <div className="text-xs font-medium text-slate-400 uppercase tracking-wider mb-3 px-4">
          MENU
        </div>
        {sidebarConfig.map((item) => (
          <NavLink
            key={item.path}
            to={item.path}
            onClick={() => window.innerWidth < 1024 && onClose()}
            className={({ isActive }) =>
              `flex items-center gap-3 px-4 py-3 rounded-xl mb-1 transition-colors ${
                isActive
                  ? 'bg-blue-600 text-white'
                  : 'text-slate-600 hover:bg-slate-100'
              }`
            }
          >
            <span>{item.icon}</span>
            <span className="text-sm font-medium">{item.label}</span>
          </NavLink>
        ))}
      </nav>
    </aside>
  );
};
