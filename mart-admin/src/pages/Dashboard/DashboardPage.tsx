import React from 'react';
import { Card } from '@/components/common';
import './DashboardPage.module.scss';

export const DashboardPage: React.FC = () => {
  return (
    <div className="dashboard-page">
      <h1>Dashboard</h1>
      <div className="dashboard-grid">
        <Card title="Total Orders">
          <div className="metric">
            <span className="metric-value">142</span>
            <span className="metric-label">This month</span>
          </div>
        </Card>
        <Card title="Revenue">
          <div className="metric">
            <span className="metric-value">₹45,230</span>
            <span className="metric-label">This month</span>
          </div>
        </Card>
        <Card title="Customers">
          <div className="metric">
            <span className="metric-value">87</span>
            <span className="metric-label">Active</span>
          </div>
        </Card>
        <Card title="Delivery Staff">
          <div className="metric">
            <span className="metric-value">12</span>
            <span className="metric-label">Active</span>
          </div>
        </Card>
      </div>
    </div>
  );
};
