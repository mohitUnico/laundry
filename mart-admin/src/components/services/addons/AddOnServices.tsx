import React, { useState } from 'react';
import { Card, Button, StatusBadge } from '@/components/common';
import { EditServiceModal } from '../modals/EditServiceModal';
import styles from './AddOnServices.module.scss';

interface AddOnItem {
  name: string;
  description?: string;
  baseFee: string;
  pricePerKg?: string;
  durationHours?: number;
  status?: 'Active' | 'Inactive';
}

interface AddOnServicesProps {
  items: AddOnItem[];
}

export const AddOnServices: React.FC<AddOnServicesProps> = ({ items }) => {
  const [isModalOpen, setIsModalOpen] = useState(false);
  const [selectedService, setSelectedService] = useState<AddOnItem | null>(null);

  const handleEdit = (service: AddOnItem) => {
    setSelectedService(service);
    setIsModalOpen(true);
  };

  const handleCloseModal = () => {
    setIsModalOpen(false);
    setSelectedService(null);
  };

  const handleSave = (formData: {
    name: string;
    description: string;
    pricePerKg: string;
    durationHours: number;
    status: 'Active' | 'Inactive';
  }) => {
    console.log('Saving service:', formData);
    // TODO: Implement actual save logic with API call
  };

  return (
    <>
      <Card className={styles.wrapper} title="Add-on Services">
        <div className={styles.list}>
          {items.map((it) => (
            <div key={it.name} className={styles.row}>
              <div className={styles.meta}>
                <div className={styles.name}>{it.name}</div>
                <div className={styles.fee}>Base fee — {it.baseFee}</div>
              </div>
              <div className={styles.actions}>
                <StatusBadge
                  status={it.status || 'Active'}
                  variant={(it.status || 'Active') === 'Active' ? 'success' : 'warning'}
                />
                <Button size="medium" onClick={() => handleEdit(it)}>
                  Edit
                </Button>
              </div>
            </div>
          ))}
        </div>
      </Card>

      <EditServiceModal
        isOpen={isModalOpen}
        onClose={handleCloseModal}
        service={selectedService || undefined}
        onSave={handleSave}
      />
    </>
  );
};


