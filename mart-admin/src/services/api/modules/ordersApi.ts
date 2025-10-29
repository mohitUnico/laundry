import { axiosInstance, API_ENDPOINTS } from '../config';
import { IOrder } from '@/interfaces';

export const ordersApi = {
  getOrders: async (params?: Record<string, any>) => {
    const response = await axiosInstance.get(API_ENDPOINTS.ORDERS.LIST, { params });
    return response.data;
  },

  getOrderById: async (orderId: string): Promise<IOrder> => {
    const response = await axiosInstance.get(API_ENDPOINTS.ORDERS.GET(orderId));
    return response.data.order;
  },

  updateOrderStatus: async (orderId: string, status: string) => {
    const response = await axiosInstance.patch(API_ENDPOINTS.ORDERS.UPDATE_STATUS(orderId), {
      status,
    });
    return response.data;
  },
};
