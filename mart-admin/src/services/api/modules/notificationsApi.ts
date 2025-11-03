import { axiosInstance, API_ENDPOINTS } from '../config';

export interface SendNotificationPayload {
  title: string;
  message: string;
  audience: 'all' | 'active' | 'custom';
  recipients?: string[]; // optional when audience is custom
}

export const notificationsApi = {
  send: async (payload: SendNotificationPayload) => {
    const response = await axiosInstance.post(API_ENDPOINTS.NOTIFICATIONS.SEND, payload);
    return response.data;
  },
};


