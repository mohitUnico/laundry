import React from 'react';
import { Card } from '@/components/common';
import styles from './StatTile.module.scss';

interface StatTileProps {
  label: string;
  value: string | number;
  dotColor?: string;
}

export const StatTile: React.FC<StatTileProps> = ({ label, value, dotColor }) => {
  return (
    <Card className={styles.tile}>
      <div className={styles.labelRow}>
        <span className={styles.label}>{label}</span>
        {dotColor && <span className={styles.dot} style={{ background: dotColor }} />}
      </div>
      <div className={styles.value}>{value}</div>
    </Card>
  );
};


