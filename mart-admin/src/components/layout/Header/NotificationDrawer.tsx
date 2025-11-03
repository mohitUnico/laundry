import React from 'react';
import { motion, AnimatePresence } from 'framer-motion';
import { Bell, MessageSquareWarning, MessageCircle } from 'lucide-react';

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
  return (
    <AnimatePresence>
      {isOpen && (
        <>
          <motion.div className="fixed inset-0 bg-black/30 z-[60]" initial={{ opacity: 0 }} animate={{ opacity: 1 }} exit={{ opacity: 0 }} onClick={onClose} />
          <motion.aside
            className="fixed right-0 top-0 h-full w-full max-w-md bg-white z-[61] shadow-xl"
            initial={{ x: '100%', opacity: 0 }}
            animate={{ x: 0, opacity: 1 }}
            exit={{ x: '100%', opacity: 0 }}
          >
            <div className="flex items-center justify-between p-4 border-b border-slate-200">
              <h3 className="text-lg font-semibold">Notifications</h3>
              <button onClick={onMarkAllRead} className="text-sm text-blue-600 hover:underline">Mark all as read</button>
            </div>
            <div className="p-4 space-y-2 overflow-y-auto h-[calc(100%-64px)]">
              {items.map((n) => (
                <div key={n.id} className={`flex items-start gap-3 p-3 rounded-xl border ${n.read ? 'bg-white' : 'bg-slate-50'} border-slate-200`}>
                  <div className="mt-0.5">{IconByType[n.type]}</div>
                  <div className="flex-1">
                    <p className="text-sm text-slate-800">{n.text}</p>
                    <p className="text-xs text-slate-500 mt-0.5">{n.time}</p>
                  </div>
                </div>
              ))}
            </div>
          </motion.aside>
        </>
      )}
    </AnimatePresence>
  );
};


