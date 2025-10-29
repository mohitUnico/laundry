import { ROUTES } from '@/routes/routeConfig';

export interface SidebarItem {
  label: string;
  path: string;
  icon?: string;
}

export const sidebarConfig: SidebarItem[] = [
  { label: 'Dashboard', path: ROUTES.DASHBOARD, icon: 'dashboard' },
  { label: 'Orders', path: ROUTES.ORDERS, icon: 'orders' },
  { label: 'Customers', path: ROUTES.CUSTOMERS, icon: 'customers' },
  { label: 'Delivery Staff', path: ROUTES.DELIVERY_STAFF, icon: 'delivery' },
  { label: 'Services', path: ROUTES.SERVICES, icon: 'services' },
  { label: 'Promotions', path: ROUTES.PROMOTIONS, icon: 'promotions' },
  { label: 'Analytics', path: ROUTES.ANALYTICS, icon: 'analytics' },
  { label: 'Notifications', path: ROUTES.NOTIFICATIONS, icon: 'notifications' },
  { label: 'Settings', path: ROUTES.SETTINGS, icon: 'settings' },
];
