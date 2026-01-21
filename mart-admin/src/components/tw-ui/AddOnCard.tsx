import React from 'react';
import { Trash2 } from 'lucide-react';

interface Item {
  id?: string;
  name: string;
  description?: string;
  fee: string;
  status?: 'Active' | 'Inactive';
}

interface AddOnCardProps {
  items: Item[];
  onAdd?: () => void;
  onEdit?: (item: Item) => void;
  onDelete?: (item: Item) => void;
}

export const AddOnCard: React.FC<AddOnCardProps> = ({ items, onAdd, onEdit, onDelete }) => {
  return (
    <div className="bg-white rounded-2xl shadow-sm border border-slate-100">
      <div className="flex items-center justify-between px-5 py-4">
        <div className="text-sm font-semibold text-slate-800">Add-on Services</div>
        <button 
          onClick={onAdd}
          className="h-7 w-7 rounded-md border border-slate-200 text-slate-500 flex items-center justify-center hover:bg-indigo-50 hover:border-indigo-300 hover:text-indigo-700 transition-colors"
        >
          +
        </button>
      </div>
      <div className="px-5 pb-5 space-y-4">
        {items.map((it) => (
          <div key={it.id || it.name} className="rounded-xl border border-slate-100 bg-white shadow-sm p-4">
            <div className="flex items-start justify-between gap-3">
              <div className="flex items-start gap-3">
                <div className="h-9 w-9 rounded-full bg-slate-100 flex items-center justify-center text-slate-400">
                  <span className="text-sm">🧺</span>
                </div>
                <div>
                  <div className="text-sm font-semibold text-slate-800">{it.name}</div>
                  {it.description && <div className="text-[12px] text-slate-500 mt-0.5">{it.description}</div>}
                </div>
              </div>
              <span className="px-2 py-0.5 text-[11px] rounded-md border bg-emerald-50 text-emerald-700 border-emerald-200">
                {it.status || 'Active'}
              </span>
            </div>

            <div className="mt-3 text-[12px] text-slate-500">Base fee</div>
            <div className="text-sm font-semibold text-slate-900">{it.fee}</div>

            <div className="mt-3 flex items-center gap-3">
              <button
                onClick={() => onEdit?.(it)}
                className="flex-1 h-8 bg-indigo-700 hover:bg-indigo-600 text-white text-sm rounded-md"
              >
                Edit
              </button>
              <button
                aria-label="Delete add-on"
                onClick={() => onDelete?.(it)}
                className="h-8 w-8 rounded-md border border-slate-200 flex items-center justify-center text-slate-500 hover:bg-red-50 hover:text-red-600 hover:border-red-200"
              >
                <Trash2 className="h-4 w-4" />
              </button>
            </div>
          </div>
        ))}
      </div>
    </div>
  );
};


