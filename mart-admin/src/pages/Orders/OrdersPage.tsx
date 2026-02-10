import React, { useEffect, useMemo, useState } from 'react';
import { useLocation } from 'react-router-dom';
import { SummaryCard } from '@/components/orders/SummaryCard';
import { FilterBar } from '@/components/orders/FilterBar';
import { OrderTable } from '@/components/orders/OrderTable';
import type { OrderRowData } from '@/components/orders/OrderRow';
import { adminManagementApi } from '@/services/api';
import { formatCurrency } from '@/utils/formatters';
import type { AdminOrdersListItem, AdminOrdersSummary } from '@/services/api/modules/adminManagementApi';
import { Modal } from '@/components/common';

export const OrdersPage: React.FC = () => {
  const location = useLocation();
  const initialSearch = useMemo(() => {
    const params = new URLSearchParams(location.search);
    return params.get('search') || '';
  }, [location.search]);

  const [search, setSearch] = useState(initialSearch);
  const [statusFilter, setStatusFilter] = useState<string>('all');
  const [dateFilter, setDateFilter] = useState<string | null>(null);

  const [apiOrders, setApiOrders] = useState<AdminOrdersListItem[]>([]);
  const [summary, setSummary] = useState<AdminOrdersSummary | null>(null);
  const [isLoading, setIsLoading] = useState<boolean>(false);
  const [error, setError] = useState<string | null>(null);

  const [selectedOrderId, setSelectedOrderId] = useState<string | null>(null);
  const [isDetailsOpen, setIsDetailsOpen] = useState(false);
  const [isEditOpen, setIsEditOpen] = useState(false);
  const [editStatus, setEditStatus] = useState<string>('');
  const [isSaving, setIsSaving] = useState(false);
  const [saveError, setSaveError] = useState<string | null>(null);

  const selectedOrder = useMemo(() => {
    if (!selectedOrderId) return null;
    return apiOrders.find((o) => o.order_number === selectedOrderId) || null;
  }, [apiOrders, selectedOrderId]);

  const monthRange = useMemo(() => {
    if (!dateFilter) return null;
    const [yearStr, monthStr] = dateFilter.split('-');
    const year = Number(yearStr);
    const month = Number(monthStr);
    if (!Number.isInteger(year) || !Number.isInteger(month) || month < 1 || month > 12) return null;

    const start = new Date(Date.UTC(year, month - 1, 1, 0, 0, 0, 0));
    const endExclusive = new Date(Date.UTC(year, month, 1, 0, 0, 0, 0));
    const endInclusive = new Date(endExclusive.getTime() - 1);
    return { from: start.toISOString(), to: endInclusive.toISOString() };
  }, [dateFilter]);

  const kpis = useMemo(() => {
    return [
      { label: 'Pending', value: summary?.pending ?? 0, status: 'pickup' },
      { label: 'Out for Delivery', value: summary?.outForDelivery ?? 0, status: 'out_for_delivery' },
      { label: 'In Progress', value: summary?.inProgress ?? 0, status: 'in_process' },
      { label: 'Completed', value: summary?.completedToday ?? 0, status: 'completed_today' },
    ];
  }, [summary]);

  const mapUiStatusToApiStatus = (uiStatus: string): string | undefined => {
    switch (uiStatus) {
      case 'pickup':
        // Backend "pending" bucket spans multiple early lifecycle statuses
        return 'placed,pickup_assigned,picked_up,received_by_collection,submitted_to_services';
      case 'in_process':
        return 'services_in_progress';
      case 'out_for_delivery':
        return 'out_for_delivery';
      case 'delivered':
        return 'delivered,closed';
      case 'ready':
        return 'services_completed';
      case 'completed_today':
        // Completed KPI card should show orders that were completed (delivered/closed)
        // on the selected day (or today when no date filter is chosen).
        return 'delivered,closed';
      default:
        return undefined;
    }
  };

  // Summary should not refetch on status changes (keeps the UI responsive).
  useEffect(() => {
    let isMounted = true;
    const run = async () => {
      try {
        const from = monthRange?.from;
        const to = monthRange?.to;

        const summaryRes = await adminManagementApi.getAdminOrdersSummary({
          from,
          to,
        });

        if (!isMounted) return;
        setSummary(summaryRes.data);
      } catch {
        // Non-blocking: orders list should still work even if summary fails.
      }
    };

    run();
    return () => {
      isMounted = false;
    };
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [monthRange, dateFilter]);

  // Orders list fetch
  useEffect(() => {
    let isMounted = true;
    const run = async () => {
      try {
        setIsLoading(true);
        setError(null);

        const isCompletedView = statusFilter === 'completed_today';

        // When viewing Completed, we intentionally ignore the date filter so that
        // the table shows all delivered/closed orders, matching the KPI total.
        const from = isCompletedView ? undefined : monthRange?.from;
        const to = isCompletedView ? undefined : monthRange?.to;

        const statusParam =
          statusFilter === 'all' ? undefined : mapUiStatusToApiStatus(statusFilter);

        const ordersRes = await adminManagementApi.getAdminOrders({
          status: statusParam,
          from,
          to,
          page: 1,
          // Keep the list snappy; backend defaults to 20.
          limit: 20,
        });

        if (!isMounted) return;
        setApiOrders(ordersRes.data.orders ?? []);
      } catch (e: any) {
        if (!isMounted) return;
        setError(e?.response?.data?.message || e?.message || 'Failed to load orders');
      } finally {
        if (!isMounted) return;
        setIsLoading(false);
      }
    };

    run();
    return () => {
      isMounted = false;
    };
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [statusFilter, monthRange, dateFilter]);

  const filtered = useMemo(() => {
    const term = search.trim().toLowerCase();
    if (!term) return apiOrders;
    return apiOrders.filter((o) => {
      const orderNumber = (o.order_number || '').toLowerCase();
      const customerName = (o.customer?.name || '').toLowerCase();
      return orderNumber.includes(term) || customerName.includes(term);
    });
  }, [apiOrders, search]);

  const handleKpiClick = (status: string) => {
    setStatusFilter(status);
  };

  const onView = (orderId: string) => {
    setSelectedOrderId(orderId);
    setIsDetailsOpen(true);
  };

  /** Map any API status to one of the 5 dropdown values (aligned with OrderRow statusClasses). */
  const apiStatusToDropdownValue = (apiStatus: string | null | undefined): string => {
    if (!apiStatus) return 'placed';
    switch (apiStatus) {
      case 'picked_up':
        return 'picked_up';
      case 'services_in_progress':
        return 'services_in_progress';
      case 'out_for_delivery':
        return 'out_for_delivery';
      case 'delivered':
      case 'closed':
        return 'delivered';
      default:
        return 'placed'; // draft, placed, pickup_assigned, submitted_to_cm, received_by_collection, submitted_to_services, services_completed, dispatch_assigned, cancelled
    }
  };

  const onEdit = (orderId: string) => {
    setSelectedOrderId(orderId);
    const current = apiOrders.find((o) => o.order_number === orderId);
    setEditStatus(apiStatusToDropdownValue(current?.status));
    setSaveError(null);
    setIsEditOpen(true);
  };

  const closeDetails = () => {
    setIsDetailsOpen(false);
    setSelectedOrderId(null);
  };

  const closeEdit = () => {
    setIsEditOpen(false);
    setSelectedOrderId(null);
    setSaveError(null);
  };

  const handleSaveStatus = async () => {
    if (!selectedOrderId || !editStatus) return;
    try {
      setIsSaving(true);
      setSaveError(null);

      const res = await adminManagementApi.updateOrderStatus(selectedOrderId, editStatus);

      // Update the list immediately (keeps UI consistent without extra fetches)
      if (res.success) {
        setApiOrders((prev) =>
          prev.map((o) =>
            o.order_number === selectedOrderId
              ? {
                  ...o,
                  status: editStatus,
                  updated_at: (res.data as any)?.updated_at || o.updated_at,
                }
              : o
          )
        );

        // Also refresh summary so KPI cards update
        try {
          const from = monthRange?.from;
          const to = monthRange?.to;
          const summaryRes = await adminManagementApi.getAdminOrdersSummary({
            from,
            to,
          });
          setSummary(summaryRes.data);
        } catch {
          // ignore summary refresh failures
        }

        setIsEditOpen(false);
        setSelectedOrderId(null);
      } else {
        setSaveError(res.message || 'Failed to update status');
      }
    } catch (e: any) {
      setSaveError(e?.response?.data?.message || e?.message || 'Failed to update status');
    } finally {
      setIsSaving(false);
    }
  };

  const mapApiStatusToRowStatus = (status: string | null): OrderRowData['status'] => {
    switch (status) {
      case 'picked_up':
        return 'Picked Up';
      case 'services_in_progress':
        return 'In Progress';
      case 'out_for_delivery':
        return 'Out for Delivery';
      case 'delivered':
      case 'closed':
      case 'payment_pending':
        return 'Delivered';
      case 'services_completed':
      case 'dispatch_assigned':
      case 'pickup_assigned':
      case 'received_by_collection':
      case 'submitted_to_services':
      case 'placed':
      case 'draft':
      case 'cancelled':
      default:
        return 'Pending';
    }
  };

  const formatEta = (iso: string | null): string => {
    if (!iso) return '-';
    const d = new Date(iso);
    if (Number.isNaN(d.getTime())) return '-';
    return d.toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' });
  };

  const rows: OrderRowData[] = filtered.map((o) => {
    const amountNumber = o.amount == null ? 0 : typeof o.amount === 'number' ? o.amount : Number(o.amount);
    const safeAmount = Number.isFinite(amountNumber) ? amountNumber : 0;

    return {
      id: o.order_number,
      customer: o.customer?.name || '-',
      address: o.customer?.address?.full_address || '-',
      services: Array.isArray(o.services) && o.services.length > 0 ? o.services.join(', ') : '-',
      amount: formatCurrency(safeAmount),
      status: mapApiStatusToRowStatus(o.status),
      deliveryBoy: o.delivery_boy?.name ? { name: o.delivery_boy.name } : 'Assign',
      eta: formatEta(o.estimated_delivery_time?.delivery_date || null),
    };
  });

  const formatIsoDate = (iso: string | null | undefined) => {
    if (!iso) return '—';
    const d = new Date(iso);
    if (Number.isNaN(d.getTime())) return '—';
    return d.toLocaleString();
  };

  const prettyStatus = (raw: string | null | undefined) => {
    if (!raw) return '—';
    return raw.replaceAll('_', ' ');
  };

  return (
    <div className="w-full">
      <div className="mx-auto w-full max-w-[1240px] rounded-2xl border border-slate-100 bg-white p-4 shadow-soft sm:p-6 md:p-7 lg:p-8">
        <div className="mb-4 sm:mb-5 md:mb-6">
          <h1 className="text-xl sm:text-2xl font-semibold text-slate-900">Order Management</h1>
          <p className="mt-1 text-xs sm:text-sm text-slate-500">Track and manage all customer orders.</p>
        </div>

        <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-3 sm:gap-4 md:gap-5 lg:gap-6">
          {kpis.map((k) => {
            const isSelected = statusFilter === k.status;
            return (
              <div key={k.label}>
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

        <div className="mt-4 sm:mt-5 md:mt-6 rounded-xl sm:rounded-2xl border border-slate-200 bg-white p-3 sm:p-4 shadow-md">
          <FilterBar
            search={search}
            onSearchChange={setSearch}
            status={statusFilter}
            onStatusChange={setStatusFilter}
            dateFilter={dateFilter}
            onDateChange={setDateFilter}
          />
        </div>

        <div className="mt-4 sm:mt-5 md:mt-6">
          {error ? (
            <div className="rounded-xl sm:rounded-2xl border border-red-200 bg-red-50 p-4 text-sm text-red-700">
              {error}
            </div>
          ) : (
            <OrderTable rows={rows} onView={onView} onEdit={onEdit} />
          )}
          {isLoading ? <p className="mt-3 text-xs sm:text-sm text-slate-500">Loading orders…</p> : null}
        </div>
      </div>

      <Modal isOpen={isDetailsOpen} onClose={closeDetails} title="Order Details" size="lg">
        {!selectedOrder ? (
          <p className="text-sm text-slate-600">Order not found.</p>
        ) : (
          <div className="space-y-4">
            <div className="grid grid-cols-1 sm:grid-cols-2 gap-3">
              <div className="rounded-xl border border-slate-200 bg-slate-50 p-3">
                <p className="text-xs text-slate-500">Order #</p>
                <p className="text-sm font-semibold text-slate-900 break-all">{selectedOrder.order_number}</p>
              </div>
              <div className="rounded-xl border border-slate-200 bg-slate-50 p-3">
                <p className="text-xs text-slate-500">Status</p>
                <p className="text-sm font-semibold text-slate-900">{prettyStatus(selectedOrder.status)}</p>
              </div>
              <div className="rounded-xl border border-slate-200 bg-slate-50 p-3">
                <p className="text-xs text-slate-500">Customer</p>
                <p className="text-sm font-semibold text-slate-900">{selectedOrder.customer?.name || '—'}</p>
                <p className="text-xs text-slate-600 mt-0.5 break-words">
                  {selectedOrder.customer?.address?.full_address || '—'}
                </p>
              </div>
              <div className="rounded-xl border border-slate-200 bg-slate-50 p-3">
                <p className="text-xs text-slate-500">Amount</p>
                <p className="text-sm font-semibold text-slate-900">
                  {formatCurrency(
                    Number.isFinite(Number(selectedOrder.amount)) ? Number(selectedOrder.amount) : 0
                  )}
                </p>
              </div>
            </div>

            <div className="rounded-xl border border-slate-200 p-3">
              <p className="text-xs font-semibold text-slate-700 uppercase tracking-wide">Services</p>
              <p className="mt-1 text-sm text-slate-700">
                {Array.isArray(selectedOrder.services) && selectedOrder.services.length > 0
                  ? selectedOrder.services.join(', ')
                  : '—'}
              </p>
            </div>

            <div className="grid grid-cols-1 sm:grid-cols-2 gap-3">
              <div className="rounded-xl border border-slate-200 p-3">
                <p className="text-xs text-slate-500">Delivery Boy</p>
                <p className="text-sm text-slate-700">{selectedOrder.delivery_boy?.name || '—'}</p>
              </div>
              <div className="rounded-xl border border-slate-200 p-3">
                <p className="text-xs text-slate-500">Est. Delivery</p>
                <p className="text-sm text-slate-700">
                  {formatIsoDate(selectedOrder.estimated_delivery_time?.delivery_date)}
                </p>
              </div>
              <div className="rounded-xl border border-slate-200 p-3">
                <p className="text-xs text-slate-500">Created</p>
                <p className="text-sm text-slate-700">{formatIsoDate(selectedOrder.created_at)}</p>
              </div>
              <div className="rounded-xl border border-slate-200 p-3">
                <p className="text-xs text-slate-500">Updated</p>
                <p className="text-sm text-slate-700">{formatIsoDate(selectedOrder.updated_at)}</p>
              </div>
            </div>
          </div>
        )}
      </Modal>

      <Modal isOpen={isEditOpen} onClose={closeEdit} title="Edit Order" size="md">
        {!selectedOrder ? (
          <p className="text-sm text-slate-600">Order not found.</p>
        ) : (
          <div className="space-y-4">
            <div className="rounded-xl border border-slate-200 bg-slate-50 p-3">
              <p className="text-xs text-slate-500">Order #</p>
              <p className="text-sm font-semibold text-slate-900 break-all">{selectedOrder.order_number}</p>
            </div>

            <div className="space-y-1.5">
              <label className="text-xs font-semibold text-slate-700 uppercase tracking-wide">Status</label>
              <select
                value={editStatus}
                onChange={(e) => setEditStatus(e.target.value)}
                className="w-full rounded-xl border border-slate-200 bg-white px-3 py-2 text-sm text-slate-700 focus:outline-none focus:ring-2 focus:ring-indigo-500"
              >
                <option value="">—</option>
                <option value="placed">Pending</option>
                <option value="picked_up">Picked Up</option>
                <option value="services_in_progress">In Progress</option>
                <option value="out_for_delivery">Out for Delivery</option>
                <option value="delivered">Delivered</option>
              </select>
              {saveError ? <p className="text-xs text-red-600">{saveError}</p> : null}
            </div>

            <div className="flex items-center justify-end gap-2 pt-2">
              <button
                type="button"
                onClick={closeEdit}
                className="rounded-xl border border-slate-200 bg-white px-4 py-2 text-sm text-slate-700 hover:bg-slate-50 transition-colors"
              >
                Cancel
              </button>
              <button
                type="button"
                onClick={handleSaveStatus}
                disabled={!editStatus || isSaving}
                className={`rounded-xl bg-indigo-600 px-4 py-2 text-sm text-white transition-colors ${
                  !editStatus || isSaving ? 'opacity-50 cursor-not-allowed' : 'hover:bg-indigo-700'
                }`}
              >
                {isSaving ? 'Saving…' : 'Save'}
              </button>
            </div>
          </div>
        )}
      </Modal>
    </div>
  );
};
