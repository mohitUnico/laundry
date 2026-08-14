import React from 'react';
import { Pencil, Trash2 } from 'lucide-react';

interface ServiceCardProps {
  title: string;
  description?: string;
  status?: 'Active' | 'Inactive';
  pricePerKg?: string;
  duration?: string;
  onView?: () => void;
  onDelete?: () => void;
  onEdit?: () => void;
}

export const ServiceCard: React.FC<ServiceCardProps> = ({
  title,
  description,
  status = 'Active',
  pricePerKg,
  duration,
  onView,
  onDelete,
  onEdit,
}) => {
  const active = status === 'Active';
  return (
    <div className="bg-white rounded-2xl shadow-sm border border-slate-100 p-4">
      <div className="flex items-start justify-between">
        <div className="flex items-start gap-3">
          <div className="h-10 w-10 rounded-full bg-slate-100 flex items-center justify-center text-slate-400">
            <span className="text-base">🧺</span>
          </div>
          <div>
            <div className="text-slate-800 font-semibold leading-5">{title}</div>
            {description && <div className="text-[12px] text-slate-500 mt-0.5">{description}</div>}
          </div>
        </div>
        <span
          className={
            'px-2 py-0.5 text-[11px] rounded-md border ' +
            (active
              ? 'bg-emerald-50 text-emerald-700 border-emerald-200'
              : 'bg-slate-50 text-slate-500 border-slate-200')
          }
        >
          {status}
        </span>
      </div>
      <div className="grid grid-cols-2 gap-4 mt-4">
        {pricePerKg && (
          <div>
            <div className="text-[12px] text-slate-500">Price per kg</div>
            <div className="text-sm font-semibold text-slate-900">{pricePerKg}</div>
          </div>
        )}
        {duration && (
          <div>
            <div className="text-[12px] text-slate-500">Duration</div>
            <div className="text-sm font-semibold text-slate-900">{duration}</div>
          </div>
        )}
      </div>
      <div className="mt-4 flex items-center gap-3">
        <button
          onClick={onView}
          className="flex-1 h-8 bg-indigo-700 hover:bg-indigo-600 text-white text-sm rounded-md"
        >
          View
        </button>

        <button
          aria-label="Edit service"
          onClick={onEdit}
          className="h-8 w-8 rounded-md border border-slate-200 flex items-center justify-center text-slate-500 hover:bg-indigo-50 hover:text-indigo-700 hover:border-indigo-200"
        >
          <Pencil className="h-4 w-4" />
        </button>

        <button
          aria-label="Delete service"
          onClick={onDelete}
          className="h-8 w-8 rounded-md border border-slate-200 flex items-center justify-center text-slate-500 hover:bg-red-50 hover:text-red-600 hover:border-red-200"
        >
          <Trash2 className="h-4 w-4" />
        </button>
      </div>
    </div>
  );
};


