import React, { useEffect, useState } from 'react';
import { Modal } from '@/components/common';
import { Send } from 'lucide-react';
import { notificationsApi, SendNotificationPayload } from '@/services/api/modules/notificationsApi';

interface SendNotificationModalProps {
  isOpen: boolean;
  onClose: () => void;
  onSuccess: () => void;
  initialAudience?: 'all' | 'active' | 'custom';
  onError?: (error: unknown) => void;
}

export const SendNotificationModal: React.FC<SendNotificationModalProps> = ({ isOpen, onClose, onSuccess, initialAudience = 'all', onError }) => {
  const [title, setTitle] = useState('');
  const [message, setMessage] = useState('');
  const [audience, setAudience] = useState<'all' | 'active' | 'custom'>(initialAudience);
  const [submitting, setSubmitting] = useState(false);

  useEffect(() => {
    if (isOpen) {
      setAudience(initialAudience);
    }
  }, [isOpen, initialAudience]);

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    try {
      setSubmitting(true);
      const payload: SendNotificationPayload = {
        title,
        message,
        audience,
      };
      await notificationsApi.send(payload);
      onSuccess();
      onClose();
      setTitle('');
      setMessage('');
      setAudience('all');
    } catch (err) {
      if (onError) onError(err);
    } finally {
      setSubmitting(false);
    }
  };

  return (
    <Modal isOpen={isOpen} onClose={onClose} title="Send Notification" size="md">
      <form onSubmit={handleSubmit} className="space-y-3 sm:space-y-4">
        <div>
          <label className="block text-xs sm:text-sm font-medium text-slate-700 mb-1.5 sm:mb-2">
            Message Title *
          </label>
          <input
            type="text"
            value={title}
            onChange={(e) => setTitle(e.target.value)}
            placeholder="Enter notification title"
            className="w-full px-3 sm:px-4 py-2 text-xs sm:text-sm border border-slate-200 rounded-lg sm:rounded-xl focus:outline-none focus:ring-2 focus:ring-blue-500 focus:border-transparent"
            required
          />
        </div>

        <div>
          <label className="block text-xs sm:text-sm font-medium text-slate-700 mb-1.5 sm:mb-2">
            Message Body *
          </label>
          <textarea
            value={message}
            onChange={(e) => setMessage(e.target.value)}
            placeholder="Enter notification message"
            rows={4}
            className="w-full px-3 sm:px-4 py-2 text-xs sm:text-sm border border-slate-200 rounded-lg sm:rounded-xl focus:outline-none focus:ring-2 focus:ring-blue-500 focus:border-transparent resize-none"
            required
          />
        </div>

        <div>
          <label className="block text-xs sm:text-sm font-medium text-slate-700 mb-1.5 sm:mb-2">
            Audience
          </label>
          <select
            value={audience}
            onChange={(e) => setAudience(e.target.value)}
            className="w-full px-3 sm:px-4 py-2 text-xs sm:text-sm border border-slate-200 rounded-lg sm:rounded-xl focus:outline-none focus:ring-2 focus:ring-blue-500 focus:border-transparent"
          >
            <option value="all">All Customers</option>
            <option value="active">Active Customers</option>
            <option value="custom">Custom Selection</option>
          </select>
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
            disabled={submitting}
            className="flex-1 px-4 py-2 text-xs sm:text-sm bg-blue-600 disabled:opacity-60 text-white rounded-lg sm:rounded-xl hover:bg-blue-700 font-medium transition-colors flex items-center justify-center gap-1.5 sm:gap-2"
          >
            <Send size={16} className="sm:w-[18px] sm:h-[18px]" />
            {submitting ? 'Sending...' : 'Send Notification'}
          </button>
        </div>
      </form>
    </Modal>
  );
};

