import { axiosInstance } from '../config';

type ApiEnvelope<T> = {
  success: boolean;
  data: T;
  message?: string;
};

export type AdminOrdersListItem = {
  order_number: string;
  created_at: string | null;
  updated_at: string | null;
  customer: {
    customer_id: string | null;
    name: string | null;
    address:
      | {
          address_id: string;
          label: string | null;
          full_address: string;
          latitude: number | string | null;
          longitude: number | string | null;
        }
      | null;
  };
  services: string[];
  amount: string | number | null;
  status: string | null;
  delivery_boy:
    | {
        staff_id: string;
        name: string;
        phone: string | null;
      }
    | null;
  estimated_delivery_time: {
    delivery_date: string | null;
    estimated_duration_minutes: number | null;
  };
  actions: {
    can_view: boolean;
    can_edit: boolean;
  };
};

export type AdminOrdersListResponse = {
  orders: AdminOrdersListItem[];
  pagination: {
    page: number;
    limit: number;
    total: number;
    total_pages: number;
    has_next: boolean;
    has_prev: boolean;
  };
};

export type AdminCustomersSummary = {
  totalCustomers: number;
  activeCustomers: number;
  averageOrdersPerCustomer: number;
};

export type AdminCustomersListItem = {
  customerId: string;
  name: string;
  contact: {
    email: string;
    phone: string | null;
  };
  primaryAddress:
    | {
        addressId: string;
        label: string;
        fullAddress: string;
        latitude: number | string;
        longitude: number | string;
        isDefault: boolean;
      }
    | null;
  totalOrdersCount: number;
  rating: number | null;
  actions: {
    can_view: boolean;
    can_message: boolean;
  };
};

export type AdminCustomersListResponse = {
  customers: AdminCustomersListItem[];
  pagination: {
    page: number;
    limit: number;
    total: number;
    total_pages: number;
    has_next: boolean;
    has_prev: boolean;
  };
};

export type AdminOrdersSummary = {
  pending: number;
  outForDelivery: number;
  inProgress: number;
  completedToday: number;
};

export const adminManagementApi = {
  getAdminOrdersSummary: async (params?: { from?: string; to?: string; completedDate?: string }) => {
    const response = await axiosInstance.get<ApiEnvelope<AdminOrdersSummary>>('/admin/orders/summary', {
      params,
    });
    return response.data;
  },

  getAdminOrders: async (params?: {
    status?: string;
    search?: string;
    from?: string;
    to?: string;
    completedDate?: string;
    page?: number;
    limit?: number;
  }) => {
    const response = await axiosInstance.get<ApiEnvelope<AdminOrdersListResponse>>('/admin/orders', {
      params,
    });
    return response.data;
  },

  getAdminCustomersSummary: async (params?: { from?: string; to?: string; isActive?: boolean }) => {
    const response = await axiosInstance.get<ApiEnvelope<AdminCustomersSummary>>('/admin/customers/summary', {
      params,
    });
    return response.data;
  },

  getAdminCustomers: async (params?: {
    from?: string;
    to?: string;
    isActive?: boolean;
    search?: string;
    page?: number;
    limit?: number;
  }) => {
    const response = await axiosInstance.get<ApiEnvelope<AdminCustomersListResponse>>('/admin/customers', {
      params,
    });
    return response.data;
  },
};


