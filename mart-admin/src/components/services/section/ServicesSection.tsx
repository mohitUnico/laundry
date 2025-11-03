import React from 'react';
import styles from './ServicesSection.module.scss';

interface ServicesSectionProps {
  title: string;
  children: React.ReactNode;
  columns?: 2 | 3;
}

export const ServicesSection: React.FC<ServicesSectionProps> = ({ title, children, columns = 2 }) => {
  return (
    <section className={styles.section}>
      <h3 className={styles.title}>{title}</h3>
      <div className={styles.grid} style={{ gridTemplateColumns: `repeat(${columns}, minmax(0, 1fr))` }}>
        {children}
      </div>
    </section>
  );
};


