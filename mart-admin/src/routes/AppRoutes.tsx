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
const PromotionsPage = lazy(() => import('@/pages/Promotions').then((m) => ({ default: m.PromotionsPage })));
const PaymentsPage = lazy(() => import('@/pages/Payments').then((m) => ({ default: m.PaymentsPage })));
const AnalyticsPage = lazy(() => import('@/pages/Analytics').then((m) => ({ default: m.AnalyticsPage })));
const NotificationsPage = lazy(() => import('@/pages/Notifications').then((m) => ({ default: m.NotificationsPage })));
const SettingsPage = lazy(() => import('@/pages/Settings').then((m) => ({ default: m.SettingsPage })));
const LoginPage = lazy(() => import('@/pages/Auth').then((m) => ({ default: m.LoginPage })));
const SignUpPage = lazy(() => import('@/pages/Auth').then((m) => ({ default: m.SignUpPage })));
const SignUpOtpPage = lazy(() => import('@/pages/Auth').then((m) => ({ default: m.SignUpOtpPage })));
const SignUpProfilePage = lazy(() => import('@/pages/Auth/SignUpProfilePage').then((m) => ({ default: m.SignUpProfilePage })));
const SignUpLocationPage = lazy(() => import('@/pages/Auth/SignUpLocationPage').then((m) => ({ default: m.SignUpLocationPage })));

export const AppRoutes: React.FC = () => {
    return (
        <Suspense fallback={<Loader />}>
            <Routes>
                {/* Public routes */}
                <Route element={<PublicRoute />}>
                    <Route path={ROUTES.LOGIN} element={<LoginPage />} />
                    <Route path={ROUTES.SIGNUP} element={<SignUpPage />} />
                    <Route path={ROUTES.SIGNUP_OTP} element={<SignUpOtpPage />} />
                    <Route path={ROUTES.SIGNUP_PROFILE} element={<SignUpProfilePage />} />
                    <Route path={ROUTES.SIGNUP_LOCATION} element={<SignUpLocationPage />} />
                </Route>

                {/* Private routes */}
                <Route element={<PrivateRoute />}>
                    <Route element={<MainLayout />}>
                        <Route path={ROUTES.DASHBOARD} element={<DashboardPage />} />
                        <Route path={ROUTES.ORDERS} element={<OrdersPage />} />
                        <Route path={ROUTES.CUSTOMERS} element={<CustomersPage />} />
                        <Route path={ROUTES.DELIVERY_STAFF} element={<DeliveryStaffPage />} />
                        <Route path={ROUTES.SERVICES} element={<ServicesPage />} />
                        <Route path={ROUTES.PROMOTIONS} element={<PromotionsPage />} />
                        <Route path={ROUTES.PAYMENTS} element={<PaymentsPage />} />
                        <Route path={ROUTES.ANALYTICS} element={<AnalyticsPage />} />
                        <Route path={ROUTES.NOTIFICATIONS} element={<NotificationsPage />} />
                        <Route path={ROUTES.SETTINGS} element={<SettingsPage />} />
                    </Route>
                </Route>

                {/* Default redirect */}
                <Route path="/" element={<Navigate to={ROUTES.DASHBOARD} replace />} />
                <Route path="*" element={<Navigate to={ROUTES.DASHBOARD} replace />} />
            </Routes>
        </Suspense>
    );
};
