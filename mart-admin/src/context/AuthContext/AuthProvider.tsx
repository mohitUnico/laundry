import React, { useState, useEffect } from 'react';
import { AuthContext } from './AuthContext';
import { IUser } from '@/interfaces';
import { authApi } from '@/services';
import { ProfileUpdateInput } from './AuthContext.types';
import { combineName, splitName } from '@/utils/helpers';

const AUTH_USER_KEY = 'authUser';
const AUTH_TOKEN_KEY = 'authToken';

export const AuthProvider: React.FC<{ children: React.ReactNode }> = ({ children }) => {
  const [user, setUser] = useState<IUser | null>(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    try {
      const storedUser = localStorage.getItem(AUTH_USER_KEY);
      if (storedUser) {
        const parsedUser: IUser = JSON.parse(storedUser);
        setUser({ ...parsedUser, role: parsedUser.role ?? 'Admin' });
      }
    } catch (error) {
      console.error('Failed to parse stored auth user', error);
      localStorage.removeItem(AUTH_USER_KEY);
    } finally {
      setLoading(false);
    }
  }, []);

  const completeLogin = (authUser: IUser, token: string) => {
    const normalizedUser: IUser = {
      ...authUser,
      role: authUser.role ?? 'Admin',
    };

    localStorage.setItem(AUTH_TOKEN_KEY, token);
    localStorage.setItem(AUTH_USER_KEY, JSON.stringify(normalizedUser));
    setUser(normalizedUser);
  };

  const logout = () => {
    void authApi.logout().catch(() => null);
    localStorage.removeItem(AUTH_TOKEN_KEY);
    localStorage.removeItem(AUTH_USER_KEY);
    setUser(null);
  };

  const updateProfile = (updates: ProfileUpdateInput) => {
    setUser((prev) => {
      if (!prev) {
        return prev;
      }

      const { firstName: currentFirst, lastName: currentLast } = splitName(prev.name);

      const incomingFirst = updates.firstName !== undefined ? updates.firstName.trim() : undefined;
      const incomingLast = updates.lastName !== undefined ? updates.lastName.trim() : undefined;
      const incomingEmail = updates.email !== undefined ? updates.email.trim() : undefined;
      const incomingRole = updates.role !== undefined ? updates.role.trim() : undefined;

      const nextFirstName = incomingFirst !== undefined ? incomingFirst : currentFirst;
      const nextLastName = incomingLast !== undefined ? incomingLast : currentLast;

      const nextUser: IUser = {
        ...prev,
        name: combineName(nextFirstName, nextLastName) || prev.name,
        email: incomingEmail !== undefined ? incomingEmail || null : prev.email,
        role: incomingRole ?? prev.role ?? 'Admin',
        updatedAt: new Date().toISOString(),
      };

      localStorage.setItem(AUTH_USER_KEY, JSON.stringify(nextUser));
      return nextUser;
    });
  };

  return (
    <AuthContext.Provider value={{ user, loading, completeLogin, logout, updateProfile }}>
      {children}
    </AuthContext.Provider>
  );
};
