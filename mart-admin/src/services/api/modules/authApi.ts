import { axiosInstance, API_ENDPOINTS } from '../config';
import { IUser } from '@/interfaces';

interface VerifyOtpPayload {
  identifier: string;
  otp: string;
}

export type IdentifierType = 'email' | 'phone';

export interface SendPortalOtpResponse {
  success: boolean;
  message: string;
  data: {
    identifier: string;
    identifierType: IdentifierType;
    isRegistered: boolean;
    expiresIn: number;
  };
}

export type VerifyPortalOtpRegisteredData = {
  isRegistered: true;
  token: string;
  user: IUser;
};

export type VerifyPortalOtpPendingData = {
  isRegistered: false;
  sessionToken: string;
  sessionExpiresIn: number;
  identifier: string;
  identifierType: IdentifierType;
};

export type VerifyPortalOtpData = VerifyPortalOtpRegisteredData | VerifyPortalOtpPendingData;

export interface VerifyPortalOtpResponse {
  success: boolean;
  message: string;
  data: VerifyPortalOtpData;
}

export interface CompletePortalRegistrationResponse {
  success: boolean;
  message: string;
  data: {
    token: string;
    mart: {
      martId: string;
      martName: string;
      contactEmail: string;
      contactPhone: string | null;
      address: string | null;
      profileImageUrl: string | null;
    };
    owner: {
      userId: string;
      fullName: string;
      email: string | null;
      phone: string | null;
      role: string;
      martId: string;
    };
  };
}

export interface CompleteRegistrationPayload {
  sessionToken: string;
  martData: {
    martName: string;
    martEmail: string;
    martContact: string;
    address?: string;
    profileImageUrl?: string;
    martCoordinates?: {
      latitude: number;
      longitude: number;
    };
  };
  ownerData: {
    ownerName: string;
    ownerPhone?: string;
    ownerEmail: string;
  };
}

export const authApi = {
  sendOtp: async (identifier: string) => {
    const response = await axiosInstance.post<SendPortalOtpResponse>(API_ENDPOINTS.AUTH.SEND_OTP, {
      identifier,
    });
    return response.data;
  },

  verifyOtp: async ({ identifier, otp }: VerifyOtpPayload) => {
    const response = await axiosInstance.post<VerifyPortalOtpResponse>(
      API_ENDPOINTS.AUTH.VERIFY_OTP,
      { identifier, otp }
    );
    return response.data;
  },

  // Owner flow: Send OTP to mart email for verification
  sendMartEmailOtp: async (payload: { sessionToken: string; martEmail: string }) => {
    const response = await axiosInstance.post(
      '/auth/owner/verify-mart-email/send-otp',
      payload
    );
    return response.data as { success: boolean; message: string };
  },

  // Owner flow: Verify mart email OTP
  verifyMartEmailOtp: async (payload: { sessionToken: string; martEmail: string; otp: string }) => {
    const response = await axiosInstance.post(
      '/auth/owner/verify-mart-email/verify-otp',
      payload
    );
    return response.data as { success: boolean; message: string };
  },

  completePortalRegistration: async (payload: CompleteRegistrationPayload) => {
    const response = await axiosInstance.post<CompletePortalRegistrationResponse>(
      '/auth/owner/complete-registration',
      payload
    );
    return response.data;
  },

  logout: async () => {
    const response = await axiosInstance.post(API_ENDPOINTS.AUTH.LOGOUT);
    return response.data;
  },
};
