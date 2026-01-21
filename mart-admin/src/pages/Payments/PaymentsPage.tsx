import React, { useMemo, useState } from 'react';
import { PaymentStatus, PaymentMethod } from '@/enums';
import { PaymentStatCard } from '@/components/payments/PaymentStatCard';
import { PaymentFilterBar } from '@/components/payments/PaymentFilterBar';
import { PaymentTable } from '@/components/payments/PaymentTable';
import type { PaymentRowData } from '@/components/payments/PaymentRow';

export const PaymentsPage: React.FC = () => {
  const [search, setSearch] = useState('');
  const [statusFilter, setStatusFilter] = useState<string>('all');
  const [methodFilter, setMethodFilter] = useState<string>('all');

  const transactions = [
    { 
      transactionId: 'TXN-2025-001', 
      orderId: 'ORD-2025-001',
      customerName: 'John Williams', 
      method: PaymentMethod.CARD,
      amount: 49.99, 
      status: PaymentStatus.COMPLETED, 
      date: '2025-01-15T10:30:00Z' 
    },
    { 
      transactionId: 'TXN-2025-002', 
      orderId: 'ORD-2025-002',
      customerName: 'Emma Davis', 
      method: PaymentMethod.COD,
      amount: 59.99, 
      status: PaymentStatus.PENDING, 
      date: '2025-01-15T11:45:00Z' 
    },
    { 
      transactionId: 'TXN-2025-003', 
      orderId: 'ORD-2025-003',
      customerName: 'Michal Chen', 
      method: PaymentMethod.UPI,
      amount: 49.99, 
      status: PaymentStatus.COMPLETED, 
      date: '2025-01-14T09:15:00Z' 
    },
    { 
      transactionId: 'TXN-2025-004', 
      orderId: 'ORD-2025-004',
      customerName: 'Wednesday Adams', 
      method: PaymentMethod.WALLET,
      amount: 30.99, 
      status: PaymentStatus.COMPLETED, 
      date: '2025-01-14T14:20:00Z' 
    },
    { 
      transactionId: 'TXN-2025-005', 
      orderId: 'ORD-2025-005',
      customerName: 'Xavier', 
      method: PaymentMethod.CARD,
      amount: 45.99, 
      status: PaymentStatus.FAILED, 
      date: '2025-01-13T16:00:00Z' 
    },
    { 
      transactionId: 'TXN-2025-006', 
      orderId: 'ORD-2025-006',
      customerName: 'Martin Luther', 
      method: PaymentMethod.COD,
      amount: 49.99, 
      status: PaymentStatus.COMPLETED, 
      date: '2025-01-13T10:00:00Z' 
    },
    { 
      transactionId: 'TXN-2025-007', 
      orderId: 'ORD-2025-007',
      customerName: 'Sarah Connor', 
      method: PaymentMethod.CARD,
      amount: 75.50, 
      status: PaymentStatus.REFUNDED, 
      date: '2025-01-12T12:30:00Z' 
    },
  ];

  const filtered = useMemo(() => {
    const term = search.toLowerCase();
    return transactions.filter((t) => {
      const matchesTerm = !term || 
        t.transactionId.toLowerCase().includes(term) || 
        t.orderId.toLowerCase().includes(term) ||
        t.customerName.toLowerCase().includes(term);
      const matchesStatus = statusFilter === 'all' || t.status === statusFilter;
      const matchesMethod = methodFilter === 'all' || t.method === methodFilter;
      return matchesTerm && matchesStatus && matchesMethod;
    });
  }, [transactions, search, statusFilter, methodFilter]);

  const kpis = [
    { label: 'Total Revenue', value: '₹12,845', icon: '💰' },
    { label: 'Pending Payments', value: '₹59.99', icon: '⏳' },
    { label: 'Failed Transactions', value: 1, icon: '❌' },
    { label: 'Avg. Transaction', value: '₹48.62', icon: '📊' },
  ];

  const rows: PaymentRowData[] = filtered.map((t) => {
    let methodLabel: string;
    switch (t.method) {
      case PaymentMethod.CARD:
        methodLabel = 'Card';
        break;
      case PaymentMethod.COD:
        methodLabel = 'COD';
        break;
      case PaymentMethod.UPI:
        methodLabel = 'UPI';
        break;
      case PaymentMethod.WALLET:
        methodLabel = 'Wallet';
        break;
      default:
        methodLabel = 'Unknown';
    }

    let statusLabel: string;
    let statusColor: string;
    switch (t.status) {
      case PaymentStatus.COMPLETED:
        statusLabel = 'Completed';
        statusColor = 'bg-emerald-50 text-emerald-700';
        break;
      case PaymentStatus.PENDING:
        statusLabel = 'Pending';
        statusColor = 'bg-yellow-50 text-yellow-700';
        break;
      case PaymentStatus.FAILED:
        statusLabel = 'Failed';
        statusColor = 'bg-red-50 text-red-700';
        break;
      case PaymentStatus.REFUNDED:
        statusLabel = 'Refunded';
        statusColor = 'bg-blue-50 text-blue-700';
        break;
      default:
        statusLabel = 'Unknown';
        statusColor = 'bg-gray-50 text-gray-700';
    }

    return {
      id: t.transactionId,
      orderId: t.orderId,
      customer: t.customerName,
      method: methodLabel,
      amount: `₹${t.amount.toFixed(2)}`,
      status: statusLabel,
      statusColor,
      date: new Date(t.date).toLocaleDateString('en-IN', {
        day: '2-digit',
        month: 'short',
        year: 'numeric'
      }),
    };
  });

  return (
    <div className="w-full">
      <div className="mx-auto mt-1 sm:mt-2 w-full max-w-[1320px] rounded-2xl border border-slate-200 bg-white p-4 sm:p-6 md:p-7 shadow-sm space-y-4 sm:space-y-5 md:space-y-6 lg:space-y-8">
        {/* Header */}
        <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-3 sm:gap-4">
          <div>
            <div className="text-xl sm:text-2xl font-bold text-[#111827]">Payment Management</div>
            <div className="text-xs sm:text-sm text-slate-500 mt-1">Track and manage all payment transactions</div>
          </div>
          <button className="h-8 sm:h-9 px-4 sm:px-5 rounded-full bg-[#2B3AFF] hover:bg-[#253BFF] text-white text-xs sm:text-sm font-medium shadow-sm transition-colors w-full sm:w-auto">
            + Process Refund
          </button>
        </div>

        {/* Stats */}
        <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-3 sm:gap-4 md:gap-5 lg:gap-6 xl:gap-8">
          {kpis.map((kpi) => (
            <PaymentStatCard 
              key={kpi.label} 
              title={kpi.label} 
              value={kpi.value} 
              icon={kpi.icon}
            />
          ))}
        </div>

        {/* Filters */}
        <div className="bg-white rounded-xl sm:rounded-2xl p-4 sm:p-5 md:p-6 shadow-sm border border-slate-100">
          <PaymentFilterBar
            search={search}
            onSearchChange={setSearch}
            status={statusFilter}
            onStatusChange={setStatusFilter}
            method={methodFilter}
            onMethodChange={setMethodFilter}
          />
        </div>

        {/* Transaction Table */}
        <div className="bg-white rounded-xl sm:rounded-2xl shadow-sm border border-slate-100 overflow-hidden">
          <PaymentTable rows={rows} />
        </div>
      </div>
    </div>
  );
};

