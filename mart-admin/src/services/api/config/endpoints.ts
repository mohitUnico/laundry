export const API_ENDPOINTS = {
  AUTH: {
    SEND_OTP: '/auth/send-otp',
    VERIFY_OTP: '/auth/verify-otp',
    COMPLETE_REGISTRATION: '/auth/portal/complete-registration',
    LOGOUT: '/auth/logout',
  },
  ORDERS: {
    LIST: '/orders',
    GET: (id: string) => `/orders/${id}`,
    CREATE: '/orders',
    UPDATE: (id: string) => `/orders/${id}`,
    UPDATE_STATUS: (id: string) => `/orders/${id}/status`,
  },
  CUSTOMERS: {
    LIST: '/customers',
    GET: (id: string) => `/customers/${id}`,
  },
  DELIVERY_STAFF: {
    LIST: '/delivery-staff',
    GET: (id: string) => `/delivery-staff/${id}`,
    CREATE: '/delivery-staff',
  },
  SERVICES: {
    LIST: '/services',
    GET: (id: string) => `/services/${id}`,
  },
  CLOTHES: {
    SERVICE_CATEGORIES: {
      LIST: '/clothes/service-categories',
      CREATE: '/clothes/service-categories',
      UPDATE: (id: string) => `/clothes/service-categories/${id}`,
      DELETE: (id: string) => `/clothes/service-categories/${id}`,
    },
    SERVICES: {
      LIST: '/clothes/services',
      CREATE: '/clothes/services',
      UPDATE: (id: string) => `/clothes/services/${id}`,
      DELETE: (id: string) => `/clothes/services/${id}`,
    },
  },
  DASHBOARD: {
    // Mart dashboard (mart scoped)
    MONTHLY_OVERVIEW: '/dashboard/monthly-overview',
    DAY_OVERVIEW: '/dashboard/day-overview',
    REVENUE_TREND: '/dashboard/revenue-trend',
    RECENT_ORDERS: '/dashboard/recent-orders',
    CUSTOMER_SATISFACTION: '/dashboard/customer-satisfaction',
    TOP_PERFORMERS: '/dashboard/top-performers',

    // Admin dashboard (global)
    ADMIN: {
      SUMMARY: '/admin/dashboard/summary',
      ORDER_STATUS: '/admin/dashboard/order-status',
      REVENUE_TREND: '/admin/dashboard/revenue-trend',
      RECENT_ORDERS: '/admin/dashboard/recent-orders',
      TOP_PERFORMERS: '/admin/dashboard/top-performers',
      CUSTOMER_SATISFACTION: '/admin/dashboard/customer-satisfaction',
    },
  },
  ADMIN_CUSTOMERS: {
    LIST: '/admin/customers',
    SUMMARY: '/admin/customers/summary',
    CREATE: '/admin/customers',
  },
  NOTIFICATIONS: {
    SEND: '/notifications/send',
  },
  SETTINGS: {
    SAVE: '/settings',
    SERVICE_AREAS: {
      LIST: '/settings/service-areas',
      CREATE: '/settings/service-areas',
      DELETE: (id: string) => `/settings/service-areas/${id}`,
    },
    TEAM: {
      SUMMARY: '/settings/team/summary',
      MEMBERS: '/settings/team/members',
      MEMBER: (id: string) => `/settings/team/members/${id}`,
    },
    SECURITY: {
      CHANGE_PASSWORD: '/settings/security/change-password',
      ACTIVITY_LOG: '/settings/security/activity-log',
    },
  },
};
