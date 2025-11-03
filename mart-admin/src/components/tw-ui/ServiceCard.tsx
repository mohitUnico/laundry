import React from 'react';

interface ServiceCardProps {
  title: string;
  description?: string;
  status?: 'Active' | 'Inactive';
  pricePerKg?: string;
  duration?: string;
  onDelete?: () => void;
  onEdit?: () => void;
}

export const ServiceCard: React.FC<ServiceCardProps> = ({
  title,
  description,
  status = 'Active',
  pricePerKg,
  duration,
  onDelete,
  onEdit,
}) => {
  const active = status === 'Active';
  return (
    <div className="bg-white rounded-2xl shadow-sm border border-slate-100 p-4">
      <div className="flex items-start justify-between">
        <div className="flex items-start gap-3">
          <div className="h-10 w-10 rounded-full bg-slate-100 flex items-center justify-center text-slate-400">🧺</div>
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
          onClick={onEdit}
          className="flex-1 h-8 bg-indigo-700 hover:bg-indigo-600 text-white text-sm rounded-md"
        >
          Edit
        </button>
        <button
          aria-label="Delete service"
          onClick={onDelete}
          className="h-8 w-8 rounded-full border border-slate-200 flex items-center justify-center text-slate-500 hover:bg-red-50 hover:text-red-600 hover:border-red-200"
        >
          <svg viewBox="0 0 20 20" fill="currentColor" className="h-4 w-4">
            <path fillRule="evenodd" d="M8 2a2 2 0 00-2 2H4a1 1 0 100 2h12a1 1 0 100-2h-2a2 2 0 00-2-2H8zm-3 6a1 1 0 011 1v7a2 2 0 002 2h4a2 2 0 002-2V9a1 1 0 112 0v7a4 4 0 01-4 4H8a4 4 0 01-4-4V9a1 1 0 011-1zm4 1a1 1 0 00-1 1v6a1 1 0 102 0V10a1 1 0 00-1-1zm4 0a1 1 0 00-1 1v6a1 1 0 102 0V10a1 1 0 00-1-1z" clipRule="evenodd" />
          </svg>
        </button>
      </div>
    </div>
  );
};


