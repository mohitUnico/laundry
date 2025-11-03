import React from 'react';

interface CardProps {
  title?: React.ReactNode;
  right?: React.ReactNode;
  className?: string;
  children: React.ReactNode;
}

export const Card: React.FC<CardProps> = ({ title, right, className, children }) => {
  return (
    <div className={`tw-card ${className || ''}`}>
      {(title || right) && (
        <div className="tw-card-header">
          {typeof title === 'string' ? (
            <h3 className="text-slate-800 font-semibold">{title}</h3>
          ) : (
            title
          )}
          {right}
        </div>
      )}
      <div className="tw-card-body">{children}</div>
    </div>
  );
};


