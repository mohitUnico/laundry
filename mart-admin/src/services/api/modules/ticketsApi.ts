// Frontend-only mock tickets API. Replace with real HTTP calls later.

export type TicketStatus = 'open' | 'in_progress' | 'resolved';

export interface TicketSummary {
  id: string;
  name: string;
  issue: string;
  status: TicketStatus;
  updatedAt: string;
}

export interface TicketMessage {
  id: string;
  sender: 'Customer' | 'Support';
  text: string;
  createdAt: string;
}

export interface TicketDetail extends TicketSummary {
  messages: TicketMessage[];
}

const seed: TicketDetail[] = [
  {
    id: 't1',
    name: 'Sarah Johnson',
    issue: 'Order not delivered',
    status: 'open',
    updatedAt: new Date(Date.now() - 30 * 60 * 1000).toISOString(),
    messages: [
      { id: 'm1', sender: 'Customer', text: 'My order is still not delivered.', createdAt: new Date(Date.now() - 90 * 60 * 1000).toISOString() },
      { id: 'm2', sender: 'Support', text: 'We are checking with the delivery partner.', createdAt: new Date(Date.now() - 70 * 60 * 1000).toISOString() },
    ],
  },
  {
    id: 't2',
    name: 'Michael Brown',
    issue: 'Payment issue',
    status: 'in_progress',
    updatedAt: new Date(Date.now() - 2 * 60 * 60 * 1000).toISOString(),
    messages: [
      { id: 'm1', sender: 'Customer', text: 'Payment was deducted twice.', createdAt: new Date(Date.now() - 5 * 60 * 60 * 1000).toISOString() },
    ],
  },
  {
    id: 't3',
    name: 'Emma Wilson',
    issue: 'Question about services',
    status: 'resolved',
    updatedAt: new Date(Date.now() - 2 * 60 * 60 * 1000).toISOString(),
    messages: [
      { id: 'm1', sender: 'Customer', text: 'Do you offer express service?', createdAt: new Date(Date.now() - 10 * 60 * 60 * 1000).toISOString() },
      { id: 'm2', sender: 'Support', text: 'Yes, available at an extra charge.', createdAt: new Date(Date.now() - 9 * 60 * 60 * 1000).toISOString() },
    ],
  },
];

const storageKey = 'mock_tickets_v1';

const load = (): TicketDetail[] => {
  const raw = localStorage.getItem(storageKey);
  if (!raw) {
    localStorage.setItem(storageKey, JSON.stringify(seed));
    return seed;
  }
  try {
    return JSON.parse(raw);
  } catch {
    return seed;
  }
};

const save = (data: TicketDetail[]) => localStorage.setItem(storageKey, JSON.stringify(data));

export const ticketsApi = {
  list: async (): Promise<TicketSummary[]> => {
    const data = load();
    // Simulate latency
    await new Promise((r) => setTimeout(r, 150));
    return data
      .map(({ messages, ...rest }) => rest)
      .sort((a, b) => new Date(b.updatedAt).getTime() - new Date(a.updatedAt).getTime());
  },
  get: async (id: string): Promise<TicketDetail> => {
    const data = load();
    await new Promise((r) => setTimeout(r, 150));
    const t = data.find((x) => x.id === id);
    if (!t) throw new Error('Not found');
    return t;
  },
  reply: async (id: string, text: string): Promise<void> => {
    const data = load();
    await new Promise((r) => setTimeout(r, 200));
    const idx = data.findIndex((x) => x.id === id);
    if (idx === -1) throw new Error('Not found');
    const now = new Date().toISOString();
    const current = data[idx]! as TicketDetail;
    data[idx] = {
      ...current,
      updatedAt: now,
      status: current.status === 'resolved' ? 'resolved' : 'in_progress',
      messages: [
        ...current.messages,
        { id: `m${current.messages.length + 1}`, sender: 'Support', text, createdAt: now },
      ],
    };
    save(data);
  },
};


