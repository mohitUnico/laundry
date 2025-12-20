import React, { useState } from 'react';
import { Modal } from '@/components/common';
import { UserPlus } from 'lucide-react';

interface AddCustomerModalProps {
  isOpen: boolean;
  onClose: () => void;
  onSuccess: () => void;
}

export const AddCustomerModal: React.FC<AddCustomerModalProps> = ({ isOpen, onClose, onSuccess }) => {
  const [name, setName] = useState('');
  const [phone, setPhone] = useState('');
  const [email, setEmail] = useState('');
  const [address, setAddress] = useState('');
  const [notes, setNotes] = useState('');

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    // Simulate customer creation
    setTimeout(() => {
      onSuccess();
      onClose();
      setName('');
      setPhone('');
      setEmail('');
      setAddress('');
      setNotes('');
    }, 1000);
  };

  return (
    <Modal isOpen={isOpen} onClose={onClose} title="Add New Customer" size="md">
      <form onSubmit={handleSubmit} className="space-y-3 sm:space-y-4">
        <div>
          <label className="block text-xs sm:text-sm font-medium text-slate-700 mb-1.5 sm:mb-2">
            Full Name *
          </label>
          <input
            type="text"
            value={name}
            onChange={(e) => setName(e.target.value)}
            placeholder="Enter full name"
            className="w-full px-3 sm:px-4 py-2 text-xs sm:text-sm border border-slate-200 rounded-lg sm:rounded-xl focus:outline-none focus:ring-2 focus:ring-blue-500 focus:border-transparent"
            required
          />
        </div>

        <div className="grid grid-cols-1 sm:grid-cols-2 gap-3 sm:gap-4">
          <div>
            <label className="block text-xs sm:text-sm font-medium text-slate-700 mb-1.5 sm:mb-2">
              Contact Number *
            </label>
            <input
              type="tel"
              value={phone}
              onChange={(e) => setPhone(e.target.value)}
              placeholder="Phone number"
              className="w-full px-3 sm:px-4 py-2 text-xs sm:text-sm border border-slate-200 rounded-lg sm:rounded-xl focus:outline-none focus:ring-2 focus:ring-blue-500 focus:border-transparent"
              required
            />
          </div>
          <div>
            <label className="block text-xs sm:text-sm font-medium text-slate-700 mb-1.5 sm:mb-2">
              Email
            </label>
            <input
              type="email"
              value={email}
              onChange={(e) => setEmail(e.target.value)}
              placeholder="Email address"
              className="w-full px-3 sm:px-4 py-2 text-xs sm:text-sm border border-slate-200 rounded-lg sm:rounded-xl focus:outline-none focus:ring-2 focus:ring-blue-500 focus:border-transparent"
            />
          </div>
        </div>

        <div>
          <label className="block text-xs sm:text-sm font-medium text-slate-700 mb-1.5 sm:mb-2">
            Address *
          </label>
          <textarea
            value={address}
            onChange={(e) => setAddress(e.target.value)}
            placeholder="Enter full address"
            rows={3}
            className="w-full px-3 sm:px-4 py-2 text-xs sm:text-sm border border-slate-200 rounded-lg sm:rounded-xl focus:outline-none focus:ring-2 focus:ring-blue-500 focus:border-transparent resize-none"
            required
          />
        </div>

        <div>
          <label className="block text-xs sm:text-sm font-medium text-slate-700 mb-1.5 sm:mb-2">
            Notes
          </label>
          <textarea
            value={notes}
            onChange={(e) => setNotes(e.target.value)}
            placeholder="Additional notes (optional)"
            rows={2}
            className="w-full px-3 sm:px-4 py-2 text-xs sm:text-sm border border-slate-200 rounded-lg sm:rounded-xl focus:outline-none focus:ring-2 focus:ring-blue-500 focus:border-transparent resize-none"
          />
        </div>

        <div className="flex flex-col sm:flex-row gap-2 sm:gap-3 pt-3 sm:pt-4">
          <button
            type="button"
            onClick={onClose}
            className="flex-1 px-4 py-2 text-xs sm:text-sm border border-slate-300 text-slate-700 rounded-lg sm:rounded-xl hover:bg-slate-50 font-medium transition-colors"
          >
            Cancel
          </button>
          <button
            type="submit"
            className="flex-1 px-4 py-2 text-xs sm:text-sm bg-blue-600 text-white rounded-lg sm:rounded-xl hover:bg-blue-700 font-medium transition-colors flex items-center justify-center gap-1.5 sm:gap-2"
          >
            <UserPlus size={16} className="sm:w-[18px] sm:h-[18px]" />
            Add Customer
          </button>
        </div>
      </form>
    </Modal>
  );
};

