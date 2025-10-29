import { useState, useCallback } from 'react';
import { ordersApi } from '@/services';
import { IOrder } from '@/interfaces';

export const useOrders = () => {
  const [orders, setOrders] = useState<IOrder[]>([]);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);

  const fetchOrders = useCallback(async (filters?: any) => {
    setLoading(true);
    setError(null);
    try {
      const response = await ordersApi.getOrders(filters);
      setOrders(response.orders);
    } catch (err: any) {
      setError(err.message || 'Failed to fetch orders');
    } finally {
      setLoading(false);
    }
  }, []);

  const updateOrderStatus = useCallback(
    async (orderId: string, status: string) => {
      try {
        await ordersApi.updateOrderStatus(orderId, status);
        setOrders((prev) =>
          prev.map((order) => (order.orderId === orderId ? { ...order, orderStatus: status as any } : order))
        );
      } catch (err: any) {
        setError(err.message);
        throw err;
      }
    },
    []
  );

  return { orders, loading, error, fetchOrders, updateOrderStatus };
};
