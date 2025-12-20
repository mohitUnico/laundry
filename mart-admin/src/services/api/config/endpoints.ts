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
  DASHBOARD: {
    METRICS: '/dashboard/metrics',
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
