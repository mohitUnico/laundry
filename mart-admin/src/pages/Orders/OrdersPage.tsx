import React, { useEffect } from 'react';
import { useOrders } from '@/hooks/api';
import { Card, Loader, StatusBadge } from '@/components/common';
import './OrdersPage.module.scss';

export const OrdersPage: React.FC = () => {
  const { orders, loading, error, fetchOrders } = useOrders();

  useEffect(() => {
    fetchOrders();
  }, [fetchOrders]);

  if (loading) return <Loader />;
  if (error) return <div>Error: {error}</div>;

  return (
    <div className="orders-page">
      <h1>Orders</h1>
      <Card>
        <div className="orders-table">
          {orders.length === 0 ? (
            <p>No orders found</p>
          ) : (
            <table>
              <thead>
                <tr>
                  <th>Order ID</th>
                  <th>Customer</th>
                  <th>Status</th>
                  <th>Amount</th>
                  <th>Date</th>
                </tr>
              </thead>
              <tbody>
                {orders.map((order) => (
                  <tr key={order.orderId}>
                    <td>{order.orderId}</td>
                    <td>{order.customerName}</td>
                    <td>
                      <StatusBadge status={order.orderStatus} variant="info" />
                    </td>
                    <td>₹{order.totalAmount}</td>
                    <td>{new Date(order.createdAt).toLocaleDateString()}</td>
                  </tr>
                ))}
              </tbody>
            </table>
          )}
        </div>
      </Card>
    </div>
  );
};
