import React from 'react';

interface CustomerSatisfactionProps {
  value?: number;
  fiveStars?: number;
  fourStars?: number;
  lessThanThree?: number;
}

export const CustomerSatisfaction: React.FC<CustomerSatisfactionProps> = ({
  value = 92,
  fiveStars = 82,
  fourStars = 12,
  lessThanThree = 4,
}) => {
  const circumference = 2 * Math.PI * 54;
  const offset = circumference - (value / 100) * circumference;
  return (
    <div className="bg-white rounded-2xl p-4 sm:p-6 border border-slate-200">
      <h3 className="text-base sm:text-lg font-semibold text-slate-800 mb-4 sm:mb-6">
        Customer Satisfaction
      </h3>
      <div className="flex flex-col items-center">
        <div className="relative mb-4 sm:mb-6">
          <svg className="w-32 h-32 sm:w-[140px] sm:h-[140px]" viewBox="0 0 140 140">
            <circle
              cx="70"
              cy="70"
              r="54"
              stroke="#e5e7eb"
              strokeWidth="12"
              fill="none"
            />
            <circle
              cx="70"
              cy="70"
              r="54"
              stroke="#16a34a"
              strokeWidth="12"
              fill="none"
              strokeDasharray={`${circumference} ${circumference}`}
              strokeDashoffset={offset}
              strokeLinecap="round"
              transform="rotate(-90 70 70)"
            />
            <text
              x="70"
              y="76"
              textAnchor="middle"
              fontSize="32"
              fontWeight="700"
              fill="#0f172a"
            >
              {value}%
            </text>
          </svg>
        </div>
        <div className="flex items-center gap-2 sm:gap-4 flex-wrap justify-center">
          <div className="flex items-center gap-1.5 sm:gap-2 text-xs sm:text-sm text-slate-600">
            <span className="h-1.5 w-1.5 sm:h-2 sm:w-2 rounded-full bg-green-500" />
            <span>5 star {fiveStars}%</span>
          </div>
          <div className="flex items-center gap-1.5 sm:gap-2 text-xs sm:text-sm text-slate-600">
            <span className="h-1.5 w-1.5 sm:h-2 sm:w-2 rounded-full bg-blue-500" />
            <span>4 star {fourStars}%</span>
          </div>
          <div className="flex items-center gap-1.5 sm:gap-2 text-xs sm:text-sm text-slate-600">
            <span className="h-1.5 w-1.5 sm:h-2 sm:w-2 rounded-full bg-amber-500" />
            <span>&le;3 star {lessThanThree}%</span>
          </div>
        </div>
      </div>
    </div>
  );
};


