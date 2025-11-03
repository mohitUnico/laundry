import React from 'react';
import { PackagePlus, UserPlus, UserCheck, BellRing } from 'lucide-react';

interface QuickActionsProps {
  onCreateOrder?: () => void;
  onAddCustomer?: () => void;
  onAddStaff?: () => void;
  onSendNotification?: () => void;
}

export const QuickActions: React.FC<QuickActionsProps> = ({
  onCreateOrder,
  onAddCustomer,
  onAddStaff,
  onSendNotification,
}) => {
  const actions = [
    {
      label: 'Create New Order',
      icon: <PackagePlus size={20} />,
      onClick: onCreateOrder || (() => console.log('Create New Order')),
    },
    {
      label: 'Add Customer',
      icon: <UserPlus size={20} />,
      onClick: onAddCustomer || (() => console.log('Add Customer')),
    },
    {
      label: 'Add Staff',
      icon: <UserCheck size={20} />,
      onClick: onAddStaff || (() => console.log('Add Staff')),
    },
    {
      label: 'Send Notification',
      icon: <BellRing size={20} />,
      onClick: onSendNotification || (() => console.log('Send Notification')),
    },
  ];

  return (
    <div className="bg-white rounded-2xl p-4 sm:p-6 border border-slate-200">
      <h3 className="text-base sm:text-lg font-semibold text-slate-800 mb-4 sm:mb-6">Quick Actions</h3>
      <div className="space-y-2 sm:space-y-3">
        {actions.map((action) => (
          <button
            key={action.label}
            onClick={action.onClick}
            className="w-full flex items-center gap-2 sm:gap-3 px-3 sm:px-4 py-2.5 sm:py-3 bg-white border border-slate-200 rounded-xl text-left hover:bg-slate-50 transition-colors"
          >
            <span className="text-slate-600 flex-shrink-0">
              {React.cloneElement(action.icon as React.ReactElement, { size: 18, className: 'sm:w-5 sm:h-5' })}
            </span>
            <span className="text-xs sm:text-sm font-medium text-slate-800">
              {action.label}
            </span>
          </button>
        ))}
      </div>
    </div>
  );
};


