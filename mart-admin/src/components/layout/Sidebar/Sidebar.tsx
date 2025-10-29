import React from 'react';
import { NavLink } from 'react-router-dom';
import { sidebarConfig } from './sidebarConfig';
import './Sidebar.module.scss';

export const Sidebar: React.FC = () => {
  return (
    <aside className="sidebar">
      <div className="sidebar-header">
        <h2>Laundry Mart</h2>
      </div>
      <nav className="sidebar-nav">
        {sidebarConfig.map((item) => (
          <NavLink
            key={item.path}
            to={item.path}
            className={({ isActive }) => `sidebar-item ${isActive ? 'active' : ''}`}
          >
            <span className="sidebar-item-icon">{item.icon}</span>
            <span className="sidebar-item-label">{item.label}</span>
          </NavLink>
        ))}
      </nav>
    </aside>
  );
};
