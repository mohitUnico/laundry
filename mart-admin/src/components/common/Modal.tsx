import React, { useEffect } from 'react';
import { X } from 'lucide-react';

interface ModalProps {
  isOpen: boolean;
  onClose: () => void;
  title: string;
  children: React.ReactNode;
  size?: 'sm' | 'md' | 'lg' | 'xl';
}

export const Modal: React.FC<ModalProps> = ({ isOpen, onClose, title, children, size = 'md' }) => {
  useEffect(() => {
    if (isOpen) {
      document.body.style.overflow = 'hidden';
    } else {
      document.body.style.overflow = 'unset';
    }
    return () => {
      document.body.style.overflow = 'unset';
    };
  }, [isOpen]);

  if (!isOpen) return null;

  const sizeClasses = {
    sm: 'max-w-sm sm:max-w-md',
    md: 'max-w-sm sm:max-w-md md:max-w-lg',
    lg: 'max-w-sm sm:max-w-lg md:max-w-2xl',
    xl: 'max-w-sm sm:max-w-lg md:max-w-2xl lg:max-w-4xl',
  };

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/50 backdrop-blur-sm animate-fade-in p-3 sm:p-4">
      <div
        className={`relative bg-white rounded-lg sm:rounded-xl md:rounded-2xl shadow-xl ${sizeClasses[size]} w-full max-h-[95vh] sm:max-h-[90vh] overflow-hidden animate-scale-in flex flex-col`}
        onClick={(e) => e.stopPropagation()}
      >
        {/* Header */}
        <div className="flex items-center justify-between p-4 sm:p-5 md:p-6 border-b border-slate-200 flex-shrink-0">
          <h2 className="text-base sm:text-lg font-semibold text-slate-900 truncate pr-2">{title}</h2>
          <button
            onClick={onClose}
            className="p-1.5 sm:p-2 text-slate-400 hover:text-slate-600 hover:bg-slate-100 rounded-lg transition-colors flex-shrink-0"
            aria-label="Close modal"
          >
            <X size={18} className="sm:w-5 sm:h-5" />
          </button>
        </div>

        {/* Content */}
        <div className="p-4 sm:p-5 md:p-6 overflow-y-auto flex-1 min-h-0">{children}</div>
      </div>
    </div>
  );
};

