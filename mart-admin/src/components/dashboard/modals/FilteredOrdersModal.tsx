import React, { useEffect, useMemo, useState } from 'react';
import { Modal } from '@/components/common';
import { Search, Download, ChevronLeft, ChevronRight } from 'lucide-react';
import { adminManagementApi, AdminOrdersListItem } from '@/services';

interface FilteredOrdersModalProps {
  isOpen: boolean;
  onClose: () => void;
  status: string;
}

export const FilteredOrdersModal: React.FC<FilteredOrdersModalProps> = ({ isOpen, onClose, status }) => {
  const [searchTerm, setSearchTerm] = useState('');
  const [currentPage, setCurrentPage] = useState(1);
  const itemsPerPage = 5;
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [orders, setOrders] = useState<AdminOrdersListItem[]>([]);
  const [total, setTotal] = useState(0);
  const [totalPages, setTotalPages] = useState(1);

  const statusQuery = useMemo(() => {
    const normalized = status.toLowerCase();
    if (normalized === 'pending') {
      return { status: 'placed,pickup_assigned,picked_up,received_by_collection,submitted_to_services' };
    }
    if (normalized === 'in progress') {
      return { status: 'services_in_progress' };
    }
    if (normalized === 'out for delivery') {
      return { status: 'out_for_delivery' };
    }
    if (normalized === 'completed today') {
      return { completedDate: new Date().toISOString() };
    }
    return {};
  }, [status]);

  useEffect(() => {
    if (!isOpen) return;

    let cancelled = false;
    const load = async () => {
      setLoading(true);
      setError(null);
      try {
        const res = await adminManagementApi.getAdminOrders({
          ...statusQuery,
          search: searchTerm || undefined,
          page: currentPage,
          limit: itemsPerPage,
        });
        if (cancelled) return;
        setOrders(res.data.orders);
        setTotal(res.data.pagination.total);
        setTotalPages(res.data.pagination.total_pages || 1);
      } catch (e: any) {
        if (cancelled) return;
        const message = e?.response?.data?.message || e?.message || 'Failed to load orders';
        setError(message);
        setOrders([]);
        setTotal(0);
        setTotalPages(1);
      } finally {
        if (!cancelled) setLoading(false);
      }
    };

    void load();
    return () => {
      cancelled = true;
    };
  }, [isOpen, statusQuery, searchTerm, currentPage]);

  useEffect(() => {
    if (!isOpen) return;
    setCurrentPage(1);
  }, [isOpen, status, searchTerm]);

  const paginatedOrders = orders;

  const getStatusColor = (status: string) => {
    switch (status.toLowerCase()) {
      case 'pending':
        return 'bg-yellow-100 text-yellow-800';
      case 'in progress':
        return 'bg-blue-100 text-blue-800';
      case 'out for delivery':
        return 'bg-cyan-100 text-cyan-800';
      case 'completed':
      case 'delivered':
      case 'closed':
        return 'bg-green-100 text-green-800';
      default:
        return 'bg-gray-100 text-gray-800';
    }
  };

  const formatStatusForRow = (raw: string | null) => {
    if (!raw) return status;
    if (raw === 'services_in_progress') return 'In progress';
    if (raw === 'out_for_delivery') return 'Out for delivery';
    if (raw === 'delivered' || raw === 'closed') return 'Completed';
    if (['placed', 'pickup_assigned', 'picked_up', 'received_by_collection', 'submitted_to_services'].includes(raw)) {
      return 'Pending';
    }
    return raw.replaceAll('_', ' ');
  };

  const formatDate = (iso: string | null) => (iso ? iso.slice(0, 10) : '—');

  const handleExport = () => {
    // Simulate export
    console.log('Exporting filtered orders...');
  };

  return (
    <Modal isOpen={isOpen} onClose={onClose} title={`${status} Orders`} size="xl">
      <div className="space-y-4">
        {/* Search and Export */}
        <div className="flex gap-3">
          <div className="flex-1 relative">
            <Search className="absolute left-3 top-1/2 transform -translate-y-1/2 text-slate-400" size={18} />
            <input
              type="text"
              placeholder="Search by Order ID or Customer name..."
              value={searchTerm}
              onChange={(e) => setSearchTerm(e.target.value)}
              className="w-full pl-10 pr-4 py-2 border border-slate-200 rounded-xl focus:outline-none focus:ring-2 focus:ring-blue-500"
            />
          </div>
          <button
            onClick={handleExport}
            className="px-4 py-2 border border-slate-300 text-slate-700 rounded-xl hover:bg-slate-50 flex items-center gap-2 transition-colors"
          >
            <Download size={18} />
            Export
          </button>
        </div>

        {/* Orders Table */}
        <div className="border border-slate-200 rounded-xl overflow-hidden">
          <div className="overflow-x-auto">
            <table className="w-full">
              <thead className="bg-slate-50 border-b border-slate-200">
                <tr>
                  <th className="px-4 py-3 text-left text-xs font-semibold text-slate-700 uppercase tracking-wider">
                    Order ID
                  </th>
                  <th className="px-4 py-3 text-left text-xs font-semibold text-slate-700 uppercase tracking-wider">
                    Customer
                  </th>
                  <th className="px-4 py-3 text-left text-xs font-semibold text-slate-700 uppercase tracking-wider">
                    Assigned Staff
                  </th>
                  <th className="px-4 py-3 text-left text-xs font-semibold text-slate-700 uppercase tracking-wider">
                    Status
                  </th>
                  <th className="px-4 py-3 text-left text-xs font-semibold text-slate-700 uppercase tracking-wider">
                    Date
                  </th>
                  <th className="px-4 py-3 text-left text-xs font-semibold text-slate-700 uppercase tracking-wider">
                    Actions
                  </th>
                </tr>
              </thead>
              <tbody className="divide-y divide-slate-200">
                {paginatedOrders.map((order) => {
                  const rowStatus = formatStatusForRow(order.status);
                  return (
                    <tr key={order.order_number} className="hover:bg-slate-50 transition-colors">
                      <td className="px-4 py-3 text-sm font-medium text-slate-900">{order.order_number}</td>
                      <td className="px-4 py-3 text-sm text-slate-700">{order.customer?.name || 'Unknown'}</td>
                      <td className="px-4 py-3 text-sm text-slate-700">{order.delivery_boy?.name || '—'}</td>
                      <td className="px-4 py-3">
                        <span className={`px-2.5 py-1 rounded-full text-xs font-medium ${getStatusColor(rowStatus)}`}>
                          {rowStatus}
                        </span>
                      </td>
                      <td className="px-4 py-3 text-sm text-slate-600">{formatDate(order.created_at)}</td>
                      <td className="px-4 py-3 text-sm">
                        <button className="text-blue-600 hover:text-blue-700 font-medium">View</button>
                      </td>
                    </tr>
                  );
                })}
              </tbody>
            </table>
          </div>
        </div>

        {loading && (
          <div className="text-center py-10">
            <p className="text-slate-500">Loading…</p>
          </div>
        )}

        {!loading && error && (
          <div className="text-center py-10">
            <p className="text-slate-500">{error}</p>
          </div>
        )}

        {!loading && !error && total === 0 && (
          <div className="text-center py-12">
            <p className="text-slate-500">No orders found for "{status}"</p>
          </div>
        )}

        {/* Pagination */}
        {totalPages > 1 && (
          <div className="flex items-center justify-between px-4 py-3 border-t border-slate-200">
            <div className="text-sm text-slate-700">
              Showing {total === 0 ? 0 : (currentPage - 1) * itemsPerPage + 1} to{' '}
              {Math.min(currentPage * itemsPerPage, total)} of {total} orders
            </div>
            <div className="flex gap-2">
              <button
                onClick={() => setCurrentPage(prev => Math.max(1, prev - 1))}
                disabled={currentPage === 1}
                className="p-2 border border-slate-200 rounded-lg hover:bg-slate-50 disabled:opacity-50 disabled:cursor-not-allowed transition-colors"
              >
                <ChevronLeft size={18} />
              </button>
              <button
                onClick={() => setCurrentPage(prev => Math.min(totalPages, prev + 1))}
                disabled={currentPage === totalPages}
                className="p-2 border border-slate-200 rounded-lg hover:bg-slate-50 disabled:opacity-50 disabled:cursor-not-allowed transition-colors"
              >
                <ChevronRight size={18} />
              </button>
            </div>
          </div>
        )}
      </div>
    </Modal>
  );
};


