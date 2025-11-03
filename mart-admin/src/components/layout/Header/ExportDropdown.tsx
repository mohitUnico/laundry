import React, { useEffect, useRef } from 'react';
import { motion, AnimatePresence } from 'framer-motion';

interface ExportDropdownProps {
  open: boolean;
  anchorClassName?: string;
  onClose: () => void;
  onSelect: (format: 'PDF' | 'Excel' | 'CSV') => void;
}

export const ExportDropdown: React.FC<ExportDropdownProps> = ({ open, onClose, onSelect }) => {
  const ref = useRef<HTMLDivElement | null>(null);

  useEffect(() => {
    const onDocClick = (e: MouseEvent) => {
      if (ref.current && !ref.current.contains(e.target as Node)) onClose();
    };
    if (open) document.addEventListener('mousedown', onDocClick);
    return () => document.removeEventListener('mousedown', onDocClick);
  }, [open, onClose]);

  return (
    <AnimatePresence>
      {open && (
        <motion.div
          ref={ref}
          className="absolute right-0 mt-2 w-44 bg-white border border-slate-200 rounded-xl shadow-lg z-50"
          initial={{ opacity: 0, scale: 0.95, y: -4 }}
          animate={{ opacity: 1, scale: 1, y: 0 }}
          exit={{ opacity: 0, scale: 0.95, y: -4 }}
          transition={{ duration: 0.15 }}
        >
          {(['PDF', 'Excel', 'CSV'] as const).map((fmt) => (
            <button
              key={fmt}
              onClick={() => onSelect(fmt)}
              className="w-full text-left px-3 py-2 hover:bg-slate-50 text-sm"
            >
              Export as {fmt}
            </button>
          ))}
        </motion.div>
      )}
    </AnimatePresence>
  );
};


