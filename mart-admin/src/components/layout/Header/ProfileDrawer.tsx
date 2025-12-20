import React from 'react';
import { X, Pencil, LogOut } from 'lucide-react';
import { motion, AnimatePresence } from 'framer-motion';

interface ProfileDrawerProps {
  isOpen: boolean;
  onClose: () => void;
  user: { firstName: string; lastName?: string; role?: string; email?: string; avatarUrl?: string } | null;
  onEditProfile: () => void;
  onLogout: () => void;
}

export const ProfileDrawer: React.FC<ProfileDrawerProps> = ({ isOpen, onClose, user, onEditProfile, onLogout }) => {
  const firstName = user?.firstName || 'User';
  const lastName = user?.lastName || '';
  const role = user?.role || 'Admin';
  const email = user?.email || 'user@example.com';
  const avatar = user?.avatarUrl || 'https://i.pravatar.cc/100?img=67';

  return (
    <AnimatePresence>
      {isOpen && (
        <>
          <motion.div
            className="fixed inset-0 bg-black/30 z-[60]"
            initial={{ opacity: 0 }}
            animate={{ opacity: 1 }}
            exit={{ opacity: 0 }}
            onClick={onClose}
          />
          <motion.aside
            role="dialog"
            aria-modal="true"
            className="fixed right-0 top-0 h-full w-full max-w-md bg-white z-[61] shadow-xl"
            initial={{ x: '100%', opacity: 0 }}
            animate={{ x: 0, opacity: 1 }}
            exit={{ x: '100%', opacity: 0 }}
            transition={{ type: 'spring', stiffness: 280, damping: 30 }}
          >
            <div className="flex items-center justify-between p-4 border-b border-slate-200">
              <h3 className="text-lg font-semibold text-slate-800">Profile</h3>
              <button aria-label="Close" onClick={onClose} className="p-2 rounded-md hover:bg-slate-100">
                <X size={18} />
              </button>
            </div>
            <div className="p-6">
              <div className="flex items-center gap-4 mb-6">
                <img
                  src={avatar}
                  alt="Profile"
                  className="w-16 h-16 rounded-full object-cover"
                />
                <div>
                  <p className="text-xl font-semibold text-slate-900">{firstName} {lastName}</p>
                  <p className="text-sm text-slate-500">{role}</p>
                  <p className="text-sm text-slate-500">{email}</p>
                </div>
              </div>
              <div className="flex gap-3">
                <button
                  onClick={onEditProfile}
                  className="flex items-center gap-2 px-4 py-2 rounded-lg bg-slate-800 text-white hover:bg-slate-900"
                >
                  <Pencil size={16} /> Edit Profile
                </button>
                <button
                  onClick={onLogout}
                  className="flex items-center gap-2 px-4 py-2 rounded-lg border border-red-600 text-red-600 hover:bg-red-50"
                >
                  <LogOut size={16} /> Logout
                </button>
              </div>
            </div>
          </motion.aside>
        </>
      )}
    </AnimatePresence>
  );
};


