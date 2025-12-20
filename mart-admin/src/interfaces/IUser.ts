export interface IUser {
  id: string;
  name: string | null;
  email: string | null;
  phone: string | null;
  createdAt: string;
  updatedAt: string;
  role?: string | null;
}
