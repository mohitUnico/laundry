import React from 'react';
import { Modal } from '@/components/common';
import { Mail, Phone, MapPin, Star } from 'lucide-react';

export type ViewCustomerModalCustomer = {
  customerId: string;
  name: string;
  email: string;
  phone?: string | null;
  address?: string | null;
  totalOrders: number;
  rating: number | null;
  joinedText?: string;
};

interface ViewCustomerModalProps {
  isOpen: boolean;
  onClose: () => void;
  customer?: ViewCustomerModalCustomer;
  onViewOrders?: (customer: ViewCustomerModalCustomer) => void;
}

export const ViewCustomerModal: React.FC<ViewCustomerModalProps> = ({ isOpen, onClose, customer, onViewOrders }) => {
  return (
    <Modal isOpen={isOpen} onClose={onClose} title="Customer Profile" size="lg">
      {!customer ? (
        <div className="text-sm text-slate-600">Customer not found.</div>
      ) : (
        <div className="space-y-5">
          <div className="flex items-start justify-between gap-4">
            <div className="flex items-center gap-3">
              <div className="h-12 w-12 rounded-full bg-slate-200" />
              <div>
                <div className="text-lg font-semibold text-slate-900">{customer.name}</div>
                <div className="text-xs text-slate-500">{customer.joinedText || ''}</div>
              </div>
            </div>
            <button
              type="button"
              onClick={() => onViewOrders?.(customer)}
              className="rounded-xl bg-indigo-700 px-4 py-2 text-sm text-white hover:bg-indigo-600 transition-colors"
            >
              View Orders
            </button>
          </div>

          <div className="grid grid-cols-1 sm:grid-cols-2 gap-3">
            <div className="rounded-xl border border-slate-200 bg-slate-50 p-3">
              <div className="flex items-center gap-2 text-xs text-slate-500">
                <Mail className="h-4 w-4" /> Email
              </div>
              <div className="mt-1 text-sm font-medium text-slate-900 break-all">{customer.email}</div>
            </div>
            <div className="rounded-xl border border-slate-200 bg-slate-50 p-3">
              <div className="flex items-center gap-2 text-xs text-slate-500">
                <Phone className="h-4 w-4" /> Phone
              </div>
              <div className="mt-1 text-sm font-medium text-slate-900">{customer.phone || 'N/A'}</div>
            </div>
            <div className="rounded-xl border border-slate-200 bg-slate-50 p-3 sm:col-span-2">
              <div className="flex items-center gap-2 text-xs text-slate-500">
                <MapPin className="h-4 w-4" /> Address
              </div>
              <div className="mt-1 text-sm font-medium text-slate-900">{customer.address || 'No address'}</div>
            </div>
            <div className="rounded-xl border border-slate-200 bg-slate-50 p-3">
              <div className="text-xs text-slate-500">Total Orders</div>
              <div className="mt-1 text-sm font-semibold text-slate-900">{customer.totalOrders}</div>
            </div>
            <div className="rounded-xl border border-slate-200 bg-slate-50 p-3">
              <div className="text-xs text-slate-500">Rating</div>
              <div className="mt-1 inline-flex items-center gap-1 text-sm font-semibold text-slate-900">
                <Star className="h-4 w-4 text-amber-400 fill-amber-400" />
                <span>{customer.rating ?? 'N/A'}</span>
              </div>
            </div>
          </div>

          <div className="flex items-center justify-end gap-2 pt-2">
            <button
              type="button"
              onClick={onClose}
              className="rounded-xl border border-slate-200 bg-white px-4 py-2 text-sm text-slate-700 hover:bg-slate-50 transition-colors"
            >
              Close
            </button>
          </div>
        </div>
      )}
    </Modal>
  );
};

