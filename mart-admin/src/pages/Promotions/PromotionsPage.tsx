import React from 'react';
import { PromoStatCard } from '@/components/tw-ui/PromoStatCard';
import { PromoCard } from '@/components/tw-ui/PromoCard';

export const PromotionsPage: React.FC = () => {
  return (
    <div className="min-h-screen bg-[#F9FAFB]">
      <div className="max-w-[1280px] mx-auto px-8 lg:px-10 py-6 space-y-8">
        {/* Header */}
        <div className="flex items-center justify-between">
          <div>
            <div className="text-2xl font-bold text-[#111827]">Promotions & Coupons</div>
            <div className="text-sm text-slate-500 mt-1">Create and manage promotional offers</div>
          </div>
          <button className="h-9 px-5 rounded-full bg-[#2B3AFF] hover:bg-[#253BFF] text-white text-sm font-medium shadow-sm">+ Create promotion</button>
        </div>

        {/* Stats */}
        <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-8">
          <PromoStatCard title="Active Promos" value={3} icon={<span className="inline-flex items-center justify-center h-7 w-7 rounded-md bg-emerald-50 text-emerald-600">🏷️</span>} />
          <PromoStatCard title="Total Uses" value={270} icon={<span className="inline-flex items-center justify-center h-7 w-7 rounded-md bg-slate-100 text-slate-600">👤</span>} />
          <PromoStatCard title="Avg. Discount" value={'27%'} icon={<span className="inline-flex items-center justify-center h-7 w-7 rounded-md bg-orange-50 text-orange-600">$</span>} />
          <PromoStatCard title="Conversion" value={'68%'} icon={<span className="inline-flex items-center justify-center h-7 w-7 rounded-md bg-sky-50 text-sky-600">↗</span>} />
        </div>

        {/* Regular Services */}
        <div className="bg-[#F8FAFC] rounded-2xl p-8 space-y-6">
          <div className="flex items-center justify-between">
            <h2 className="text-lg font-bold text-black">Regular Services</h2>
            <button className="text-slate-600 hover:text-slate-900">
              <svg xmlns="http://www.w3.org/2000/svg" className="h-5 w-5" viewBox="0 0 20 20" fill="currentColor">
                <path d="M13.586 3.586a2 2 0 112.828 2.828l-.793.793-2.828-2.828.793-.793zM11.379 5.793L3 14.172V17h2.828l8.38-8.379-2.83-2.828z" />
              </svg>
            </button>
          </div>

          <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-[24px]">
            <PromoCard
              title="New Customer Welcome"
              subtitle="20% off on first order"
              discountPercent="20%"
              details={{
                discount: '20%',
                minOrder: '₹100',
                validUntil: '31 Dec 2024'
              }}
              code="WELCOME20"
              variant="detailed"
            />
            <PromoCard
              title="New Customer Welcome"
              subtitle="20% off on first order"
              discountPercent="20%"
              details={{
                discount: '20%',
                minOrder: '₹100',
                validUntil: '31 Dec 2024'
              }}
              code="WELCOME20"
              variant="simple"
            />
            <PromoCard
              title="Festive Flash Sale"
              subtitle="Limited time only"
              discountPercent="35%"
              details={{
                discount: '35%',
                minOrder: '₹200',
                validUntil: '25 Dec 2024'
              }}
              code="FESTIVAL35"
              variant="detailed"
            />
          </div>
        </div>
      </div>
    </div>
  );
};


