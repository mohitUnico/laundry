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
    <div className="bg-white rounded-[24px] p-4 sm:p-6 border border-[#E2E8F0] shadow-[0_1px_2px_rgba(15,23,42,0.06)]">
      <h3 className="text-base sm:text-lg font-semibold text-[#0F172A] mb-4 sm:mb-6">Quick Actions</h3>
      <div className="space-y-2 sm:space-y-3">
        {actions.map((action) => (
          <button
            key={action.label}
            onClick={action.onClick}
            className="w-full flex items-center gap-2 sm:gap-3 px-3 sm:px-4 py-2.5 sm:py-3 bg-[#F7F7F7] border border-[#E2E8F0] rounded-[16px] text-left hover:bg-[#EEF2FF] hover:border-[#CBD5E1] transition-colors"
          >
            <span className="text-[#64748B] flex-shrink-0">
              {React.cloneElement(action.icon as React.ReactElement, { size: 18, className: 'sm:w-5 sm:h-5' })}
            </span>
            <span className="text-xs sm:text-sm font-medium text-[#0F172A]">
              {action.label}
            </span>
          </button>
        ))}
      </div>
    </div>
  );
};


