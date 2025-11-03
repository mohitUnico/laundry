import React, { useMemo, useState } from 'react';
import { Bell, Menu, Plus, Download } from 'lucide-react';
import { ProfileDrawer } from './ProfileDrawer';
import { EditProfileModal } from './EditProfileModal';
import { AddReportModal } from './AddReportModal';
import { ExportDropdown } from './ExportDropdown';
import { NotificationDrawer, NotificationItem } from './NotificationDrawer';
import { SearchBar } from './SearchBar';
import { useToast } from '@/hooks/common';

interface HeaderProps {
  onMenuClick?: () => void;
  onAddReport?: () => void; // legacy prop support
  onExportReport?: () => void; // legacy prop support
}

export const Header: React.FC<HeaderProps> = ({ onMenuClick }) => {
  const { showToast } = useToast();

  // Mock user (replace with Supabase/auth hook later)
  const user = { firstName: 'Michael', lastName: 'Jackson', role: 'Admin', email: 'michael@example.com' };

  // UI state
  const [isProfileOpen, setProfileOpen] = useState(false);
  const [isReportOpen, setReportOpen] = useState(false);
  const [isEditProfileOpen, setEditProfileOpen] = useState(false);
  const [exportOpen, setExportOpen] = useState(false);
  const [notifOpen, setNotifOpen] = useState(false);
  const [notifications, setNotifications] = useState<NotificationItem[]>([
    { id: '1', type: 'order', text: 'New Order #ORD-2025-006 created', time: '5 min ago', read: false },
    { id: '2', type: 'feedback', text: 'Customer feedback received', time: '15 min ago', read: false },
    { id: '3', type: 'alert', text: '1 delivery delayed by 15 mins', time: '30 min ago', read: false },
  ]);

  const hasUnread = useMemo(() => notifications.some((n) => !n.read), [notifications]);

  const searchData = useMemo(
    () => [
      { id: 'ORD-2025-006', type: 'order' as const, label: 'Order ORD-2025-006', href: '/orders/ORD-2025-006' },
      { id: 'CUS-1001', type: 'customer' as const, label: 'Customer John Doe', href: '/customers/CUS-1001' },
      { id: 'SRV-DRY', type: 'service' as const, label: 'Service Dry Clean', href: '/services/SRV-DRY' },
    ],
    []
  );

  const handleNavigate = (href: string) => {
    window.location.href = href;
  };

  const handleExportSelect = (fmt: 'PDF' | 'Excel' | 'CSV') => {
    setExportOpen(false);
    showToast(`Dashboard exported as ${fmt}!`, 'success');
  };

  const handleReportSuccess = () => {
    showToast('Report successfully generated!', 'success');
  };

  const handleMarkAllRead = () => {
    setNotifications((prev) => prev.map((n) => ({ ...n, read: true })));
  };

  const handleLogout = () => {
    localStorage.removeItem('authToken');
    showToast('Logged out', 'success');
    window.location.href = '/login';
  };

  return (
    <header className="sticky top-0 z-40 bg-white border-b border-slate-200">
      <div className="flex items-center justify-between px-3 sm:px-6 py-3 sm:py-4 gap-2 sm:gap-4">
        {/* Search Bar */}
        <div className="flex-1 max-w-md relative">
          <SearchBar data={searchData} onNavigate={handleNavigate} />
          <button
            onClick={onMenuClick}
            className="lg:hidden absolute right-2 top-1/2 -translate-y-1/2 p-1.5 text-slate-400 hover:text-slate-600 rounded-md hover:bg-slate-100"
          >
            <Menu size={20} />
          </button>
        </div>

        {/* Right Section */}
        <div className="flex items-center gap-2 sm:gap-4">
          {/* Notification Bell */}
          <button
            className="relative p-1.5 sm:p-2 text-slate-600 hover:text-slate-800 transition-colors"
            onClick={() => setNotifOpen(true)}
            aria-label="Open notifications"
          >
            <Bell size={20} className="sm:w-6 sm:h-6" />
            {hasUnread && <span className="absolute top-1 right-1 sm:top-1.5 sm:right-1.5 h-2 w-2 bg-red-500 rounded-full"></span>}
          </button>

          {/* User Info */}
          <div className="flex items-center gap-2 sm:gap-3">
            <button
              onClick={() => setProfileOpen(true)}
              className="relative group"
              aria-label="View Profile"
            >
              <img
                src="https://i.pravatar.cc/40?img=67"
                alt="User"
                className="w-8 h-8 sm:w-10 sm:h-10 rounded-full border-2 border-transparent group-hover:border-blue-500 transition-colors cursor-pointer"
              />
              <div className="absolute inset-0 rounded-full bg-blue-500 opacity-0 group-hover:opacity-10 transition-opacity"></div>
            </button>
            <div className="hidden md:block">
              <button
                title="View Profile"
                onClick={() => setProfileOpen(true)}
                className="text-left group"
              >
                <p className="text-xs sm:text-sm font-medium text-slate-900 group-hover:text-blue-600 transition-colors">
                  {user.firstName} {user.lastName}
                </p>
                <p className="text-xs text-slate-500">{user.role}</p>
              </button>
            </div>
          </div>

          {/* Action Buttons */}
          <div className="hidden xl:flex items-center gap-2">
            <button 
              onClick={() => setReportOpen(true)}
              className="flex items-center gap-2 px-3 sm:px-4 py-1.5 sm:py-2 bg-blue-600 hover:bg-blue-700 text-white rounded-full text-xs sm:text-sm font-medium transition-colors"
            >
              <Plus size={14} className="sm:w-4 sm:h-4" />
              <span className="hidden 2xl:inline">Add Report</span>
            </button>
            <div className="relative">
              <button 
                onClick={() => setExportOpen((v) => !v)}
                className="flex items-center gap-2 px-3 sm:px-4 py-1.5 sm:py-2 border border-blue-600 text-blue-600 hover:bg-blue-50 rounded-full text-xs sm:text-sm font-medium transition-colors"
              >
                <Download size={14} className="sm:w-4 sm:h-4" />
                <span className="hidden 2xl:inline">Export Report</span>
              </button>
              <ExportDropdown open={exportOpen} onClose={() => setExportOpen(false)} onSelect={handleExportSelect} />
            </div>
          </div>
        </div>
      </div>

      {/* Drawers & Modals */}
      <ProfileDrawer
        isOpen={isProfileOpen}
        onClose={() => setProfileOpen(false)}
        user={user}
        onEditProfile={() => setEditProfileOpen(true)}
        onLogout={handleLogout}
      />
      <AddReportModal isOpen={isReportOpen} onClose={() => setReportOpen(false)} onSuccess={handleReportSuccess} />
      <NotificationDrawer isOpen={notifOpen} onClose={() => setNotifOpen(false)} items={notifications} onMarkAllRead={handleMarkAllRead} />
      <EditProfileModal
        isOpen={isEditProfileOpen}
        onClose={() => setEditProfileOpen(false)}
        initial={user}
        onSave={() => showToast('Profile updated!', 'success')}
      />
    </header>
  );
};
