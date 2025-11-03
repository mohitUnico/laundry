import React from 'react';
import styles from './Card.module.scss';

interface CardProps {
  children: React.ReactNode;
  title?: string;
  className?: string;
}

export const Card: React.FC<CardProps> = ({ children, title, className }) => {
  return (
    <div className={`${styles.card} ${className || ''}`}>
      {title && <div className={styles['card-header']}>{title}</div>}
      <div className={styles['card-body']}>{children}</div>
    </div>
  );
};
