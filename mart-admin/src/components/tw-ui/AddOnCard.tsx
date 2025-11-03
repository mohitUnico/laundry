import React from 'react';

interface Item {
  id?: string;
  name: string;
  fee: string;
  status?: 'Active' | 'Inactive';
}

interface AddOnCardProps {
  items: Item[];
  onAdd?: () => void;
  onEdit?: (item: Item) => void;
}

export const AddOnCard: React.FC<AddOnCardProps> = ({ items, onAdd, onEdit }) => {
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
      <div className="divide-y divide-slate-100">
        {items.map((it) => (
          <div key={it.id || it.name} className="px-5 py-4 flex items-center justify-between">
            <div>
              <div className="text-sm font-semibold text-slate-800">{it.name}</div>
              <div className="text-[12px] text-slate-500">Base fee — {it.fee}</div>
            </div>
            <div className="flex items-center gap-3">
              <span className="px-2 py-0.5 text-[11px] rounded-md border bg-emerald-50 text-emerald-700 border-emerald-200">
                {it.status || 'Active'}
              </span>
              <button 
                onClick={() => onEdit?.(it)}
                className="h-8 px-4 bg-indigo-700 hover:bg-indigo-600 text-white text-sm rounded-md"
              >
                Edit
              </button>
            </div>
          </div>
        ))}
      </div>
    </div>
  );
};


