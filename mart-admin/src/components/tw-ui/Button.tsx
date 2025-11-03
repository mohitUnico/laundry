import React from 'react';

type Variant = 'primary' | 'secondary' | 'ghost';

interface ButtonProps extends React.ButtonHTMLAttributes<HTMLButtonElement> {
  variant?: Variant;
  iconLeft?: React.ReactNode;
}

export const Button: React.FC<ButtonProps> = ({
  children,
  variant = 'primary',
  iconLeft,
  className,
  ...props
}) => {
  const base =
    'inline-flex items-center gap-2 rounded-full px-4 py-2 text-sm font-medium transition-colors focus:outline-none focus:ring-2 focus:ring-offset-2';
  const variants: Record<Variant, string> = {
    primary:
      'bg-primary-600 hover:bg-primary-700 text-white focus:ring-primary-700',
    secondary:
      'bg-slate-100 hover:bg-slate-200 text-slate-800 focus:ring-slate-300',
    ghost: 'bg-transparent hover:bg-slate-100 text-slate-700',
  };
  return (
    <button className={`${base} ${variants[variant]} ${className || ''}`} {...props}>
      {iconLeft}
      {children}
    </button>
  );
};


