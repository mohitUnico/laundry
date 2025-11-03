import React, { useEffect, useState } from 'react';
import { NotificationStatCard } from '@/components/tw-ui/NotificationStatCard';
import { SendNotificationModal, SupportTicketModal } from '@/components/dashboard/modals';
import { Toast } from '@/components/common';
import { useToast } from '@/hooks/common/useToast';
import { ticketsApi, TicketSummary } from '@/services/api/modules/ticketsApi';

const RecentItem: React.FC<{ title: string; desc: string; time: string; to: string; status: string }> = ({ title, desc, time, to, status }) => (
  <div className="flex items-start justify-between p-3 rounded-lg border border-slate-200 bg-white">
    <div className="flex items-start gap-3">
      <div className="h-9 w-9 rounded-lg bg-indigo-50 text-indigo-600 flex items-center justify-center">🔔</div>
      <div>
        <div className="text-sm font-semibold text-slate-800">{title}</div>
        <div className="text-[12px] text-slate-500">{desc}</div>
        <div className="text-[12px] text-slate-500 mt-1">To: <span className="text-slate-700">{to}</span> <span className="text-emerald-600 ml-2">{status}</span></div>
      </div>
    </div>
    <div className="text-[12px] text-slate-400">{time}</div>
  </div>
);

const QuickSendBtn: React.FC<{ label: string; note: string; onClick: () => void }> = ({ label, note, onClick }) => (
  <button onClick={onClick} className="w-full text-left bg-white border border-slate-200 rounded-xl px-4 py-3 hover:bg-slate-50">
    <div className="text-sm font-semibold text-slate-800">{label}</div>
    <div className="text-[12px] text-slate-500">{note}</div>
  </button>
);

const TicketItem: React.FC<{ ticket: TicketSummary; onOpen: (id: string) => void }> = ({ ticket, onOpen }) => {
  const statusChip = {
    open: { text: 'Open', color: '#ef4444' },
    in_progress: { text: 'In progress', color: '#3b82f6' },
    resolved: { text: 'Resolved', color: '#10b981' },
  }[ticket.status];
  return (
    <button onClick={() => onOpen(ticket.id)} className="w-full text-left flex items-center justify-between p-3 rounded-lg border border-slate-200 bg-white hover:bg-slate-50">
      <div className="flex items-center gap-3">
        <div className="flex -space-x-2">
          <span className="h-7 w-7 rounded-full bg-slate-200 inline-block" />
          <span className="h-7 w-7 rounded-full bg-slate-300 inline-block" />
        </div>
        <div>
          <div className="text-sm font-semibold text-slate-800">{ticket.name}</div>
          <div className="text-[12px] text-slate-500">{ticket.issue}</div>
        </div>
      </div>
      <div className="flex items-center gap-3">
        <span className={`px-2 py-0.5 rounded text-[11px] border`} style={{ color: statusChip.color, borderColor: statusChip.color }}>{statusChip.text}</span>
        <div className="text-[12px] text-slate-400">{new Date(ticket.updatedAt).toLocaleTimeString()}</div>
      </div>
    </button>
  );
};

export const NotificationsPage: React.FC = () => {
  const [showSendModal, setShowSendModal] = useState(false);
  const [audiencePreset, setAudiencePreset] = useState<'all' | 'active' | 'custom'>('all');
  const { toast, showToast, hideToast } = useToast();
  const [tickets, setTickets] = useState<TicketSummary[]>([]);
  const [ticketModalId, setTicketModalId] = useState<string | null>(null);

  useEffect(() => {
    const loadTickets = async () => {
      try {
        const list = await ticketsApi.list();
        setTickets(list);
      } catch (e) {
        // optional toast
      }
    };
    loadTickets();
  }, []);

  const openSend = (aud: 'all' | 'active' | 'custom' = 'all') => {
    setAudiencePreset(aud);
    setShowSendModal(true);
  };

  return (
    <div className="min-h-screen bg-gray-50">
      <div className="max-w-[1280px] mx-auto px-4 py-6">
        <div className="flex items-center justify-between mb-4">
          <div>
            <div className="text-2xl font-semibold text-slate-900">Notification & Communication</div>
            <div className="text-[12px] text-slate-500">Send messages and manage communications</div>
          </div>
          <button onClick={() => openSend('all')} className="h-10 px-4 rounded-full bg-indigo-700 text-white font-semibold">🚀 Send Notification</button>
        </div>

        <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4 mb-6">
          <NotificationStatCard title="Total Sent" value={1247} sub="+12% this week" />
          <NotificationStatCard title="Delivered" value={1198} sub="96% delivery rate" />
          <NotificationStatCard title="Open Rate" value={'82%'} />
          <NotificationStatCard title="Active Chats" value={23} />
        </div>

        <div className="grid grid-cols-1 lg:grid-cols-[1fr_320px] gap-5">
          {/* Left Column */}
          <div className="space-y-5">
            <div className="bg-white rounded-2xl border border-slate-100 shadow-sm p-5">
              <div className="text-sm font-semibold text-slate-800 mb-3">Recent Notifications</div>
              <div className="space-y-3">
                <RecentItem title="Order Status Update" desc="Your order #ORD-2025-001 has been picked up" to="John Williams" status="Sent" time="2 mins ago" />
                <RecentItem title="Payment Received" desc="Payment of $9.90 received for order #ORD-2025-002" to="Emma Davis" status="Sent" time="10 mins ago" />
                <RecentItem title="Delivery Assignment" desc="New order #ORD-2025-003 has been assigned to you" to="Markus Chen" status="Sent" time="30 mins ago" />
              </div>
            </div>

            <div className="bg-white rounded-2xl border border-slate-100 shadow-sm p-5">
              <div className="text-sm font-semibold text-slate-800 mb-3">Support Tickets</div>
              <div className="space-y-3">
                {tickets.map((t) => (
                  <TicketItem key={t.id} ticket={t} onOpen={(id) => setTicketModalId(id)} />
                ))}
              </div>
            </div>
          </div>

          {/* Right Column */}
          <aside className="space-y-5">
            <div className="bg-white rounded-2xl border border-slate-100 shadow-sm p-5">
              <div className="text-sm font-semibold text-slate-800 mb-3">Quick Send</div>
              <div className="space-y-3">
                <QuickSendBtn onClick={() => openSend('all')} label="All Customers" note="Send to all customers" />
                <QuickSendBtn onClick={() => openSend('active')} label="Delivery Staff" note="Send to delivery team" />
                <QuickSendBtn onClick={() => openSend('active')} label="Active Orders" note="Customers with active orders" />
              </div>
            </div>

            <div className="rounded-2xl bg-indigo-700 text-white p-5 shadow-sm">
              <div className="text-sm font-semibold mb-1">Automated Notifications</div>
              <div className="text-[12px] text-indigo-100 mb-4">Set up automatic notifications for order updates, payments, and more</div>
              <button className="w-full bg-white text-indigo-700 font-semibold rounded-md py-2">Configure</button>
            </div>
          </aside>
        </div>
      </div>

      <SendNotificationModal
        isOpen={showSendModal}
        onClose={() => setShowSendModal(false)}
        initialAudience={audiencePreset}
        onSuccess={() => showToast('Notification sent successfully', 'success')}
        onError={() => showToast('Failed to send notification', 'error')}
      />

      <SupportTicketModal
        isOpen={!!ticketModalId}
        ticketId={ticketModalId}
        onClose={() => setTicketModalId(null)}
        onReplySuccess={() => showToast('Reply sent', 'success')}
        onError={() => showToast('Failed to send reply', 'error')}
      />

      <Toast
        message={toast.message}
        type={toast.type}
        isVisible={toast.isVisible}
        onClose={hideToast}
      />
    </div>
  );
};


