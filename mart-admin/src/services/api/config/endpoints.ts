export const API_ENDPOINTS = {
  AUTH: {
    LOGIN: '/auth/login',
    LOGOUT: '/auth/logout',
    ME: '/auth/me',
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
  DASHBOARD: {
    METRICS: '/dashboard/metrics',
  },
};
