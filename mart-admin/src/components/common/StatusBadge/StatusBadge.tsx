import React from 'react';
import styles from './StatusBadge.module.scss';

interface StatusBadgeProps {
  status: string;
  variant?: 'success' | 'warning' | 'error' | 'info';
}

export const StatusBadge: React.FC<StatusBadgeProps> = ({ status, variant = 'info' }) => {
  return <span className={`${styles['status-badge']} ${styles[`status-badge-${variant}`]}`}>{status}</span>;
};
