import { axiosInstance, API_ENDPOINTS } from '../config';
import { ApiResponse, ClothesServiceRecord, ServiceCategoryRecord } from '@/types';

const cleanParams = <T extends Record<string, any>>(params?: T): T | undefined => {
  if (!params) return undefined;
  const entries = Object.entries(params).filter(([, v]) => v !== undefined);
  return entries.length ? (Object.fromEntries(entries) as T) : undefined;
};

export const clothesApi = {
  listServiceCategories: async (params?: { isActive?: boolean }): Promise<ServiceCategoryRecord[]> => {
    const response = await axiosInstance.get<ApiResponse<ServiceCategoryRecord[]>>(
      API_ENDPOINTS.CLOTHES.SERVICE_CATEGORIES.LIST,
      { params: cleanParams(params) }
    );
    return response.data.data;
  },

  listServices: async (params?: { categoryId?: string; isActive?: boolean }): Promise<ClothesServiceRecord[]> => {
    const response = await axiosInstance.get<ApiResponse<ClothesServiceRecord[]>>(API_ENDPOINTS.CLOTHES.SERVICES.LIST, {
      params: cleanParams(params),
    });
    return response.data.data;
  },

  createService: async (payload: {
    categoryId: string;
    serviceName: string;
    description?: string | null;
    basePrice: number;
    perKgPrice?: number | null;
    estimatedHours: number;
    iconUrl?: string | null;
    isActive?: boolean;
    displayOrder?: number;
  }): Promise<ClothesServiceRecord> => {
    const response = await axiosInstance.post<ApiResponse<ClothesServiceRecord>>(API_ENDPOINTS.CLOTHES.SERVICES.CREATE, payload);
    return response.data.data;
  },

  updateService: async (
    serviceId: string,
    payload: {
      serviceName?: string;
      description?: string | null;
      basePrice?: number;
      perKgPrice?: number | null;
      estimatedHours?: number;
      iconUrl?: string | null;
      isActive?: boolean;
      displayOrder?: number;
      categoryId?: string;
    }
  ): Promise<ClothesServiceRecord> => {
    const response = await axiosInstance.put<ApiResponse<ClothesServiceRecord>>(API_ENDPOINTS.CLOTHES.SERVICES.UPDATE(serviceId), payload);
    return response.data.data;
  },

  deleteService: async (serviceId: string): Promise<void> => {
    await axiosInstance.delete<ApiResponse<null>>(API_ENDPOINTS.CLOTHES.SERVICES.DELETE(serviceId));
  },
};

