import { IUser } from '@/interfaces';

export interface AuthContextType {
  user: IUser | null;
  loading: boolean;
  completeLogin: (user: IUser, token: string) => void;
  logout: () => void;
  updateProfile: (updates: ProfileUpdateInput) => void;
}

export interface ProfileUpdateInput {
  firstName?: string;
  lastName?: string;
  email?: string;
  role?: string;
}
