import React from 'react';
import { useAuth } from '@/hooks';
import './Header.module.scss';

export const Header: React.FC = () => {
  const { user, logout } = useAuth();

  return (
    <header className="header">
      <div className="header-left">
        <h1>Admin Panel</h1>
      </div>
      <div className="header-right">
        <div className="user-menu">
          <span className="user-name">{user?.name || 'Admin'}</span>
          <button className="logout-btn" onClick={logout}>
            Logout
          </button>
        </div>
      </div>
    </header>
  );
};
