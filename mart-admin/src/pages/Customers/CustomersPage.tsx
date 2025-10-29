import React from 'react';
import { Card } from '@/components/common';

export const CustomersPage: React.FC = () => {
  return (
    <div className="customers-page">
      <h1>Customers</h1>
      <Card>
        <p>Customer list will be displayed here.</p>
      </Card>
    </div>
  );
};
