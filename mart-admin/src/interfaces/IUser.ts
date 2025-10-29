import { UserRole } from '../enums';

export interface IUser {
  userId: string;
  martId: string;
  name: string;
  email: string;
  role: UserRole;
  profilePhoto?: string;
  createdAt: string;
}
