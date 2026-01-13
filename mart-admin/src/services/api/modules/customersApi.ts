import { axiosInstance, API_ENDPOINTS } from '../config';

type ApiEnvelope<T> = {
  success: boolean;
  data: T;
  message?: string;
};

// Admin Customer Management Types
export type AdminCustomerContact = {
  email: string;
  phone: string | null;
};

export type AdminCustomerPrimaryAddress = {
  addressId: string;
  label: string;
  fullAddress: string;
  latitude: number | null;
  longitude: number | null;
  isDefault: boolean;
};

export type AdminCustomerActions = {
  can_view: boolean;
  can_message: boolean;
};

export type AdminCustomer = {
  customerId: string;
  name: string;
  contact: AdminCustomerContact;
  primaryAddress: AdminCustomerPrimaryAddress | null;
  totalOrdersCount: number;
  rating: number | null;
  actions: AdminCustomerActions;
  createdAt?: string | null; // Optional - backend selects it but may not include in response
};

export type AdminCustomerPagination = {
  page: number;
  limit: number;
  total: number;
  total_pages: number;
  has_next: boolean;
  has_prev: boolean;
};

export type AdminCustomersListResponse = {
  customers: AdminCustomer[];
  pagination: AdminCustomerPagination;
};

export type AdminCustomerSummary = {
  totalCustomers: number;
  activeCustomers: number;
  averageOrdersPerCustomer: number;
};

export type GetCustomersParams = {
  page?: number;
  limit?: number;
  search?: string;
  from?: string; // ISO date string
  to?: string; // ISO date string
  isActive?: boolean;
};

export type CreateCustomerParams = {
  fullName: string;
  email: string;
  phone?: string | null;
  address?: string | null;
  addressLabel?: string;
  latitude?: number | null;
  longitude?: number | null;
};

export const customersApi = {
  /**
   * Get admin customers list with pagination and filters
   * GET /api/v1/admin/customers
   */
  getCustomers: async (params?: GetCustomersParams) => {
    const response = await axiosInstance.get<ApiEnvelope<AdminCustomersListResponse>>(
      API_ENDPOINTS.ADMIN_CUSTOMERS.LIST,
      { params }
    );
    return response.data;
  },

  /**
   * Get admin customer summary (KPIs)
   * GET /api/v1/admin/customers/summary
   */
  getCustomerSummary: async (params?: { from?: string; to?: string; isActive?: boolean }) => {
    const response = await axiosInstance.get<ApiEnvelope<AdminCustomerSummary>>(
      API_ENDPOINTS.ADMIN_CUSTOMERS.SUMMARY,
      { params }
    );
    return response.data;
  },

  /**
   * Create a new customer (admin only)
   * POST /api/v1/admin/customers
   */
  createCustomer: async (params: CreateCustomerParams) => {
    const response = await axiosInstance.post<ApiEnvelope<AdminCustomer>>(
      API_ENDPOINTS.ADMIN_CUSTOMERS.CREATE,
      params
    );
    return response.data;
  },

  /**
   * Get customer by ID (existing method for non-admin endpoints)
   */
  getCustomerById: async (customerId: string) => {
    const response = await axiosInstance.get(API_ENDPOINTS.CUSTOMERS.GET(customerId));
    return response.data;
  },
};
