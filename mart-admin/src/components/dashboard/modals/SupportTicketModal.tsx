import React, { useEffect, useState } from 'react';
import { Modal } from '@/components/common';
import { ticketsApi, TicketDetail, TicketMessage } from '../../../services/api/modules/ticketsApi';

interface SupportTicketModalProps {
  isOpen: boolean;
  ticketId: string | null;
  onClose: () => void;
  onReplySuccess?: () => void;
  onError?: () => void;
}

export const SupportTicketModal: React.FC<SupportTicketModalProps> = ({ isOpen, ticketId, onClose, onReplySuccess, onError }) => {
  const [ticket, setTicket] = useState<TicketDetail | null>(null);
  const [reply, setReply] = useState('');
  const [loading, setLoading] = useState(false);
  const [sending, setSending] = useState(false);

  useEffect(() => {
    const load = async () => {
      if (!isOpen || !ticketId) return;
      try {
        setLoading(true);
        const data = await ticketsApi.get(ticketId);
        setTicket(data);
      } catch (e) {
        if (onError) onError();
      } finally {
        setLoading(false);
      }
    };
    load();
  }, [isOpen, ticketId, onError]);

  const handleSend = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!ticketId || !reply.trim()) return;
    try {
      setSending(true);
      await ticketsApi.reply(ticketId, reply.trim());
      setReply('');
      if (onReplySuccess) onReplySuccess();
      onClose();
    } catch (_e) {
      if (onError) onError();
    } finally {
      setSending(false);
    }
  };

  return (
    <Modal isOpen={isOpen} onClose={onClose} title="Support Ticket" size="lg">
      {loading ? (
        <div className="text-sm text-slate-500">Loading...</div>
      ) : ticket ? (
        <div className="space-y-5">
          <div className="rounded-xl border border-slate-200 p-4 bg-slate-50">
            <div className="text-sm font-semibold text-slate-800 mb-1">{ticket.name}</div>
            <div className="text-[12px] text-slate-500">{ticket.issue}</div>
          </div>

          <div className="space-y-3">
            <div className="text-sm font-semibold text-slate-800">Conversation</div>
            <div className="space-y-2 max-h-64 overflow-auto border border-slate-200 rounded-xl p-3">
              {ticket.messages.map((m: TicketMessage) => (
                <div key={m.id} className="text-sm">
                  <span className="font-medium text-slate-800">{m.sender}: </span>
                  <span className="text-slate-700">{m.text}</span>
                  <span className="text-[11px] text-slate-400 ml-2">{new Date(m.createdAt).toLocaleString()}</span>
                </div>
              ))}
            </div>
          </div>

          <form onSubmit={handleSend} className="space-y-3">
            <textarea
              value={reply}
              onChange={(e) => setReply(e.target.value)}
              rows={3}
              placeholder="Type your reply..."
              className="w-full px-3 py-2 border border-slate-200 rounded-xl focus:outline-none focus:ring-2 focus:ring-blue-500 focus:border-transparent resize-none"
            />
            <div className="flex gap-3">
              <button type="button" onClick={onClose} className="px-4 py-2 border border-slate-300 text-slate-700 rounded-xl hover:bg-slate-50">Close</button>
              <button type="submit" disabled={sending || !reply.trim()} className="px-4 py-2 bg-blue-600 text-white rounded-xl hover:bg-blue-700 disabled:opacity-60">
                {sending ? 'Sending...' : 'Send Reply'}
              </button>
            </div>
          </form>
        </div>
      ) : (
        <div className="text-sm text-slate-500">No ticket selected</div>
      )}
    </Modal>
  );
};


