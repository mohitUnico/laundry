import React from 'react';
import { Card } from '@/components/common';
import { ArrowUpRight } from 'lucide-react';
import './OrderStatusWidget.module.scss';

interface StatusItem {
  label: string;
  value: number;
  color: string;
}

interface OrderStatusWidgetProps {
  items?: StatusItem[];
  onStatusClick?: (status: string) => void;
}

const DEFAULT_ITEMS: StatusItem[] = [
  { label: 'Pending', value: 8, color: '#facc15' },
  { label: 'In progress', value: 15, color: '#60a5fa' },
  { label: 'Out for delivery', value: 12, color: '#22d3ee' },
  { label: 'Completed today', value: 34, color: '#34d399' },
];

export const OrderStatusWidget: React.FC<OrderStatusWidgetProps> = ({ items, onStatusClick }) => {
  const data = items || DEFAULT_ITEMS;

  const handleClick = (status: string) => {
    if (onStatusClick) {
      onStatusClick(status);
    }
  };

  return (
    <Card title="Order Status">
      <div className="order-status-grid">
        {data.map((s) => (
          <div 
            key={s.label} 
            className="status-tile"
            onClick={() => handleClick(s.label)}
          >
            <span className="dot" style={{ backgroundColor: s.color }} />
            <span className="label">{s.label}</span>
            <span className="value-container">
              <span className="value">{s.value}</span>
              {onStatusClick && (
                <button
                  onClick={(e) => {
                    e.stopPropagation();
                    handleClick(s.label);
                  }}
                  className="arrow-button"
                  aria-label={`View ${s.label} orders`}
                >
                  <ArrowUpRight size={16} />
                </button>
              )}
            </span>
          </div>
        ))}
      </div>
    </Card>
  );
};


