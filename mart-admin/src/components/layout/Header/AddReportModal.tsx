import React, { useState } from 'react';
import { motion, AnimatePresence } from 'framer-motion';

interface AddReportModalProps {
  isOpen: boolean;
  onClose: () => void;
  onSuccess: (fileName: string) => void;
}

export const AddReportModal: React.FC<AddReportModalProps> = ({ isOpen, onClose, onSuccess }) => {
  const [reportName, setReportName] = useState('');
  const [reportType, setReportType] = useState('Revenue');
  const [duration, setDuration] = useState('Last 7 days');
  const [format, setFormat] = useState<'PDF' | 'CSV'>('PDF');
  const [loading, setLoading] = useState(false);

  const handleGenerate = async () => {
    setLoading(true);
    await new Promise((r) => setTimeout(r, 1200));
    const content = `Report: ${reportName || 'New Report'}\nType: ${reportType}\nDuration: ${duration}`;
    const blob = new Blob([content], { type: format === 'PDF' ? 'application/pdf' : 'text/csv' });
    const url = URL.createObjectURL(blob);
    const a = document.createElement('a');
    a.href = url;
    a.download = `${reportName || 'report'}.${format === 'PDF' ? 'pdf' : 'csv'}`;
    a.click();
    URL.revokeObjectURL(url);
    setLoading(false);
    onSuccess(a.download);
    onClose();
  };

  return (
    <AnimatePresence>
      {isOpen && (
        <>
          <motion.div className="fixed inset-0 bg-black/30 z-[70]" initial={{ opacity: 0 }} animate={{ opacity: 1 }} exit={{ opacity: 0 }} onClick={onClose} />
          <motion.div
            className="fixed inset-0 z-[71] flex items-center justify-center p-4"
            initial={{ opacity: 0 }}
            animate={{ opacity: 1 }}
            exit={{ opacity: 0 }}
          >
            <motion.div className="w-full max-w-lg bg-white rounded-2xl shadow-xl p-6" initial={{ y: 32 }} animate={{ y: 0 }} exit={{ y: 32 }}>
              <h3 className="text-lg font-semibold mb-4">Generate New Report</h3>
              <div className="space-y-4">
                <div>
                  <label className="block text-sm text-slate-600 mb-1">Report Name</label>
                  <input className="w-full border border-slate-200 rounded-lg px-3 py-2" value={reportName} onChange={(e) => setReportName(e.target.value)} />
                </div>
                <div>
                  <label className="block text-sm text-slate-600 mb-1">Report Type</label>
                  <select className="w-full border border-slate-200 rounded-lg px-3 py-2" value={reportType} onChange={(e) => setReportType(e.target.value)}>
                    {['Revenue', 'Orders', 'Deliveries', 'Customers'].map((t) => (
                      <option key={t}>{t}</option>
                    ))}
                  </select>
                </div>
                <div>
                  <label className="block text-sm text-slate-600 mb-1">Duration</label>
                  <select className="w-full border border-slate-200 rounded-lg px-3 py-2" value={duration} onChange={(e) => setDuration(e.target.value)}>
                    {['Last 7 days', 'Last 30 days', 'This Month', 'Custom'].map((d) => (
                      <option key={d}>{d}</option>
                    ))}
                  </select>
                </div>
                <div>
                  <label className="block text-sm text-slate-600 mb-2">Format</label>
                  <div className="flex items-center gap-4">
                    {(['PDF', 'CSV'] as const).map((f) => (
                      <label key={f} className="flex items-center gap-2 cursor-pointer">
                        <input type="radio" checked={format === f} onChange={() => setFormat(f)} />
                        <span>{f}</span>
                      </label>
                    ))}
                  </div>
                </div>
              </div>
              <div className="flex justify-end gap-3 mt-6">
                <button onClick={onClose} className="px-4 py-2 rounded-lg border border-slate-200">Cancel</button>
                <button onClick={handleGenerate} disabled={loading} className="px-4 py-2 rounded-lg bg-blue-600 text-white disabled:opacity-60">
                  {loading ? 'Generating...' : 'Generate'}
                </button>
              </div>
            </motion.div>
          </motion.div>
        </>
      )}
    </AnimatePresence>
  );
};


