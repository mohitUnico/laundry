import React, { useState, useMemo } from 'react';
import { Modal } from '@/components/common';
import { Search, Download, ChevronLeft, ChevronRight } from 'lucide-react';

interface Order {
  orderId: string;
  customer: string;
  assignedStaff: string;
  status: string;
  date: string;
}

interface FilteredOrdersModalProps {
  isOpen: boolean;
  onClose: () => void;
  status: string;
}

export const FilteredOrdersModal: React.FC<FilteredOrdersModalProps> = ({ isOpen, onClose, status }) => {
  const [searchTerm, setSearchTerm] = useState('');
  const [currentPage, setCurrentPage] = useState(1);
  const itemsPerPage = 5;

  // Dummy data based on status
  const allOrders: Order[] = useMemo(() => {
    const ordersByStatus: Record<string, Order[]> = {
      'Pending': [
        { orderId: 'ORD-2025-100', customer: 'Alice Johnson', assignedStaff: 'John Doe', status: 'Pending', date: '2025-01-15' },
        { orderId: 'ORD-2025-101', customer: 'Bob Smith', assignedStaff: 'Jane Smith', status: 'Pending', date: '2025-01-15' },
        { orderId: 'ORD-2025-102', customer: 'Carol White', assignedStaff: 'John Doe', status: 'Pending', date: '2025-01-14' },
        { orderId: 'ORD-2025-103', customer: 'David Brown', assignedStaff: '-', status: 'Pending', date: '2025-01-14' },
        { orderId: 'ORD-2025-104', customer: 'Emma Davis', assignedStaff: 'John Doe', status: 'Pending', date: '2025-01-13' },
        { orderId: 'ORD-2025-105', customer: 'Frank Miller', assignedStaff: 'Jane Smith', status: 'Pending', date: '2025-01-13' },
        { orderId: 'ORD-2025-106', customer: 'Grace Lee', assignedStaff: '-', status: 'Pending', date: '2025-01-12' },
        { orderId: 'ORD-2025-107', customer: 'Henry Taylor', assignedStaff: 'John Doe', status: 'Pending', date: '2025-01-12' },
      ],
      'In progress': [
        { orderId: 'ORD-2025-080', customer: 'Iris Chen', assignedStaff: 'Mike Johnson', status: 'In progress', date: '2025-01-15' },
        { orderId: 'ORD-2025-081', customer: 'Jack Wilson', assignedStaff: 'Sarah Connor', status: 'In progress', date: '2025-01-15' },
        { orderId: 'ORD-2025-082', customer: 'Karen Anderson', assignedStaff: 'Mike Johnson', status: 'In progress', date: '2025-01-14' },
        { orderId: 'ORD-2025-083', customer: 'Larry Martin', assignedStaff: 'Sarah Connor', status: 'In progress', date: '2025-01-14' },
        { orderId: 'ORD-2025-084', customer: 'Mary Garcia', assignedStaff: 'Mike Johnson', status: 'In progress', date: '2025-01-13' },
        { orderId: 'ORD-2025-085', customer: 'Nick Thompson', assignedStaff: 'Tom Hanks', status: 'In progress', date: '2025-01-13' },
        { orderId: 'ORD-2025-086', customer: 'Olivia Martinez', assignedStaff: 'Sarah Connor', status: 'In progress', date: '2025-01-12' },
        { orderId: 'ORD-2025-087', customer: 'Paul Rodriguez', assignedStaff: 'Mike Johnson', status: 'In progress', date: '2025-01-12' },
        { orderId: 'ORD-2025-088', customer: 'Quinn Lewis', assignedStaff: 'Tom Hanks', status: 'In progress', date: '2025-01-11' },
        { orderId: 'ORD-2025-089', customer: 'Rachel Walker', assignedStaff: 'Mike Johnson', status: 'In progress', date: '2025-01-11' },
        { orderId: 'ORD-2025-090', customer: 'Sam Young', assignedStaff: 'Sarah Connor', status: 'In progress', date: '2025-01-10' },
        { orderId: 'ORD-2025-091', customer: 'Tina Hall', assignedStaff: 'Tom Hanks', status: 'In progress', date: '2025-01-10' },
        { orderId: 'ORD-2025-092', customer: 'Uma King', assignedStaff: 'Mike Johnson', status: 'In progress', date: '2025-01-09' },
        { orderId: 'ORD-2025-093', customer: 'Victor Wright', assignedStaff: 'Sarah Connor', status: 'In progress', date: '2025-01-09' },
        { orderId: 'ORD-2025-094', customer: 'Wendy Lopez', assignedStaff: 'Tom Hanks', status: 'In progress', date: '2025-01-08' },
      ],
      'Out for delivery': [
        { orderId: 'ORD-2025-060', customer: 'Xara Moore', assignedStaff: 'Ryan Gosling', status: 'Out for delivery', date: '2025-01-15' },
        { orderId: 'ORD-2025-061', customer: 'Yuki Clark', assignedStaff: 'Emma Stone', status: 'Out for delivery', date: '2025-01-15' },
        { orderId: 'ORD-2025-062', customer: 'Zara Scott', assignedStaff: 'Ryan Gosling', status: 'Out for delivery', date: '2025-01-14' },
        { orderId: 'ORD-2025-063', customer: 'Alex Green', assignedStaff: 'Emma Stone', status: 'Out for delivery', date: '2025-01-14' },
        { orderId: 'ORD-2025-064', customer: 'Ben Adams', assignedStaff: 'Ryan Gosling', status: 'Out for delivery', date: '2025-01-13' },
        { orderId: 'ORD-2025-065', customer: 'Cindy Baker', assignedStaff: 'Tom Cruise', status: 'Out for delivery', date: '2025-01-13' },
        { orderId: 'ORD-2025-066', customer: 'Dan Nelson', assignedStaff: 'Emma Stone', status: 'Out for delivery', date: '2025-01-12' },
        { orderId: 'ORD-2025-067', customer: 'Eva Hill', assignedStaff: 'Ryan Gosling', status: 'Out for delivery', date: '2025-01-12' },
        { orderId: 'ORD-2025-068', customer: 'Fiona Campbell', assignedStaff: 'Tom Cruise', status: 'Out for delivery', date: '2025-01-11' },
        { orderId: 'ORD-2025-069', customer: 'George Mitchell', assignedStaff: 'Emma Stone', status: 'Out for delivery', date: '2025-01-11' },
        { orderId: 'ORD-2025-070', customer: 'Hannah Roberts', assignedStaff: 'Ryan Gosling', status: 'Out for delivery', date: '2025-01-10' },
        { orderId: 'ORD-2025-071', customer: 'Ian Turner', assignedStaff: 'Tom Cruise', status: 'Out for delivery', date: '2025-01-10' },
      ],
      'Completed today': Array.from({ length: 34 }, (_, i) => ({
        orderId: `ORD-2025-${String(20 + i).padStart(3, '0')}`,
        customer: `Customer ${i + 1}`,
        assignedStaff: ['Mike Johnson', 'Sarah Connor', 'Tom Hanks', 'Ryan Gosling'][i % 4],
        status: 'Completed',
        date: '2025-01-15',
      })),
    };

    return ordersByStatus[status] || [];
  }, [status]);

  const filteredOrders = useMemo(() => {
    return allOrders.filter(order =>
      order.orderId.toLowerCase().includes(searchTerm.toLowerCase()) ||
      order.customer.toLowerCase().includes(searchTerm.toLowerCase())
    );
  }, [allOrders, searchTerm]);

  const totalPages = Math.ceil(filteredOrders.length / itemsPerPage);
  const paginatedOrders = useMemo(() => {
    const start = (currentPage - 1) * itemsPerPage;
    const end = start + itemsPerPage;
    return filteredOrders.slice(start, end);
  }, [filteredOrders, currentPage]);

  const getStatusColor = (status: string) => {
    switch (status.toLowerCase()) {
      case 'pending':
        return 'bg-yellow-100 text-yellow-800';
      case 'in progress':
        return 'bg-blue-100 text-blue-800';
      case 'out for delivery':
        return 'bg-cyan-100 text-cyan-800';
      case 'completed':
        return 'bg-green-100 text-green-800';
      default:
        return 'bg-gray-100 text-gray-800';
    }
  };

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
                {paginatedOrders.map((order) => (
                  <tr key={order.orderId} className="hover:bg-slate-50 transition-colors">
                    <td className="px-4 py-3 text-sm font-medium text-slate-900">
                      {order.orderId}
                    </td>
                    <td className="px-4 py-3 text-sm text-slate-700">
                      {order.customer}
                    </td>
                    <td className="px-4 py-3 text-sm text-slate-700">
                      {order.assignedStaff}
                    </td>
                    <td className="px-4 py-3">
                      <span className={`px-2.5 py-1 rounded-full text-xs font-medium ${getStatusColor(order.status)}`}>
                        {order.status}
                      </span>
                    </td>
                    <td className="px-4 py-3 text-sm text-slate-600">
                      {order.date}
                    </td>
                    <td className="px-4 py-3 text-sm">
                      <button className="text-blue-600 hover:text-blue-700 font-medium">
                        View
                      </button>
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        </div>

        {filteredOrders.length === 0 && (
          <div className="text-center py-12">
            <p className="text-slate-500">No orders found for "{status}"</p>
          </div>
        )}

        {/* Pagination */}
        {totalPages > 1 && (
          <div className="flex items-center justify-between px-4 py-3 border-t border-slate-200">
            <div className="text-sm text-slate-700">
              Showing {((currentPage - 1) * itemsPerPage) + 1} to {Math.min(currentPage * itemsPerPage, filteredOrders.length)} of {filteredOrders.length} orders
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


