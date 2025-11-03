import React from 'react';
import { Card, StatusBadge } from '@/components/common';
import './RecentOrders.module.scss';

interface RecentOrder {
  id: string;
  customer: string;
  amount: string;
  status: 'Pending' | 'In progress' | 'Delivered' | 'Out for delivery';
  time: string;
}

const MOCK: RecentOrder[] = [
  { id: 'ORD-2025-001', customer: 'John Williams', amount: '$45.99', status: 'In progress', time: '38 mins ago' },
  { id: 'ORD-2025-021', customer: 'Emma Davis', amount: '$89.50', status: 'In progress', time: '50 mins ago' },
  { id: 'ORD-2025-002', customer: 'Michael Brown', amount: '$32.00', status: 'Delivered', time: '1 hrs ago' },
  { id: 'ORD-2025-054', customer: 'Oliver Johnson', amount: '$65.00', status: 'Delivered', time: '1:15 hrs ago' },
];

export const RecentOrders: React.FC<{ items?: RecentOrder[] }> = ({ items }) => {
  const list = items || MOCK;
  return (
    <Card title="Recent Orders">
      <ul className="ro-list">
        {list.map((o) => (
          <li key={o.id} className="ro-item">
            <div className="id">{o.id}</div>
            <div className="amount">{o.amount}</div>
            <div className="status"><StatusBadge status={o.status} /></div>
            <div className="time">{o.time}</div>
            <div className="customer">{o.customer}</div>
          </li>
        ))}
      </ul>
    </Card>
  );
};


