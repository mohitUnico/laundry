import React from 'react';

interface PromoCardProps {
  title: string;
  subtitle: string;
  discountPercent?: string; // e.g. '20%'
  details: {
    discount?: string;
    minOrder?: string;
    validUntil?: string;
  };
  code: string;
  variant?: 'simple' | 'detailed';
}

export const PromoCard: React.FC<PromoCardProps> = ({ title, subtitle, discountPercent, details, code, variant = 'detailed' }) => {
  return (
    <div className="relative bg-[#1E3AFF] rounded-xl shadow-[0_8px_20px_rgba(0,0,0,0.08)] text-white p-5 h-[383px] flex flex-col">
      {/* Perforation circles */}
      <span className="absolute left-0 top-1/2 -translate-y-1/2 bg-[#F8FAFC] rounded-full" style={{ width: 18, height: 18, marginLeft: -9 }} />
      <span className="absolute right-0 top-1/2 -translate-y-1/2 bg-[#F8FAFC] rounded-full" style={{ width: 18, height: 18, marginRight: -9 }} />

      {/* Zig-zag top edge */}
      <div
        className="absolute left-0 top-0 w-full h-4"
        style={{
          backgroundImage:
            "url('data:image/svg+xml;utf8, %3Csvg xmlns=%22http://www.w3.org/2000/svg%22 width=%22100%25%22 height=%224%22 viewBox=%220 0 100 4%22 preserveAspectRatio=%22none%22%3E%3Cpath d=%22M0 4 L2 0 L4 4 L6 0 L8 4 L10 0 L12 4 L14 0 L16 4 L18 0 L20 4 L22 0 L24 4 L26 0 L28 4 L30 0 L32 4 L34 0 L36 4 L38 0 L40 4 L42 0 L44 4 L46 0 L48 4 L50 0 L52 4 L54 0 L56 4 L58 0 L60 4 L62 0 L64 4 L66 0 L68 4 L70 0 L72 4 L74 0 L76 4 L78 0 L80 4 L82 0 L84 4 L86 0 L88 4 L90 0 L92 4 L94 0 L96 4 L98 0 L100 4 Z%22 fill=%22%23FFFFFF%22 fill-opacity=%220.25%22/%3E%3C/svg%3E')",
        }}
      />
      {/* Zig-zag bottom */}
      <div
        className="absolute left-0 bottom-0 w-full h-4 rotate-180"
        style={{
          backgroundImage:
            "url('data:image/svg+xml;utf8, %3Csvg xmlns=%22http://www.w3.org/2000/svg%22 width=%22100%25%22 height=%224%22 viewBox=%220 0 100 4%22 preserveAspectRatio=%22none%22%3E%3Cpath d=%22M0 4 L2 0 L4 4 L6 0 L8 4 L10 0 L12 4 L14 0 L16 4 L18 0 L20 4 L22 0 L24 4 L26 0 L28 4 L30 0 L32 4 L34 0 L36 4 L38 0 L40 4 L42 0 L44 4 L46 0 L48 4 L50 0 L52 4 L54 0 L56 4 L58 0 L60 4 L62 0 L64 4 L66 0 L68 4 L70 0 L72 4 L74 0 L76 4 L78 0 L80 4 L82 0 L84 4 L86 0 L88 4 L90 0 L92 4 L94 0 L96 4 L98 0 L100 4 Z%22 fill=%22%23FFFFFF%22 fill-opacity=%220.25%22/%3E%3C/svg%3E')",
        }}
      />

      <div className="flex items-start gap-3">
        <div className="h-9 w-9 rounded-md flex items-center justify-center text-[18px]" style={{ background: 'linear-gradient(135deg,#FFA94D 0%,#FF6B6B 100%)' }}>🎁</div>
        <div>
          <div className="font-bold leading-5 text-[16px]">{title}</div>
          <div className="text-white/80 text-[12px]">{subtitle}</div>
        </div>
      </div>

      {discountPercent && (
        <div className="mt-6 mb-2 text-center">
          <div className="text-white/80 text-[14px] font-medium">Offer</div>
          <div className="text-[42px] font-bold tracking-tight mt-1">{discountPercent}</div>
        </div>
      )}

      {variant === 'detailed' ? (
        <>
          <div className="mt-6 pt-4 border-t border-dotted border-white/60" />
          <div className="text-[12px] mt-2">
            <div className="flex items-center">
              <span className="text-white/80">Discount</span>
              <span className="flex-1 mx-2 border-b border-dotted border-white/60" />
              <span className="font-semibold">{details.discount}</span>
            </div>
            <div className="flex items-center mt-1">
              <span className="text-white/80">Minimum order</span>
              <span className="flex-1 mx-2 border-b border-dotted border-white/60" />
              <span className="font-semibold">{details.minOrder}</span>
            </div>
            <div className="flex items-center mt-1">
              <span className="text-white/80">Expires</span>
              <span className="flex-1 mx-2 border-b border-dotted border-white/60" />
              <span className="font-semibold">{details.validUntil}</span>
            </div>
          </div>
        </>
      ) : (
        <div className="mt-8 pt-4 border-t border-dashed border-white/60" />
      )}

      <div className="flex-1" />

      {/* Code */}
      <div className="mt-4">
        <div className="text-[11px] text-white/75 text-center mb-2 tracking-wide">USE CODE</div>
        <div className="border border-dashed border-white/80 rounded-lg py-3 text-center font-semibold uppercase tracking-[0.12em] text-[14px]">
          {code}
        </div>
      </div>
    </div>
  );
};


