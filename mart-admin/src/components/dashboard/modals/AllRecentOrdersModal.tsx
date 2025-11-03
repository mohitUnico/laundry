import React, { useState, useMemo } from 'react';
import { Modal } from '@/components/common';
import { Search, Download, ChevronLeft, ChevronRight } from 'lucide-react';

interface Order {
  orderId: string;
  customer: string;
  amount: string;
  status: string;
  time: string;
  assignedStaff: string;
}

interface AllRecentOrdersModalProps {
  isOpen: boolean;
  onClose: () => void;
}

export const AllRecentOrdersModal: React.FC<AllRecentOrdersModalProps> = ({ isOpen, onClose }) => {
  const [searchTerm, setSearchTerm] = useState('');
  const [currentPage, setCurrentPage] = useState(1);
  const itemsPerPage = 10;

  // Dummy data for all recent orders
  const allOrders: Order[] = useMemo(() => {
    const orders: Order[] = [
      { orderId: 'ORD-2025-001', customer: 'John Williams', amount: '$45.99', status: 'In progress', time: '38 mins ago', assignedStaff: 'Mike Johnson' },
      { orderId: 'ORD-2025-021', customer: 'Emma Davis', amount: '$89.50', status: 'In progress', time: '50 mins ago', assignedStaff: 'Sarah Connor' },
      { orderId: 'ORD-2025-002', customer: 'Michael Brown', amount: '$32.00', status: 'Delivered', time: '1 hr ago', assignedStaff: 'Tom Hanks' },
      { orderId: 'ORD-2025-054', customer: 'Oliver Johnson', amount: '$65.00', status: 'Delivered', time: '1:15 hr ago', assignedStaff: 'Ryan Gosling' },
      { orderId: 'ORD-2025-003', customer: 'Sophia Martinez', amount: '$120.00', status: 'Out for delivery', time: '2 hrs ago', assignedStaff: 'Mike Johnson' },
      { orderId: 'ORD-2025-004', customer: 'William Taylor', amount: '$55.50', status: 'Pending', time: '2:30 hrs ago', assignedStaff: '-' },
      { orderId: 'ORD-2025-005', customer: 'Isabella Anderson', amount: '$78.25', status: 'In progress', time: '3 hrs ago', assignedStaff: 'Sarah Connor' },
      { orderId: 'ORD-2025-006', customer: 'James Wilson', amount: '$95.00', status: 'Delivered', time: '4 hrs ago', assignedStaff: 'Tom Hanks' },
      { orderId: 'ORD-2025-007', customer: 'Charlotte Lee', amount: '$42.75', status: 'Out for delivery', time: '5 hrs ago', assignedStaff: 'Ryan Gosling' },
      { orderId: 'ORD-2025-008', customer: 'Benjamin White', amount: '$110.00', status: 'In progress', time: '6 hrs ago', assignedStaff: 'Mike Johnson' },
      { orderId: 'ORD-2025-009', customer: 'Amelia Harris', amount: '$67.00', status: 'Delivered', time: '7 hrs ago', assignedStaff: 'Sarah Connor' },
      { orderId: 'ORD-2025-010', customer: 'Lucas Clark', amount: '$88.50', status: 'Pending', time: '8 hrs ago', assignedStaff: '-' },
      { orderId: 'ORD-2025-011', customer: 'Mia Lewis', amount: '$52.00', status: 'Out for delivery', time: '9 hrs ago', assignedStaff: 'Tom Hanks' },
      { orderId: 'ORD-2025-012', customer: 'Henry Walker', amount: '$125.00', status: 'Delivered', time: '10 hrs ago', assignedStaff: 'Ryan Gosling' },
      { orderId: 'ORD-2025-013', customer: 'Harper Hall', amount: '$48.25', status: 'In progress', time: '11 hrs ago', assignedStaff: 'Mike Johnson' },
      { orderId: 'ORD-2025-014', customer: 'Alexander Young', amount: '$73.50', status: 'Out for delivery', time: '12 hrs ago', assignedStaff: 'Sarah Connor' },
      { orderId: 'ORD-2025-015', customer: 'Evelyn King', amount: '$92.00', status: 'Delivered', time: '13 hrs ago', assignedStaff: 'Tom Hanks' },
      { orderId: 'ORD-2025-016', customer: 'Daniel Wright', amount: '$58.75', status: 'Pending', time: '14 hrs ago', assignedStaff: '-' },
      { orderId: 'ORD-2025-017', customer: 'Avery Green', amount: '$105.00', status: 'In progress', time: '15 hrs ago', assignedStaff: 'Ryan Gosling' },
      { orderId: 'ORD-2025-018', customer: 'Sofia Baker', amount: '$41.50', status: 'Out for delivery', time: '16 hrs ago', assignedStaff: 'Mike Johnson' },
      { orderId: 'ORD-2025-019', customer: 'Matthew Adams', amount: '$79.25', status: 'Delivered', time: '17 hrs ago', assignedStaff: 'Sarah Connor' },
      { orderId: 'ORD-2025-020', customer: 'Aria Nelson', amount: '$68.00', status: 'In progress', time: '18 hrs ago', assignedStaff: 'Tom Hanks' },
    ];

    return orders;
  }, []);

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
      case 'delivered':
        return 'bg-green-100 text-green-800';
      default:
        return 'bg-gray-100 text-gray-800';
    }
  };

  const handleExport = () => {
    // Simulate export
    console.log('Exporting all recent orders...');
  };

  return (
    <Modal isOpen={isOpen} onClose={onClose} title="All Recent Orders" size="xl">
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
                    Amount
                  </th>
                  <th className="px-4 py-3 text-left text-xs font-semibold text-slate-700 uppercase tracking-wider">
                    Assigned Staff
                  </th>
                  <th className="px-4 py-3 text-left text-xs font-semibold text-slate-700 uppercase tracking-wider">
                    Status
                  </th>
                  <th className="px-4 py-3 text-left text-xs font-semibold text-slate-700 uppercase tracking-wider">
                    Time
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
                    <td className="px-4 py-3 text-sm font-semibold text-slate-900">
                      {order.amount}
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
                      {order.time}
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
            <p className="text-slate-500">No orders found</p>
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


