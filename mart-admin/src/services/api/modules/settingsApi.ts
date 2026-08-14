import { axiosInstance, API_ENDPOINTS } from '../config';

export interface ServiceArea {
  id: string;
  name: string;
}

export interface AdminTeamMember {
  staffId: string;
  fullName: string;
  email?: string | null;
  phone?: string | null;
  role: 'owner' | 'service_man' | 'collection_manager' | 'distribution_manager' | string;
  isActive: boolean;
  service?: any;
  createdAt: string;
  updatedAt: string;
}

export interface AdminTeamMembersGrouped {
  owner: AdminTeamMember[];
  service_men: AdminTeamMember[];
  collection_managers: AdminTeamMember[];
  distribution_managers: AdminTeamMember[];
}

export interface AdminCreateTeamMemberInput {
  fullName: string;
  email: string;
  phone?: string | null;
  role: 'owner' | 'service_man' | 'collection_manager' | 'distribution_manager';
  serviceId?: string | null;
  isActive?: boolean;
}

export interface SaveSettingsPayload {
  businessName: string;
  businessEmail: string;
  contactNumber: string;
  taxId: string;
  businessAddress: string;
  paymentMethods: {
    creditCard: boolean;
    debitCard: boolean;
    digitalWallets: boolean;
    cod: boolean;
    bankTransfer: boolean;
  };
  notifications: {
    newOrders: boolean;
    deliveryUpdates: boolean;
    customerMessages: boolean;
    systemAlerts: boolean;
  };
  serviceAreas: { id?: string; name: string }[];
  teamMembersAdded?: TeamMemberInput[];
}

export interface TeamSummary {
  owner: number;
  manager: number;
  cleaningStaff: number;
  deliveryBoys: number;
}

export interface TeamMemberInput {
  name: string;
  email?: string;
  phone?: string;
  role: 'owner' | 'manager' | 'cleaningStaff' | 'deliveryBoys';
}

export interface TeamMember extends TeamMemberInput {
  id: string;
}

export const settingsApi = {
  async getAdminTeamMembersGrouped(): Promise<AdminTeamMembersGrouped> {
    const res = await axiosInstance.get(API_ENDPOINTS.ADMIN_SETTINGS.TEAM_MEMBERS_GROUPED);
    const data = res.data?.data;
    return {
      owner: data?.owner ?? [],
      service_men: data?.service_men ?? [],
      collection_managers: data?.collection_managers ?? [],
      distribution_managers: data?.distribution_managers ?? [],
    };
  },

  async createAdminTeamMember(payload: AdminCreateTeamMemberInput): Promise<AdminTeamMember> {
    const res = await axiosInstance.post(API_ENDPOINTS.ADMIN_SETTINGS.TEAM_MEMBERS_GROUPED, payload);
    return res.data?.data;
  },

  async getServiceAreas(): Promise<ServiceArea[]> {
    const res = await axiosInstance.get(API_ENDPOINTS.SETTINGS.SERVICE_AREAS.LIST);
    // Expecting { serviceAreas: ServiceArea[] } or { data: ServiceArea[] }
    return res.data?.serviceAreas ?? res.data?.data ?? [];
  },

  async addServiceArea(name: string): Promise<ServiceArea> {
    const res = await axiosInstance.post(API_ENDPOINTS.SETTINGS.SERVICE_AREAS.CREATE, { name });
    // Expecting { serviceArea } or { data }
    return res.data?.serviceArea ?? res.data?.data;
  },

  async deleteServiceArea(id: string): Promise<void> {
    await axiosInstance.delete(API_ENDPOINTS.SETTINGS.SERVICE_AREAS.DELETE(id));
  },

  async saveSettings(payload: SaveSettingsPayload): Promise<void> {
    await axiosInstance.put(API_ENDPOINTS.SETTINGS.SAVE, payload);
  },

  async getTeamSummary(): Promise<TeamSummary> {
    const res = await axiosInstance.get(API_ENDPOINTS.SETTINGS.TEAM.SUMMARY);
    return (
      res.data?.teamSummary ?? res.data?.data ?? {
        owner: 1,
        manager: 3,
        cleaningStaff: 5,
        deliveryBoys: 8,
      }
    );
  },

  async addTeamMember(member: TeamMemberInput): Promise<void> {
    await axiosInstance.post(API_ENDPOINTS.SETTINGS.TEAM.MEMBERS, member);
  },

  async getTeamMembers(role: TeamMemberInput['role']): Promise<TeamMember[]> {
    const res = await axiosInstance.get(API_ENDPOINTS.SETTINGS.TEAM.MEMBERS, { params: { role } });
    return res.data?.members ?? res.data?.data ?? [];
  },

  async deleteTeamMember(memberId: string): Promise<void> {
    await axiosInstance.delete(API_ENDPOINTS.SETTINGS.TEAM.MEMBER(memberId));
  },

  async changePassword(currentPassword: string, newPassword: string): Promise<void> {
    await axiosInstance.post(API_ENDPOINTS.SETTINGS.SECURITY.CHANGE_PASSWORD, {
      currentPassword,
      newPassword,
    });
  },

  async getActivityLog(params?: { page?: number; limit?: number }): Promise<
    { id: string; action: string; at: string; ip?: string }[]
  > {
    const res = await axiosInstance.get(API_ENDPOINTS.SETTINGS.SECURITY.ACTIVITY_LOG, {
      params,
    });
    return (
      res.data?.logs ??
      res.data?.data ?? [
        { id: 'log-1', action: 'Logged in', at: new Date().toISOString(), ip: '127.0.0.1' },
        { id: 'log-2', action: 'Changed password', at: new Date(Date.now() - 3600000).toISOString() },
      ]
    );
  },
};


