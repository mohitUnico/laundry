import React from 'react';
import { AlertCircle } from 'lucide-react';

interface AlertCardProps {
  title?: string;
  subtitle?: string;
  ctaText?: string;
  onCta?: () => void;
}

export const AlertCard: React.FC<AlertCardProps> = ({
  title = 'No alerts',
  subtitle = 'All deliveries are on schedule.',
  ctaText = 'View Details',
  onCta,
}) => {
  const isUrgent = title.toLowerCase().includes('late') || title.toLowerCase().includes('urgent');
  return (
    <div className="bg-[#2F47FF] rounded-[24px] p-4 sm:p-6 text-white relative overflow-hidden min-h-[200px] shadow-[0_10px_30px_rgba(47,71,255,0.18)]">
      <div className="absolute top-3 right-3 sm:top-4 sm:right-4">
        <div className={`rounded-full px-2 sm:px-3 py-1 text-[10px] sm:text-xs font-medium ${
          isUrgent ? 'bg-white/20 text-white' : 'bg-white/20 text-white'
        }`}>
          {isUrgent ? 'Urgent' : 'Info'}
        </div>
      </div>
      <div className="absolute top-3 left-3 sm:top-4 sm:left-4 w-8 h-8 sm:w-10 sm:h-10 rounded-full bg-white/20 flex items-center justify-center">
        <AlertCircle size={18} className="sm:w-5 sm:h-5" />
      </div>
      <div className="mt-10 sm:mt-12 relative z-10">
        <h3 className="text-lg sm:text-xl font-bold mb-2">{title}</h3>
        <p className="text-xs sm:text-sm text-white/90 mb-4">{subtitle}</p>
        {onCta ? (
          <button
            onClick={onCta}
            className="bg-white hover:bg-white/90 text-[#2F47FF] px-4 py-2 rounded-full text-xs sm:text-sm font-semibold transition-colors"
          >
            {ctaText}
          </button>
        ) : null}
      </div>
    </div>
  );
};


