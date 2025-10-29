import React, { lazy, Suspense } from 'react';
import { Routes, Route, Navigate } from 'react-router-dom';
import { PrivateRoute, PublicRoute, ROUTES } from '@/routes';
import { MainLayout } from '@/components/layout';
import { Loader } from '@/components/common';

// Lazy load pages
const DashboardPage = lazy(() => import('@/pages/Dashboard').then((m) => ({ default: m.DashboardPage })));
const OrdersPage = lazy(() => import('@/pages/Orders').then((m) => ({ default: m.OrdersPage })));
const CustomersPage = lazy(() => import('@/pages/Customers').then((m) => ({ default: m.CustomersPage })));
const DeliveryStaffPage = lazy(() => import('@/pages/DeliveryStaff').then((m) => ({ default: m.DeliveryStaffPage })));
const ServicesPage = lazy(() => import('@/pages/Services').then((m) => ({ default: m.ServicesPage })));
const LoginPage = lazy(() => import('@/pages/Auth').then((m) => ({ default: m.LoginPage })));

export const AppRoutes: React.FC = () => {
    return (
        <Suspense fallback={<Loader />}>
            <Routes>
                {/* Public routes */}
                <Route element={<PublicRoute />}>
                    <Route path={ROUTES.LOGIN} element={<LoginPage />} />
                </Route>

                {/* Private routes */}
                <Route element={<PrivateRoute />}>
                    <Route element={<MainLayout />}>
                        <Route path={ROUTES.DASHBOARD} element={<DashboardPage />} />
                        <Route path={ROUTES.ORDERS} element={<OrdersPage />} />
                        <Route path={ROUTES.CUSTOMERS} element={<CustomersPage />} />
                        <Route path={ROUTES.DELIVERY_STAFF} element={<DeliveryStaffPage />} />
                        <Route path={ROUTES.SERVICES} element={<ServicesPage />} />
                    </Route>
                </Route>

                {/* Default redirect */}
                <Route path="/" element={<Navigate to={ROUTES.DASHBOARD} replace />} />
                <Route path="*" element={<Navigate to={ROUTES.DASHBOARD} replace />} />
            </Routes>
        </Suspense>
    );
};
