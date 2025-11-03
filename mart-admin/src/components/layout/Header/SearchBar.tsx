import React, { useMemo, useState } from 'react';
import { Search } from 'lucide-react';
import { motion, AnimatePresence } from 'framer-motion';

interface SearchItem {
  id: string;
  type: 'order' | 'customer' | 'service';
  label: string;
  href: string;
}

interface SearchBarProps {
  data: SearchItem[];
  onNavigate: (href: string) => void;
}

export const SearchBar: React.FC<SearchBarProps> = ({ data, onNavigate }) => {
  const [query, setQuery] = useState('');
  const [open, setOpen] = useState(false);

  const results = useMemo(() => {
    const q = query.trim().toLowerCase();
    if (!q) return [] as SearchItem[];
    return data.filter((d) => d.label.toLowerCase().includes(q)).slice(0, 8);
  }, [query, data]);

  return (
    <div className="flex-1 max-w-md relative" onFocus={() => setOpen(true)} onBlur={() => setTimeout(() => setOpen(false), 120)}>
      <div className="absolute left-3 sm:left-4 top-1/2 -translate-y-1/2 text-slate-400">
        <Search size={18} className="sm:w-5 sm:h-5" />
      </div>
      <input
        type="text"
        placeholder="Search orders, customers, services..."
        className="w-full pl-9 sm:pl-12 pr-10 sm:pr-12 py-2 sm:py-2.5 rounded-full border border-slate-200 focus:outline-none focus:ring-2 focus:ring-blue-500/20 focus:border-blue-500 text-xs sm:text-sm bg-white"
        value={query}
        onChange={(e) => setQuery(e.target.value)}
      />

      <AnimatePresence>
        {open && results.length > 0 && (
          <motion.div
            className="absolute z-50 mt-2 w-full bg-white border border-slate-200 rounded-xl shadow-lg overflow-hidden"
            initial={{ opacity: 0, y: -6 }}
            animate={{ opacity: 1, y: 0 }}
            exit={{ opacity: 0, y: -6 }}
          >
            {results.map((r) => (
              <button
                key={r.id}
                className="w-full text-left px-4 py-2.5 hover:bg-slate-50 text-sm"
                onMouseDown={(e) => e.preventDefault()}
                onClick={() => onNavigate(r.href)}
              >
                {r.label}
                <span className="ml-2 text-xs text-slate-500">({r.type})</span>
              </button>
            ))}
          </motion.div>
        )}
      </AnimatePresence>
    </div>
  );
};


