import React from 'react';
import { Modal } from '@/components/common';

interface ViewServiceModalProps {
  isOpen: boolean;
  onClose: () => void;
  service?: {
    name: string;
    description?: string | null;
    pricePerKg?: string | null;
    duration?: string | null;
    status?: 'Active' | 'Inactive';
  };
}

export const ViewServiceModal: React.FC<ViewServiceModalProps> = ({ isOpen, onClose, service }) => {
  return (
    <Modal isOpen={isOpen} onClose={onClose} title="Service Details" size="md">
      <div className="space-y-4">
        <div className="flex items-start justify-between gap-3">
          <div>
            <div className="text-lg font-semibold text-slate-900">{service?.name || '-'}</div>
            {service?.description ? <div className="text-sm text-slate-500 mt-1">{service.description}</div> : null}
          </div>
          <span
            className={
              'px-2 py-0.5 text-[11px] rounded-md border ' +
              ((service?.status || 'Active') === 'Active'
                ? 'bg-emerald-50 text-emerald-700 border-emerald-200'
                : 'bg-slate-50 text-slate-500 border-slate-200')
            }
          >
            {service?.status || 'Active'}
          </span>
        </div>

        <div className="grid grid-cols-2 gap-4">
          <div className="rounded-xl border border-slate-100 p-3">
            <div className="text-[12px] text-slate-500">Price per kg</div>
            <div className="text-sm font-semibold text-slate-900">{service?.pricePerKg || '-'}</div>
          </div>
          <div className="rounded-xl border border-slate-100 p-3">
            <div className="text-[12px] text-slate-500">Duration</div>
            <div className="text-sm font-semibold text-slate-900">{service?.duration || '-'}</div>
          </div>
        </div>
      </div>
    </Modal>
  );
};

