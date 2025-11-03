import React from 'react';
import { Outlet } from 'react-router-dom';

// Dev-only bypass: render private routes without authentication
export const PrivateRoute: React.FC = () => {
  return <Outlet />;
};
