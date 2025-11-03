import React, { useMemo, useState } from 'react';
import { OrderStatus } from '@/enums';
import { SummaryCard } from '@/components/orders/SummaryCard';
import { FilterBar } from '@/components/orders/FilterBar';
import { OrderTable } from '@/components/orders/OrderTable';
import type { OrderRowData } from '@/components/orders/OrderRow';

export const OrdersPage: React.FC = () => {
  const [search, setSearch] = useState('');
  const [statusFilter, setStatusFilter] = useState<string>('all');
  const [dateFilter, setDateFilter] = useState<string | null>(null);

  // Sample orders with different dates for testing
  const orders = [
    // Today's orders
    { orderId: 'ORD-2025-001', customerName: 'John Williams', orderStatus: OrderStatus.PICKUP, totalAmount: 49.99, createdAt: new Date().toISOString() },
    { orderId: 'ORD-2025-002', customerName: 'Emma Davis', orderStatus: OrderStatus.IN_PROCESS, totalAmount: 59.99, createdAt: new Date().toISOString() },
    { orderId: 'ORD-2025-003', customerName: 'Michal Chen', orderStatus: OrderStatus.PICKUP, totalAmount: 49.99, createdAt: new Date().toISOString() },
    { orderId: 'ORD-2025-004', customerName: 'Wednesday Adams', orderStatus: OrderStatus.OUT_FOR_DELIVERY, totalAmount: 30.99, createdAt: new Date().toISOString() },
    { orderId: 'ORD-2025-005', customerName: 'Xavier', orderStatus: OrderStatus.DELIVERED, totalAmount: 45.99, createdAt: new Date().toISOString() },
    { orderId: 'ORD-2025-006', customerName: 'Martin Luther', orderStatus: OrderStatus.DELIVERED, totalAmount: 49.99, createdAt: new Date().toISOString() },
    // November 3, 2025 orders
    { orderId: 'ORD-2025-101', customerName: 'Sarah Johnson', orderStatus: OrderStatus.PICKUP, totalAmount: 65.99, createdAt: new Date('2025-11-03T10:30:00').toISOString() },
    { orderId: 'ORD-2025-102', customerName: 'Michael Brown', orderStatus: OrderStatus.IN_PROCESS, totalAmount: 55.99, createdAt: new Date('2025-11-03T11:15:00').toISOString() },
    { orderId: 'ORD-2025-103', customerName: 'Emily Wilson', orderStatus: OrderStatus.OUT_FOR_DELIVERY, totalAmount: 79.99, createdAt: new Date('2025-11-03T14:20:00').toISOString() },
    { orderId: 'ORD-2025-104', customerName: 'David Lee', orderStatus: OrderStatus.DELIVERED, totalAmount: 89.99, createdAt: new Date('2025-11-03T16:45:00').toISOString() },
    { orderId: 'ORD-2025-105', customerName: 'Jennifer Taylor', orderStatus: OrderStatus.DELIVERED, totalAmount: 95.99, createdAt: new Date('2025-11-03T18:00:00').toISOString() },
    // Other dates
    { orderId: 'ORD-2025-201', customerName: 'Robert Smith', orderStatus: OrderStatus.PICKUP, totalAmount: 35.99, createdAt: new Date('2025-11-01T09:00:00').toISOString() },
    { orderId: 'ORD-2025-202', customerName: 'Lisa Anderson', orderStatus: OrderStatus.IN_PROCESS, totalAmount: 42.99, createdAt: new Date('2025-11-02T10:30:00').toISOString() },
    { orderId: 'ORD-2025-301', customerName: 'James White', orderStatus: OrderStatus.DELIVERED, totalAmount: 58.99, createdAt: new Date('2025-11-05T12:00:00').toISOString() },
  ];

  // Calculate counts dynamically from orders
  const kpis = useMemo(() => {
    const today = new Date();
    today.setHours(0, 0, 0, 0);

    const pending = orders.filter((o) => o.orderStatus === OrderStatus.PICKUP).length;
    const outForDelivery = orders.filter((o) => o.orderStatus === OrderStatus.OUT_FOR_DELIVERY).length;
    const inProgress = orders.filter((o) => o.orderStatus === OrderStatus.IN_PROCESS).length;
    const completedToday = orders.filter((o) => {
      const orderDate = new Date(o.createdAt);
      orderDate.setHours(0, 0, 0, 0);
      return o.orderStatus === OrderStatus.DELIVERED && orderDate.getTime() === today.getTime();
    }).length;

    return [
      { label: 'Pending', value: pending, status: OrderStatus.PICKUP },
      { label: 'Out for Delivery', value: outForDelivery, status: OrderStatus.OUT_FOR_DELIVERY },
      { label: 'In Progress', value: inProgress, status: OrderStatus.IN_PROCESS },
      { label: 'Completed Today', value: completedToday, status: 'completed_today' },
    ];
  }, [orders]);

  const filtered = useMemo(() => {
    const term = search.toLowerCase();
    return orders.filter((o) => {
      // Search filter - matches order number or customer name
      const matchesTerm = !term || o.orderId.toLowerCase().includes(term) || o.customerName.toLowerCase().includes(term);
      
      // Date filter - matches orders created in the selected month/year
      let matchesDate = true;
      if (dateFilter) {
        // Parse the date filter (YYYY-MM-DD format from date input)
        const dateParts = dateFilter.split('-');
        if (dateParts.length === 3) {
          const filterYear = Number(dateParts[0]);
          const filterMonth = Number(dateParts[1]);
          
          if (!isNaN(filterYear) && !isNaN(filterMonth)) {
            // Parse the order creation date
            const orderDate = new Date(o.createdAt);
            
            // Compare by month and year only (not specific day)
            matchesDate = 
              orderDate.getFullYear() === filterYear &&
              orderDate.getMonth() === (filterMonth - 1); // JavaScript months are 0-indexed
          }
        }
      }
      
      // Status filter
      let matchesStatus = true;
      if (statusFilter === 'all') {
        matchesStatus = true;
      } else if (statusFilter === 'completed_today') {
        const today = new Date();
        today.setHours(0, 0, 0, 0);
        const orderDate = new Date(o.createdAt);
        orderDate.setHours(0, 0, 0, 0);
        matchesStatus = o.orderStatus === OrderStatus.DELIVERED && orderDate.getTime() === today.getTime();
      } else {
        matchesStatus = o.orderStatus === (statusFilter as any);
      }
      
      return matchesTerm && matchesDate && matchesStatus;
    });
  }, [orders, search, statusFilter, dateFilter]);

  const handleKpiClick = (status: string) => {
    setStatusFilter(status);
  };

  const rows: OrderRowData[] = filtered.map((o) => {
    let delivery: OrderRowData['deliveryBoy'] = 'Assign';
    switch (o.orderId) {
      case 'ORD-2025-001':
        delivery = { name: 'Marcus Chen' };
        break;
      case 'ORD-2025-002':
        delivery = { name: 'Adam Richard' };
        break;
      case 'ORD-2025-004':
        delivery = { name: 'Lisa Mennu' };
        break;
      case 'ORD-2025-005':
        delivery = { name: 'Aish Bachchan' };
        break;
      case 'ORD-2025-006':
        delivery = { name: 'Shikkar Dha' };
        break;
      case 'ORD-2025-101':
      case 'ORD-2025-103':
        delivery = { name: 'Tom Wilson' };
        break;
      case 'ORD-2025-102':
        delivery = { name: 'Anna Martinez' };
        break;
      case 'ORD-2025-104':
      case 'ORD-2025-105':
        delivery = { name: 'Chris Garcia' };
        break;
      case 'ORD-2025-201':
        delivery = { name: 'Mike Johnson' };
        break;
      case 'ORD-2025-202':
        delivery = { name: 'Sarah Connor' };
        break;
      case 'ORD-2025-301':
        delivery = { name: 'John Doe' };
        break;
    }

    return {
      id: o.orderId,
      customer: o.customerName,
      address: '123 Oak Street',
      services: 'Wash & Fold, Express',
      amount: `$${o.totalAmount.toFixed(2)}`,
      status:
        o.orderStatus === OrderStatus.PICKUP
          ? 'Picked Up'
          : o.orderStatus === OrderStatus.IN_PROCESS
          ? 'In Progress'
          : o.orderStatus === OrderStatus.OUT_FOR_DELIVERY
          ? 'Out for Delivery'
          : 'Delivered',
      deliveryBoy: delivery,
      eta: '12:00 PM',
    };
  });

  return (
    <div className="min-h-screen bg-slate-50 p-6">
      <div className="mx-auto max-w-[1200px]">
        <div className="mb-6">
          <h1 className="text-2xl font-semibold text-slate-900">Order Management</h1>
          <p className="mt-1 text-sm text-slate-500">Track and manage all customer orders.</p>
        </div>

        <div className="grid grid-cols-12 gap-6">
          {kpis.map((k) => {
            const isSelected = statusFilter === k.status;
            return (
              <div key={k.label} className="col-span-12 sm:col-span-6 lg:col-span-3">
                <SummaryCard 
                  title={k.label} 
                  value={k.value} 
                  onClick={() => handleKpiClick(isSelected ? 'all' : k.status)}
                  isSelected={isSelected}
                />
              </div>
            );
          })}
        </div>

        <div className="mt-6 rounded-2xl border border-slate-200 bg-white p-4 shadow-md">
          <FilterBar
            search={search}
            onSearchChange={setSearch}
            status={statusFilter}
            onStatusChange={setStatusFilter}
            dateFilter={dateFilter}
            onDateChange={setDateFilter}
          />
        </div>

        <div className="mt-6">
          <OrderTable rows={rows} />
        </div>
      </div>
    </div>
  );
};
