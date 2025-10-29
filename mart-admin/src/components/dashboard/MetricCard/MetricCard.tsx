import React from 'react';
import { Card } from '@/components/common';

interface MetricCardProps {
  title: string;
  value: string | number;
  subtitle?: string;
}

export const MetricCard: React.FC<MetricCardProps> = ({ title, value, subtitle }) => {
  return (
    <Card>
      <h3 style={{ fontSize: '14px', color: '#64748b', marginBottom: '8px' }}>{title}</h3>
      <div style={{ fontSize: '32px', fontWeight: 700, color: '#1e293b' }}>{value}</div>
      {subtitle && <div style={{ fontSize: '12px', color: '#94a3b8' }}>{subtitle}</div>}
    </Card>
  );
};
