import { axiosInstance, API_ENDPOINTS } from '../config';
import { IUser } from '@/interfaces';

export const authApi = {
  login: async (email: string, password: string) => {
    const response = await axiosInstance.post(API_ENDPOINTS.AUTH.LOGIN, { email, password });
    return response.data;
  },

  logout: async () => {
    const response = await axiosInstance.post(API_ENDPOINTS.AUTH.LOGOUT);
    return response.data;
  },

  getCurrentUser: async (): Promise<IUser> => {
    const response = await axiosInstance.get(API_ENDPOINTS.AUTH.ME);
    return response.data.user;
  },
};
