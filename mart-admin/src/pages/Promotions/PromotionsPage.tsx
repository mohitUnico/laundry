import React from 'react';
import { PromoStatCard } from '@/components/tw-ui/PromoStatCard';
import { PromoCard } from '@/components/tw-ui/PromoCard';

export const PromotionsPage: React.FC = () => {
  return (
    <div className="w-full">
      <div className="mx-auto mt-1 sm:mt-2 w-full max-w-[1320px] rounded-2xl border border-slate-200 bg-white p-4 sm:p-6 md:p-7 shadow-sm">
        {/* Header */}
        <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-3 sm:gap-4">
          <div>
            <div className="text-xl sm:text-2xl font-bold text-[#111827]">Promotions & Coupons</div>
            <div className="text-xs sm:text-sm text-slate-500 mt-1">Create, schedule, and track discounts your customers can use at checkout.</div>
          </div>
          <button className="h-8 sm:h-9 px-4 sm:px-5 rounded-full bg-[#2B3AFF] hover:bg-[#253BFF] text-white text-xs sm:text-sm font-medium shadow-sm transition-colors w-full sm:w-auto">
            Create promotion
          </button>
        </div>

        {/* Stats */}
        <div className="mt-5 sm:mt-6 grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-3 sm:gap-4 md:gap-5 lg:gap-6 xl:gap-8">
          <PromoStatCard
            title="Active promotions"
            value={3}
            icon={<span className="inline-flex items-center justify-center h-6 w-6 sm:h-7 sm:w-7 rounded-md bg-emerald-50 text-emerald-600">🏷️</span>}
          />
          <PromoStatCard
            title="Total redemptions"
            value={270}
            icon={<span className="inline-flex items-center justify-center h-6 w-6 sm:h-7 sm:w-7 rounded-md bg-slate-100 text-slate-600">👤</span>}
          />
          <PromoStatCard
            title="Average discount"
            value={'27%'}
            icon={<span className="inline-flex items-center justify-center h-6 w-6 sm:h-7 sm:w-7 rounded-md bg-orange-50 text-orange-600">₹</span>}
          />
          <PromoStatCard
            title="Redemption rate"
            value={'68%'}
            icon={<span className="inline-flex items-center justify-center h-6 w-6 sm:h-7 sm:w-7 rounded-md bg-sky-50 text-sky-600">↗</span>}
          />
        </div>

        {/* Promotions list */}
        <div className="mt-6 sm:mt-8 bg-[#F8FAFC] rounded-xl sm:rounded-2xl p-4 sm:p-6 md:p-8 space-y-4 sm:space-y-5 md:space-y-6">
          <div className="flex items-center justify-between gap-3">
            <div>
              <h2 className="text-base sm:text-lg font-bold text-black">Active promotions</h2>
              <p className="text-xs sm:text-sm text-slate-500 mt-1">These codes are available to customers right now.</p>
            </div>
            <button
              type="button"
              aria-label="Manage promotions"
              className="text-slate-600 hover:text-slate-900 transition-colors p-1"
            >
              <svg xmlns="http://www.w3.org/2000/svg" className="h-4 w-4 sm:h-5 sm:w-5" viewBox="0 0 20 20" fill="currentColor">
                <path d="M13.586 3.586a2 2 0 112.828 2.828l-.793.793-2.828-2.828.793-.793zM11.379 5.793L3 14.172V17h2.828l8.38-8.379-2.83-2.828z" />
              </svg>
            </button>
          </div>

          <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-4 sm:gap-5 md:gap-6">
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
              title="Free Delivery Weekend"
              subtitle="Free delivery on orders above ₹299"
              discountPercent="FREE"
              details={{
                discount: 'Delivery fee waived',
                minOrder: '₹299',
                validUntil: '28 Jan 2026'
              }}
              code="FREESHIP"
              variant="detailed"
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


