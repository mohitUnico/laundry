import React, { useState, useEffect } from 'react';
import { Modal, Button } from '@/components/common';
import styles from './EditServiceModal.module.scss';

interface ServiceFormData {
  name: string;
  description: string;
  pricePerKg: string;
  durationHours: number;
  status: 'Active' | 'Inactive';
}

interface EditServiceModalProps {
  isOpen: boolean;
  onClose: () => void;
  service?: {
    name: string;
    description?: string;
    pricePerKg?: string;
    durationHours?: number;
    status?: 'Active' | 'Inactive';
  };
  onSave: (data: ServiceFormData) => void;
}

export const EditServiceModal: React.FC<EditServiceModalProps> = ({
  isOpen,
  onClose,
  service,
  onSave,
}) => {
  const [formData, setFormData] = useState<ServiceFormData>({
    name: service?.name || '',
    description: service?.description || '',
    pricePerKg: service?.pricePerKg || '',
    durationHours: service?.durationHours || 0,
    status: service?.status || 'Active',
  });

  // Update form data when service prop changes
  useEffect(() => {
    if (service && isOpen) {
      setFormData({
        name: service.name || '',
        description: service.description || '',
        pricePerKg: service.pricePerKg || '',
        durationHours: service.durationHours || 0,
        status: service.status || 'Active',
      });
    }
  }, [service, isOpen]);

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    onSave(formData);
    onClose();
  };

  const handleChange = (
    field: keyof ServiceFormData,
    value: string | number
  ) => {
    setFormData((prev) => ({ ...prev, [field]: value }));
  };

  return (
    <Modal isOpen={isOpen} onClose={onClose} title="Edit Service" size="md">
      <form onSubmit={handleSubmit} className={styles.form}>
        <div className={styles.formGroup}>
          <label htmlFor="name" className={styles.label}>
            Service Name
          </label>
          <input
            id="name"
            type="text"
            className={styles.input}
            value={formData.name}
            onChange={(e) => handleChange('name', e.target.value)}
            required
          />
        </div>

        <div className={styles.formGroup}>
          <label htmlFor="description" className={styles.label}>
            Description
          </label>
          <textarea
            id="description"
            className={styles.textarea}
            value={formData.description}
            onChange={(e) => handleChange('description', e.target.value)}
            rows={3}
            required
          />
        </div>

        <div className={styles.formGroup}>
          <label htmlFor="pricePerKg" className={styles.label}>
            Price per kg
          </label>
          <input
            id="pricePerKg"
            type="text"
            className={styles.input}
            value={formData.pricePerKg}
            onChange={(e) => handleChange('pricePerKg', e.target.value)}
            placeholder="$0.00"
            required
          />
        </div>

        <div className={styles.formGroup}>
          <label htmlFor="durationHours" className={styles.label}>
            Duration (hours)
          </label>
          <input
            id="durationHours"
            type="number"
            className={styles.input}
            value={formData.durationHours}
            onChange={(e) => handleChange('durationHours', parseInt(e.target.value) || 0)}
            min="1"
            required
          />
        </div>

        <div className={styles.formGroup}>
          <label htmlFor="status" className={styles.label}>
            Status
          </label>
          <select
            id="status"
            className={styles.select}
            value={formData.status}
            onChange={(e) => handleChange('status', e.target.value as 'Active' | 'Inactive')}
          >
            <option value="Active">Active</option>
            <option value="Inactive">Inactive</option>
          </select>
        </div>

        <div className={styles.actions}>
          <Button type="button" variant="secondary" onClick={onClose}>
            Cancel
          </Button>
          <Button type="submit" variant="primary">
            Save Changes
          </Button>
        </div>
      </form>
    </Modal>
  );
};

