import { axiosInstance } from '../config';

type ApiEnvelope<T> = {
  success: boolean;
  data: T;
  message?: string;
};

// -----------------------------------------------------------------------------
// Mart dashboard (mart scoped): /api/v1/dashboard/*
// NOTE: Backend reads optional current_timestamp from request body, but for GET
// requests we rely on the default timestamp behavior (no body sent).
// -----------------------------------------------------------------------------

export type MartDashboardMonthlyOverview = {
  total_revenue: string;
  percentage_increase_total_revenue: number;
  total_orders: number;
  percentage_increase_total_orders: number;
  new_customers: number;
  percentage_increase_new_customers: number;
  avg_delivery_time: number;
  percentage_increase_avg_delivery_time: number;
};

export type MartDashboardDayOverview = {
  pending_orders: number;
  in_progress: number;
  out_for_delivery: number;
  completed_today: number;
};

export type MartDashboardRevenueTrendPoint = {
  label: string;
  total_revenue: number;
  total_orders: number;
};

export type MartDashboardRevenueTrend = {
  range: '7days' | '7weeks' | '7months';
  start_date: string;
  end_date: string;
  total_revenue: number;
  total_orders: number;
  data: MartDashboardRevenueTrendPoint[];
};

export type MartDashboardRecentOrder = {
  order_id: string;
  customer_name: string;
  order_price: number;
  status: string;
  duration_ago: string;
};

export type MartDashboardRecentOrders = {
  mart_id: string;
  count: number;
  data: MartDashboardRecentOrder[];
};

export type MartDashboardTopPerformer = {
  delivery_staff_name: string;
  total_deliveries: number;
  overall_rating: number;
};

export type MartDashboardTopPerformers = {
  top_performers: MartDashboardTopPerformer[];
};

export type MartDashboardCustomerSatisfaction = {
  overall: number;
  five_stars: number;
  four_stars: number;
  less_than_three: number;
};

export type AdminDashboardSummary = {
  totalRevenue: number;
  totalOrders: number;
  newCustomers: number;
  averageDeliveryTime: number;
};

export type AdminDashboardOrderStatus = {
  pending: number;
  inProgress: number;
  outForDelivery: number;
  completedToday: number;
};

export type AdminDashboardRevenueTrendPoint = {
  date: string | null; // YYYY-MM-DD
  totalRevenue: number;
  totalOrders: number;
  averageOrderValue: number;
};

export type AdminDashboardRecentOrder = {
  orderNumber: string;
  customerName: string | null;
  amount: string; // backend sometimes returns string
  status: string | null;
  deliveryStaffName?: string | null;
  timeElapsedSeconds: number | null;
  createdAt: string | null;
};

export type AdminDashboardDeliveryAnalytics = {
  metrics: {
    todayAvgMinutes: number;
    todayDeltaMinutes: number;
    weekAvgMinutes: number;
    weekDeltaMinutes: number;
    monthAvgMinutes: number;
    monthDeltaMinutes: number;
  };
  recentDeliveries: Array<{
    orderId: string;
    customerName: string | null;
    durationMinutes: number | null;
    status: 'On Time' | 'Delayed' | 'Early';
    completedAt: string | null;
  }>;
};

export type AdminDashboardLateDeliveries = {
  count: number;
  lateDeliveries: Array<{
    orderId: string;
    customerName: string | null;
    customerEmail: string | null;
    customerPhone: string | null;
    orderValue: string | number | null;
    scheduledTime: string | null;
    currentStatus: string | null;
    delayMinutes: number | null;
    pickupAddress: { label: string | null; fullAddress: string } | null;
    deliveryAddress: { label: string | null; fullAddress: string } | null;
    deliveryPartner:
      | {
          name: string;
          phone: string | null;
          vehicleNumber: string | null;
          deliveryStatus: string | null;
        }
      | null;
  }>;
};

export type AdminDashboardTopPerformer = {
  deliveryStaffName: string;
  totalDeliveries: number;
  rating: number;
};

export type AdminDashboardCustomerSatisfaction = {
  overallPercentage: number;
  distribution: {
    fiveStar: number;
    fourStar: number;
    lessThanThree: number;
  };
};

export const dashboardApi = {
  // ---------------------------------------------------------------------------
  // Mart dashboard (mart scoped): /api/v1/dashboard/*
  // ---------------------------------------------------------------------------
  getMonthlyOverview: async () => {
    const response = await axiosInstance.get<ApiEnvelope<MartDashboardMonthlyOverview>>(
      '/dashboard/monthly-overview'
    );
    return response.data;
  },

  getDayOverview: async () => {
    const response = await axiosInstance.get<ApiEnvelope<MartDashboardDayOverview>>('/dashboard/day-overview');
    return response.data;
  },

  getRevenueTrend: async (params?: { range?: '7days' | '7weeks' | '7months' }) => {
    const response = await axiosInstance.get<ApiEnvelope<MartDashboardRevenueTrend>>('/dashboard/revenue-trend', {
      params,
    });
    return response.data;
  },

  getRecentOrders: async (params?: { limit?: number }) => {
    const response = await axiosInstance.get<ApiEnvelope<MartDashboardRecentOrders>>('/dashboard/recent-orders', {
      params,
    });
    return response.data;
  },

  getTopPerformers: async (params?: { limit?: number }) => {
    const response = await axiosInstance.get<ApiEnvelope<MartDashboardTopPerformers>>('/dashboard/top-performers', {
      params,
    });
    return response.data;
  },

  getCustomerSatisfaction: async () => {
    const response = await axiosInstance.get<ApiEnvelope<MartDashboardCustomerSatisfaction>>(
      '/dashboard/customer-satisfaction'
    );
    return response.data;
  },

  // ---------------------------------------------------------------------------
  // Admin dashboard (global): /api/v1/admin/dashboard/*
  // ---------------------------------------------------------------------------
  getAdminSummary: async (params?: { from?: string; to?: string }) => {
    const response = await axiosInstance.get<ApiEnvelope<AdminDashboardSummary>>('/admin/dashboard/summary', {
      params,
    });
    return response.data;
  },

  getAdminOrderStatus: async (params?: { date?: string }) => {
    const response = await axiosInstance.get<ApiEnvelope<AdminDashboardOrderStatus>>('/admin/dashboard/order-status', {
      params,
    });
    return response.data;
  },

  getAdminRevenueTrend: async (params?: { range?: '7d' | '30d' }) => {
    const response = await axiosInstance.get<ApiEnvelope<AdminDashboardRevenueTrendPoint[]>>(
      '/admin/dashboard/revenue-trend',
      {
        params,
      }
    );
    return response.data;
  },

  getAdminRecentOrders: async (params?: { limit?: number }) => {
    const response = await axiosInstance.get<ApiEnvelope<AdminDashboardRecentOrder[]>>(
      '/admin/dashboard/recent-orders',
      {
        params,
      }
    );
    return response.data;
  },

  getAdminTopPerformers: async (params?: { limit?: number }) => {
    const response = await axiosInstance.get<ApiEnvelope<AdminDashboardTopPerformer[]>>(
      '/admin/dashboard/top-performers',
      {
        params,
      }
    );
    return response.data;
  },

  getAdminCustomerSatisfaction: async () => {
    const response = await axiosInstance.get<ApiEnvelope<AdminDashboardCustomerSatisfaction>>(
      '/admin/dashboard/customer-satisfaction'
    );
    return response.data;
  },

  getAdminDeliveryAnalytics: async (params?: { limit?: number }) => {
    const response = await axiosInstance.get<ApiEnvelope<AdminDashboardDeliveryAnalytics>>(
      '/admin/dashboard/delivery-analytics',
      { params }
    );
    return response.data;
  },

  getAdminLateDeliveries: async (params?: { limit?: number }) => {
    const response = await axiosInstance.get<ApiEnvelope<AdminDashboardLateDeliveries>>(
      '/admin/dashboard/late-deliveries',
      { params }
    );
    return response.data;
  },
};


