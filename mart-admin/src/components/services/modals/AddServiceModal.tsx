import React, { useEffect, useState } from 'react';
import { Modal, Button } from '@/components/common';
import styles from './EditServiceModal.module.scss';

interface ServiceFormData {
  name: string;
  description: string;
  pricePerKg: string;
  durationHours: number;
  status: 'Active' | 'Inactive';
  categoryId: string;
}

interface AddServiceModalProps {
  isOpen: boolean;
  onClose: () => void;
  onSave: (data: ServiceFormData) => void;
  categories: Array<{ id: string; name: string }>;
}

export const AddServiceModal: React.FC<AddServiceModalProps> = ({
  isOpen,
  onClose,
  onSave,
  categories,
}) => {
  const [formData, setFormData] = useState<ServiceFormData>({
    name: '',
    description: '',
    pricePerKg: '',
    durationHours: 0,
    status: 'Active',
    categoryId: categories[0]?.id || '',
  });

  useEffect(() => {
    if (!isOpen) return;
    if (formData.categoryId) return;
    if (categories.length === 0) return;
    setFormData((prev) => ({ ...prev, categoryId: categories[0].id }));
  }, [categories, formData.categoryId, isOpen]);

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    onSave(formData);
    // Reset form after save
    setFormData({
      name: '',
      description: '',
      pricePerKg: '',
      durationHours: 0,
      status: 'Active',
      categoryId: categories[0]?.id || '',
    });
    onClose();
  };

  const handleChange = (
    field: keyof ServiceFormData,
    value: string | number
  ) => {
    setFormData((prev) => ({ ...prev, [field]: value }));
  };

  const handleClose = () => {
    // Reset form on close
    setFormData({
      name: '',
      description: '',
      pricePerKg: '',
      durationHours: 0,
      status: 'Active',
      categoryId: categories[0]?.id || '',
    });
    onClose();
  };

  return (
    <Modal isOpen={isOpen} onClose={handleClose} title="Add New Service" size="md">
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
          <label htmlFor="categoryId" className={styles.label}>
            Category
          </label>
          <select
            id="categoryId"
            className={styles.select}
            value={formData.categoryId}
            onChange={(e) => handleChange('categoryId', e.target.value)}
          >
            {categories.map((c) => (
              <option key={c.id} value={c.id}>
                {c.name}
              </option>
            ))}
          </select>
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
          <Button type="button" variant="secondary" onClick={handleClose}>
            Cancel
          </Button>
          <Button type="submit" variant="primary">
            Add Service
          </Button>
        </div>
      </form>
    </Modal>
  );
};

