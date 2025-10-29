import React from 'react';
import { IOrder } from '@/interfaces';
import { StatusBadge } from '@/components/common';

interface OrderCardProps {
  order: IOrder;
  onViewDetails?: (orderId: string) => void;
}

export const OrderCard: React.FC<OrderCardProps> = ({ order, onViewDetails }) => {
  return (
    <div
      style={{
        background: 'white',
        borderRadius: '8px',
        padding: '16px',
        boxShadow: '0 1px 3px rgba(0,0,0,0.1)',
        cursor: 'pointer',
      }}
      onClick={() => onViewDetails?.(order.orderId)}
    >
      <div style={{ display: 'flex', justifyContent: 'space-between', marginBottom: '12px' }}>
        <span style={{ fontWeight: 600 }}>{order.orderId}</span>
        <StatusBadge status={order.orderStatus} variant="info" />
      </div>
      <div>
        <div>Customer: {order.customerName}</div>
        <div>Amount: ₹{order.totalAmount}</div>
        <div>Date: {new Date(order.createdAt).toLocaleDateString()}</div>
      </div>
    </div>
  );
};
