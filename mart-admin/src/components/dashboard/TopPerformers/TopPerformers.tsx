import React from 'react';
import { Card } from '@/components/common';
import './TopPerformers.module.scss';

interface Performer {
  name: string;
  deliveries: number;
  rating: number;
}

const MOCK: Performer[] = [
  { name: 'Nina Patel', deliveries: 421, rating: 4.9 },
  { name: 'Marcus Chen', deliveries: 374, rating: 4.9 },
  { name: 'Lisa Rodriguez', deliveries: 330, rating: 4.8 },
  { name: 'Arman Cera', deliveries: 290, rating: 4.9 },
];

export const TopPerformers: React.FC<{ items?: Performer[] }> = ({ items }) => {
  const list = items || MOCK;
  return (
    <Card>
      <div className="tp-header">Top Performers</div>
      <ul className="tp-list">
        {list.map((p) => (
          <li key={p.name} className="tp-item">
            <div className="avatar">{p.name.charAt(0)}</div>
            <div className="meta">
              <div className="name">{p.name}</div>
              <div className="sub">{p.deliveries} Deliveries</div>
            </div>
            <div className="rating">⭐ {p.rating.toFixed(1)}</div>
          </li>
        ))}
      </ul>
    </Card>
  );
};


