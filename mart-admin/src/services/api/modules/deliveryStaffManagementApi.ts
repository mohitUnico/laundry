import { axiosInstance, API_ENDPOINTS } from '../config';

type ApiEnvelope<T> = {
  success: boolean;
  data: T;
  message?: string;
};

export type AdminPagination = {
  page: number;
  limit: number;
  total: number;
  totalPages: number;
};

export type AdminDeliveryStaffDocuments = {
  profileImageUrl: string | null;
  idProofType: string | null;
  idProofUrl: string | null;
  drivingLicenseUrl: string | null;
};

export type AdminDeliveryStaff = {
  staffId: string;
  fullName: string;
  email: string;
  phone: string | null;
  address: string | null;
  currentCoordinates: { latitude: string; longitude: string } | null;
  vehicleType: string | null;
  vehicleNumber: string | null;
  verificationStatus: 'pending' | 'verified' | 'rejected';
  isVerifiedByAdmin: boolean;
  isActive: boolean;
  averageRating: string | number | null;
  totalDeliveries?: number | null;
  documents: AdminDeliveryStaffDocuments;
  createdAt: string;
  updatedAt: string;
};

export type AdminDeliveryStaffListResponse = {
  pagination: AdminPagination;
  deliveryStaffs: AdminDeliveryStaff[];
};

export type AdminDeliveryStaffSummary = {
  total_staffs: number;
  available: number;
  currently_delivering: number;
  average_rating: number;
};

export type AdminPendingVerificationsResponse = {
  pagination: AdminPagination;
  pendingVerifications: Array<
    Omit<AdminDeliveryStaff, 'currentCoordinates' | 'averageRating' | 'totalDeliveries'>
  >;
};

export type AdminOnlineDeliveryStaffShift = {
  shiftId: string;
  startedAt: string;
  lastLocationAt: string;
  lastLatitude: string;
  lastLongitude: string;
};

export type AdminOnlineDeliveryStaff = {
  staffId: string;
  fullName: string;
  email: string;
  phone: string | null;
  vehicleType: string | null;
  vehicleNumber: string | null;
  profileImageUrl: string | null;
  verificationStatus: 'pending' | 'verified' | 'rejected';
  isVerifiedByAdmin: boolean;
  isActive: boolean;
  shift: AdminOnlineDeliveryStaffShift;
};

export type AdminOnlineDeliveryStaffResponse = {
  pagination: AdminPagination;
  onlineDeliveryStaffs: AdminOnlineDeliveryStaff[];
};

export type GetDeliveryStaffListParams = {
  page?: number;
  limit?: number;
  verificationStatus?: 'pending' | 'verified' | 'rejected';
  isVerifiedByAdmin?: boolean;
  isActive?: boolean;
};

export const deliveryStaffManagementApi = {
  /**
   * Admin delivery staff list with pagination and filters
   * GET /api/v1/admin/delivery-staff
   */
  getDeliveryStaffs: async (params?: GetDeliveryStaffListParams) => {
    const response = await axiosInstance.get<ApiEnvelope<AdminDeliveryStaffListResponse>>(
      API_ENDPOINTS.ADMIN_DELIVERY_STAFF.LIST,
      { params }
    );
    return response.data;
  },

  /**
   * Admin delivery staff summary (KPIs)
   * GET /api/v1/admin/delivery-staff/staff-summary
   */
  getDeliveryStaffSummary: async () => {
    const response = await axiosInstance.get<ApiEnvelope<AdminDeliveryStaffSummary>>(
      API_ENDPOINTS.ADMIN_DELIVERY_STAFF.SUMMARY
    );
    return response.data;
  },

  /**
   * Admin pending delivery staff verifications
   * GET /api/v1/admin/delivery-staff/pending-verifications
   */
  getPendingVerifications: async (params?: { page?: number; limit?: number }) => {
    const response = await axiosInstance.get<ApiEnvelope<AdminPendingVerificationsResponse>>(
      API_ENDPOINTS.ADMIN_DELIVERY_STAFF.PENDING_VERIFICATIONS,
      { params }
    );
    return response.data;
  },

  /**
   * Admin online delivery staff list
   * GET /api/v1/admin/delivery-staff/online
   */
  getOnlineDeliveryStaffs: async (params?: { page?: number; limit?: number }) => {
    const response = await axiosInstance.get<ApiEnvelope<AdminOnlineDeliveryStaffResponse>>(
      API_ENDPOINTS.ADMIN_DELIVERY_STAFF.ONLINE,
      { params }
    );
    return response.data;
  },

  /**
   * Verify (approve) a delivery staff
   * PATCH /api/v1/admin/delivery-staff/:staffId/verify
   */
  verifyDeliveryStaff: async (staffId: string) => {
    const response = await axiosInstance.patch<ApiEnvelope<any>>(
      API_ENDPOINTS.ADMIN_DELIVERY_STAFF.VERIFY(staffId)
    );
    return response.data;
  },
};

