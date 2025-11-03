import React, { useState, useEffect } from 'react';
import { Modal, Button } from '@/components/common';
import styles from './EditServiceModal.module.scss';

interface AddOnFormData {
  name: string;
  baseFee: string;
  status: 'Active' | 'Inactive';
}

interface AddOnModalProps {
  isOpen: boolean;
  onClose: () => void;
  addOn?: {
    id?: string;
    name?: string;
    fee?: string;
    status?: 'Active' | 'Inactive';
  };
  onSave: (data: AddOnFormData) => void;
  onDelete?: () => void;
}

export const AddOnModal: React.FC<AddOnModalProps> = ({
  isOpen,
  onClose,
  addOn,
  onSave,
  onDelete,
}) => {
  const [formData, setFormData] = useState<AddOnFormData>({
    name: addOn?.name || '',
    baseFee: addOn?.fee || '',
    status: addOn?.status || 'Active',
  });

  // Update form data when addOn prop changes
  useEffect(() => {
    if (isOpen) {
      if (addOn && (addOn.id || addOn.name)) {
        // Edit mode - load the add-on data
        setFormData({
          name: addOn.name || '',
          baseFee: addOn.fee || '',
          status: addOn.status || 'Active',
        });
      } else {
        // Add mode - clear the form
        setFormData({
          name: '',
          baseFee: '',
          status: 'Active',
        });
      }
    }
  }, [addOn, isOpen]);

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    onSave(formData);
    // Reset form after save
    setFormData({
      name: '',
      baseFee: '',
      status: 'Active',
    });
    onClose();
  };

  const handleChange = (
    field: keyof AddOnFormData,
    value: string
  ) => {
    setFormData((prev) => ({ ...prev, [field]: value }));
  };

  const handleClose = () => {
    // Reset form on close
    setFormData({
      name: '',
      baseFee: '',
      status: 'Active',
    });
    onClose();
  };

  const handleDelete = () => {
    if (window.confirm('Are you sure you want to delete this add-on service?')) {
      onDelete?.();
      onClose();
    }
  };

  const isEditMode = !!addOn?.id || !!addOn?.name;

  return (
    <Modal isOpen={isOpen} onClose={handleClose} title={isEditMode ? "Edit Add-on Service" : "Add Add-on Service"} size="sm">
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
          <label htmlFor="baseFee" className={styles.label}>
            Base Fee
          </label>
          <input
            id="baseFee"
            type="text"
            className={styles.input}
            value={formData.baseFee}
            onChange={(e) => handleChange('baseFee', e.target.value)}
            placeholder="$0.00"
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
          <div className="flex-1">
            {isEditMode && onDelete && (
              <Button type="button" variant="danger" onClick={handleDelete}>
                Delete
              </Button>
            )}
          </div>
          <div className="flex gap-3">
            <Button type="button" variant="secondary" onClick={handleClose}>
              Cancel
            </Button>
            <Button type="submit" variant="primary">
              {isEditMode ? 'Save Changes' : 'Add Service'}
            </Button>
          </div>
        </div>
      </form>
    </Modal>
  );
};

