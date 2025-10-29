import React from 'react';
import './StatusBadge.module.scss';

interface StatusBadgeProps {
  status: string;
  variant?: 'success' | 'warning' | 'error' | 'info';
}

export const StatusBadge: React.FC<StatusBadgeProps> = ({ status, variant = 'info' }) => {
  return <span className={`status-badge status-badge-${variant}`}>{status}</span>;
};
