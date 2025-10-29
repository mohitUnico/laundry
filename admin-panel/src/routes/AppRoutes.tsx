import { Routes, Route, Navigate } from 'react-router-dom'
import { MainLayout } from '@/components/layout/MainLayout'
import { LoginPage } from '@/pages/Auth/LoginPage'
import { DashboardPage } from '@/pages/Dashboard/DashboardPage'
import { OrdersListPage } from '@/pages/Orders/OrdersListPage'
import { CustomersListPage } from '@/pages/Customers/CustomersListPage'

export const AppRoutes = () => {
    return (
        <Routes>
            {/* Public routes */}
            <Route path="/login" element={<LoginPage />} />

            {/* Protected routes */}
            <Route element={<MainLayout />}>
                <Route path="/" element={<Navigate to="/dashboard" replace />} />
                <Route path="/dashboard" element={<DashboardPage />} />
                <Route path="/orders" element={<OrdersListPage />} />
                <Route path="/customers" element={<CustomersListPage />} />
                {/* Add more routes as needed */}
            </Route>

            {/* 404 */}
            <Route path="*" element={<div>Page Not Found</div>} />
        </Routes>
    )
}

