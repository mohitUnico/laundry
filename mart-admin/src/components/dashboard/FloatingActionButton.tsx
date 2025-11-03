import React, { useState } from 'react';
import { Plus, ShoppingBag, UserPlus, FileText, Bell } from 'lucide-react';

interface FloatingActionButtonProps {
  onCreateOrder?: () => void;
  onAddStaff?: () => void;
  onCreateReport?: () => void;
  onSendNotification?: () => void;
}

export const FloatingActionButton: React.FC<FloatingActionButtonProps> = ({
  onCreateOrder,
  onAddStaff,
  onCreateReport,
  onSendNotification,
}) => {
  const [isOpen, setIsOpen] = useState(false);

  const actions = [
    {
      label: 'Add Order',
      icon: <ShoppingBag size={20} />,
      color: 'bg-blue-600',
      onClick: () => {
        onCreateOrder?.();
        setIsOpen(false);
      },
    },
    {
      label: 'Add Staff',
      icon: <UserPlus size={20} />,
      color: 'bg-purple-600',
      onClick: () => {
        onAddStaff?.();
        setIsOpen(false);
      },
    },
    {
      label: 'Create Report',
      icon: <FileText size={20} />,
      color: 'bg-green-600',
      onClick: () => {
        onCreateReport?.();
        setIsOpen(false);
      },
    },
    {
      label: 'Notification',
      icon: <Bell size={20} />,
      color: 'bg-orange-600',
      onClick: () => {
        onSendNotification?.();
        setIsOpen(false);
      },
    },
  ];

  return (
    <div className="fixed bottom-6 right-6 z-50">
      {/* Radial Menu */}
      {isOpen && (
        <div className="absolute bottom-20 right-0 mb-4 space-y-2 animate-slide-in">
          {actions.map((action, index) => (
            <button
              key={action.label}
              onClick={action.onClick}
              className="group flex items-center gap-3 rounded-full bg-white px-4 py-3 shadow-lg hover:shadow-xl transition-all animate-scale-in"
              style={{ animationDelay: `${index * 0.05}s` }}
            >
              <span className={`p-2 ${action.color} rounded-full text-white`}>
                {action.icon}
              </span>
              <span className="text-sm font-medium text-slate-700 whitespace-nowrap group-hover:text-slate-900">
                {action.label}
              </span>
            </button>
          ))}
        </div>
      )}

      {/* Main FAB Button */}
      <button
        onClick={() => setIsOpen(!isOpen)}
        className={`w-14 h-14 rounded-full shadow-lg flex items-center justify-center transition-transform transform ${
          isOpen ? 'bg-red-600 rotate-45' : 'bg-blue-600 hover:bg-blue-700'
        }`}
      >
        <Plus size={24} className="text-white" />
      </button>
    </div>
  );
};

