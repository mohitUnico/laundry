import React, { useEffect } from 'react';
import { motion, AnimatePresence } from 'framer-motion';
import { Bell, MessageSquareWarning, MessageCircle, X } from 'lucide-react';

export interface NotificationItem {
  id: string;
  type: 'order' | 'alert' | 'feedback';
  text: string;
  time: string;
  read?: boolean;
}

interface NotificationDrawerProps {
  isOpen: boolean;
  onClose: () => void;
  items: NotificationItem[];
  onMarkAllRead: () => void;
}

const IconByType: Record<NotificationItem['type'], React.ReactNode> = {
  order: <Bell size={16} className="text-blue-600" />,
  alert: <MessageSquareWarning size={16} className="text-amber-600" />,
  feedback: <MessageCircle size={16} className="text-emerald-600" />,
};

export const NotificationDrawer: React.FC<NotificationDrawerProps> = ({ isOpen, onClose, items, onMarkAllRead }) => {
  // Handle ESC key to close drawer
  useEffect(() => {
    if (!isOpen) return;

    const handleEscape = (e: KeyboardEvent) => {
      if (e.key === 'Escape') {
        onClose();
      }
    };

    document.addEventListener('keydown', handleEscape);
    // Prevent body scroll when drawer is open
    document.body.style.overflow = 'hidden';

    return () => {
      document.removeEventListener('keydown', handleEscape);
      document.body.style.overflow = 'unset';
    };
  }, [isOpen, onClose]);

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
            aria-hidden="true"
          />
          <motion.aside
            className="fixed right-0 top-0 h-full w-full max-w-md bg-white z-[61] shadow-xl flex flex-col"
            initial={{ x: '100%', opacity: 0 }}
            animate={{ x: 0, opacity: 1 }}
            exit={{ x: '100%', opacity: 0 }}
            onClick={(e) => e.stopPropagation()}
          >
            {/* Header with Close Button */}
            <div className="flex items-center justify-between p-3 sm:p-4 border-b border-slate-200 flex-shrink-0">
              <h3 className="text-base sm:text-lg font-semibold text-slate-900">Notifications</h3>
              <div className="flex items-center gap-2 sm:gap-3">
                <button 
                  onClick={onMarkAllRead} 
                  className="text-xs sm:text-sm text-blue-600 hover:text-blue-700 hover:underline transition-colors"
                >
                  Mark all as read
                </button>
                <button
                  onClick={onClose}
                  className="p-1.5 sm:p-2 text-slate-400 hover:text-slate-600 hover:bg-slate-100 rounded-lg transition-colors flex-shrink-0"
                  aria-label="Close notifications"
                >
                  <X size={18} className="sm:w-5 sm:h-5" />
                </button>
              </div>
            </div>

            {/* Notifications List */}
            <div className="flex-1 overflow-y-auto p-3 sm:p-4">
              {items.length === 0 ? (
                <div className="flex flex-col items-center justify-center h-full text-center py-12">
                  <Bell size={48} className="text-slate-300 mb-3" />
                  <p className="text-sm text-slate-500">No notifications</p>
                </div>
              ) : (
                <div className="space-y-2 sm:space-y-3">
                  {items.map((n) => (
                    <div 
                      key={n.id} 
                      className={`flex items-start gap-2 sm:gap-3 p-2.5 sm:p-3 rounded-lg sm:rounded-xl border transition-colors ${
                        n.read ? 'bg-white border-slate-200' : 'bg-slate-50 border-slate-200'
                      } hover:border-slate-300`}
                    >
                      <div className="mt-0.5 flex-shrink-0">{IconByType[n.type]}</div>
                      <div className="flex-1 min-w-0">
                        <p className="text-xs sm:text-sm text-slate-800 break-words">{n.text}</p>
                        <p className="text-[10px] sm:text-xs text-slate-500 mt-0.5">{n.time}</p>
                      </div>
                    </div>
                  ))}
                </div>
              )}
            </div>
          </motion.aside>
        </>
      )}
    </AnimatePresence>
  );
};


