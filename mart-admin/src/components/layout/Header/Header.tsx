import React, { useMemo, useState } from 'react';
import { Bell, Menu } from 'lucide-react';
import { ProfileDrawer } from './ProfileDrawer';
import { EditProfileModal } from './EditProfileModal';
import { NotificationDrawer, NotificationItem } from './NotificationDrawer';
import { SearchBar } from './SearchBar';
import { useToast } from '@/hooks/common';
import { useAuth } from '@/hooks';
import { useNavigate } from 'react-router-dom';
import { ROUTES } from '@/routes';
import { splitName } from '@/utils/helpers';

interface HeaderProps {
  onMenuClick?: () => void;
  onAddReport?: () => void; // legacy prop support
  onExportReport?: () => void; // legacy prop support
}

export const Header: React.FC<HeaderProps> = ({ onMenuClick }) => {
  const { showToast } = useToast();
  const navigate = useNavigate();
  const { user, logout, updateProfile } = useAuth();

  const profileUser = useMemo((): { firstName: string; lastName?: string; role?: string; email?: string; avatarUrl?: string } | null => {
    if (!user) {
      return null;
    }

    const nameParts = splitName(user.name);
    const fallbackFirst = nameParts.firstName || (user.email ? user.email.split('@')[0] : '');
    const safeFirstName = fallbackFirst || 'User';

    return {
      firstName: safeFirstName,
      lastName: nameParts.lastName || undefined,
      role: user.role ?? 'Admin',
      email: user.email || undefined,
      avatarUrl: undefined,
    };
  }, [user]);

  const displayFirstName = profileUser?.firstName ?? 'User';
  const displayLastName = profileUser?.lastName ?? '';

  // UI state
  const [isProfileOpen, setProfileOpen] = useState(false);
  const [isEditProfileOpen, setEditProfileOpen] = useState(false);
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

  const handleMarkAllRead = () => {
    setNotifications((prev) => prev.map((n) => ({ ...n, read: true })));
  };

  const handleLogout = () => {
    logout();
    showToast('Logged out', 'success');
    navigate(ROUTES.LOGIN);
  };

  const handleProfileSave = (values: { firstName: string; lastName: string; email: string; role: string }) => {
    updateProfile(values);
    showToast('Profile updated!', 'success');
  };

  return (
    <header className="sticky top-0 z-40">
      <div className="bg-white border border-[#E2E8F0] rounded-[24px] shadow-[0_1px_2px_rgba(15,23,42,0.06)] px-3 sm:px-4 md:px-5 lg:px-6 py-3 sm:py-3.5 md:py-4">
        <div className="flex items-center justify-between gap-2 sm:gap-3 md:gap-4">
          {/* Search Bar */}
          <div className="flex-1 max-w-xs sm:max-w-sm md:max-w-md lg:max-w-lg relative">
            <SearchBar data={searchData} onNavigate={handleNavigate} />
            <button
              onClick={onMenuClick}
              className="lg:hidden absolute right-2 top-1/2 -translate-y-1/2 p-1.5 text-[#64748B] hover:text-[#0F172A] rounded-md hover:bg-[#F7F7F7] transition-colors"
              aria-label="Toggle menu"
            >
              <Menu size={20} />
            </button>
          </div>

          {/* Right Section */}
          <div className="flex items-center gap-1.5 sm:gap-2 md:gap-3 lg:gap-4">
            {/* Notification Bell */}
            <button
              className="relative p-2 text-[#64748B] hover:text-[#0F172A] transition-colors rounded-full hover:bg-[#F7F7F7]"
              onClick={() => setNotifOpen(true)}
              aria-label="Open notifications"
            >
              <Bell size={18} className="sm:w-5 sm:h-5 md:w-6 md:h-6" />
              {hasUnread && (
                <span className="absolute top-0.5 right-0.5 sm:top-1 sm:right-1 h-2 w-2 bg-red-500 rounded-full ring-2 ring-white"></span>
              )}
            </button>

            {/* User Info */}
            <div className="flex items-center gap-1.5 sm:gap-2 md:gap-3">
              <button
                onClick={() => setProfileOpen(true)}
                className="relative group"
                aria-label="View Profile"
              >
                <img
                  src="https://i.pravatar.cc/40?img=67"
                  alt="User"
                  className="w-7 h-7 sm:w-8 sm:h-8 md:w-9 md:h-9 lg:w-10 lg:h-10 rounded-full border-2 border-transparent group-hover:border-[#2F47FF] transition-colors cursor-pointer"
                />
                <div className="absolute inset-0 rounded-full bg-[#2F47FF] opacity-0 group-hover:opacity-10 transition-opacity"></div>
              </button>
              <div className="hidden sm:block">
                <button
                  title="View Profile"
                  onClick={() => setProfileOpen(true)}
                  className="text-left group"
                >
                  <p className="text-[10px] sm:text-xs text-[#64748B] leading-none mb-1">Hey, Welcome!</p>
                  <p className="text-xs sm:text-sm font-semibold text-[#0F172A] group-hover:text-[#2F47FF] transition-colors truncate max-w-[140px] md:max-w-none">
                    {displayFirstName} {displayLastName}
                  </p>
                </button>
              </div>
            </div>
          </div>
        </div>
      </div>

      {/* Drawers & Modals */}
      <ProfileDrawer
        isOpen={isProfileOpen}
        onClose={() => setProfileOpen(false)}
        user={profileUser}
        onEditProfile={() => setEditProfileOpen(true)}
        onLogout={handleLogout}
      />
      <NotificationDrawer isOpen={notifOpen} onClose={() => setNotifOpen(false)} items={notifications} onMarkAllRead={handleMarkAllRead} />
      <EditProfileModal
        isOpen={isEditProfileOpen}
        onClose={() => setEditProfileOpen(false)}
        initial={profileUser ?? {}}
        onSave={handleProfileSave}
      />
    </header>
  );
};
