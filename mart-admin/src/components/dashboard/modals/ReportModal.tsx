import React, { useState } from 'react';
import { Modal } from '@/components/common';
import { Download, FileText, FileSpreadsheet } from 'lucide-react';

interface ReportModalProps {
  isOpen: boolean;
  onClose: () => void;
  onSuccess: () => void;
}

export const ReportModal: React.FC<ReportModalProps> = ({ isOpen, onClose, onSuccess }) => {
  const [reportName, setReportName] = useState('');
  const [reportType, setReportType] = useState('sales');
  const [format, setFormat] = useState('pdf');

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    // Simulate report generation
    setTimeout(() => {
      onSuccess();
      onClose();
      setReportName('');
      setReportType('sales');
      setFormat('pdf');
    }, 1000);
  };

  return (
    <Modal isOpen={isOpen} onClose={onClose} title="Create New Report" size="md">
      <form onSubmit={handleSubmit} className="space-y-3 sm:space-y-4">
        <div>
          <label className="block text-xs sm:text-sm font-medium text-slate-700 mb-1.5 sm:mb-2">
            Report Name
          </label>
          <input
            type="text"
            value={reportName}
            onChange={(e) => setReportName(e.target.value)}
            placeholder="Enter report name"
            className="w-full px-3 sm:px-4 py-2 text-xs sm:text-sm border border-slate-200 rounded-lg sm:rounded-xl focus:outline-none focus:ring-2 focus:ring-blue-500 focus:border-transparent"
            required
          />
        </div>

        <div>
          <label className="block text-xs sm:text-sm font-medium text-slate-700 mb-1.5 sm:mb-2">
            Report Type
          </label>
          <select
            value={reportType}
            onChange={(e) => setReportType(e.target.value)}
            className="w-full px-3 sm:px-4 py-2 text-xs sm:text-sm border border-slate-200 rounded-lg sm:rounded-xl focus:outline-none focus:ring-2 focus:ring-blue-500 focus:border-transparent"
          >
            <option value="sales">Sales Report</option>
            <option value="orders">Orders Report</option>
            <option value="customers">Customers Report</option>
            <option value="revenue">Revenue Analysis</option>
          </select>
        </div>

        <div>
          <label className="block text-xs sm:text-sm font-medium text-slate-700 mb-1.5 sm:mb-2">
            Date Range
          </label>
          <select className="w-full px-3 sm:px-4 py-2 text-xs sm:text-sm border border-slate-200 rounded-lg sm:rounded-xl focus:outline-none focus:ring-2 focus:ring-blue-500 focus:border-transparent">
            <option>Last 7 Days</option>
            <option>Last 30 Days</option>
            <option>This Month</option>
            <option>This Quarter</option>
            <option>This Year</option>
          </select>
        </div>

        <div>
          <label className="block text-xs sm:text-sm font-medium text-slate-700 mb-2 sm:mb-3">
            Export Format
          </label>
          <div className="grid grid-cols-2 gap-2 sm:gap-3">
            <button
              type="button"
              onClick={() => setFormat('pdf')}
              className={`flex items-center justify-center gap-1.5 sm:gap-2 px-3 sm:px-4 py-2.5 sm:py-3 border-2 rounded-lg sm:rounded-xl transition-colors ${
                format === 'pdf'
                  ? 'border-blue-600 bg-blue-50 text-blue-700'
                  : 'border-slate-200 hover:border-slate-300'
              }`}
            >
              <FileText size={16} className="sm:w-5 sm:h-5" />
              <span className="text-xs sm:text-sm font-medium">PDF</span>
            </button>
            <button
              type="button"
              onClick={() => setFormat('csv')}
              className={`flex items-center justify-center gap-1.5 sm:gap-2 px-3 sm:px-4 py-2.5 sm:py-3 border-2 rounded-lg sm:rounded-xl transition-colors ${
                format === 'csv'
                  ? 'border-blue-600 bg-blue-50 text-blue-700'
                  : 'border-slate-200 hover:border-slate-300'
              }`}
            >
              <FileSpreadsheet size={16} className="sm:w-5 sm:h-5" />
              <span className="text-xs sm:text-sm font-medium">CSV</span>
            </button>
          </div>
        </div>

        <div className="flex flex-col sm:flex-row gap-2 sm:gap-3 pt-3 sm:pt-4">
          <button
            type="button"
            onClick={onClose}
            className="flex-1 px-4 py-2 text-xs sm:text-sm border border-slate-300 text-slate-700 rounded-lg sm:rounded-xl hover:bg-slate-50 font-medium transition-colors"
          >
            Cancel
          </button>
          <button
            type="submit"
            className="flex-1 px-4 py-2 text-xs sm:text-sm bg-blue-600 text-white rounded-lg sm:rounded-xl hover:bg-blue-700 font-medium transition-colors flex items-center justify-center gap-1.5 sm:gap-2"
          >
            <Download size={16} className="sm:w-[18px] sm:h-[18px]" />
            Generate Report
          </button>
        </div>
      </form>
    </Modal>
  );
};

