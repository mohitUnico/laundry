import { axiosInstance, API_ENDPOINTS } from '../config';

export const customersApi = {
  getCustomers: async (params?: Record<string, any>) => {
    const response = await axiosInstance.get(API_ENDPOINTS.CUSTOMERS.LIST, { params });
    return response.data;
  },

  getCustomerById: async (customerId: string) => {
    const response = await axiosInstance.get(API_ENDPOINTS.CUSTOMERS.GET(customerId));
    return response.data;
  },
};
