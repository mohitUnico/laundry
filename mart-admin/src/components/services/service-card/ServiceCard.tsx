import React from 'react';
import { Card, Button, StatusBadge } from '@/components/common';
import styles from './ServiceCard.module.scss';

interface ServiceCardProps {
  name: string;
  description?: string;
  pricePerKg?: string;
  baseFee?: string;
  durationHours?: number;
  status?: 'Active' | 'Inactive';
  onEdit?: () => void;
}

export const ServiceCard: React.FC<ServiceCardProps> = ({
  name,
  description,
  pricePerKg,
  baseFee,
  durationHours,
  status = 'Active',
  onEdit,
}) => {
  return (
    <Card className={styles.card}>
      <div className={styles.headerRow}>
        <div>
          <div className={styles.title}>{name}</div>
          {description && <div className={styles.subtitle}>{description}</div>}
        </div>
        <StatusBadge status={status} variant={status === 'Active' ? 'success' : 'warning'} />
      </div>

      <div className={styles.metaRow}>
        {pricePerKg && (
          <div className={styles.metaItem}>
            <span className={styles.metaLabel}>Price per kg</span>
            <span className={styles.metaValue}>{pricePerKg}</span>
          </div>
        )}
        {baseFee && (
          <div className={styles.metaItem}>
            <span className={styles.metaLabel}>Base fee</span>
            <span className={styles.metaValue}>{baseFee}</span>
          </div>
        )}
        {typeof durationHours === 'number' && (
          <div className={styles.metaItem}>
            <span className={styles.metaLabel}>Duration</span>
            <span className={styles.metaValue}>{durationHours} hrs</span>
          </div>
        )}
      </div>

      <div className={styles.actionsRow}>
        <Button variant="primary" size="medium" className={styles.fullWidthBtn} onClick={onEdit}>
          Edit
        </Button>
        <span className={styles.rightKnob} />
      </div>
    </Card>
  );
};


