const express = require('express');
const authRoutes = require('./auth.routes');
const martRoutes = require('./mart.routes');
const orderRoutes = require('./order.routes');
const cartRoutes = require('./cart.routes');
const dashboardRoutes = require('./dashboard.routes');
const serviceRoutes = require('./service.routes');
const clothesRoutes = require('./clothes.routes');
const customerInfoRoutes = require('./customer-info.routes');
const adminOrderManagementRoutes = require('./admin-order-management.routes');
const adminCustomerManagementRoutes = require('./admin-customer-management.routes');
const paymentRoutes = require('./payment.routes');

const router = express.Router();

// API information endpoint
router.get('/', (req, res) => {
    res.json({
        name: 'Laundry App API',
        version: '1.0.0',
        description: 'REST API for Laundry App platform - OTP-based Passwordless Authentication',
        endpoints: {
            health: '/health',
            api: '/api/v1',
            auth: '/api/v1/auth',
            marts: '/api/v1/marts',
            orders: '/api/v1/orders',
            carts: '/api/v1/carts',
            dashboard: '/api/v1/dashboard',
            services: '/api/v1/services',
            clothes: '/api/v1/clothes',
        },
        authentication: {
            type: 'OTP-based Passwordless',
            flows: {
                martRegistration: {
                    step1: 'POST /api/v1/auth/mart/verify-phone/send-otp',
                    step2: 'POST /api/v1/auth/mart/verify-phone/verify-otp',
                    step3: 'POST /api/v1/auth/mart/verify-owner/send-otp',
                    step4: 'POST /api/v1/auth/mart/verify-owner/verify-otp',
                    step5: 'POST /api/v1/marts/register'
                },
                adminLogin: {
                    step1: 'POST /api/v1/auth/admin/login/send-otp',
                    step2: 'POST /api/v1/auth/admin/login/verify-otp'
                },
                customerSignup: {
                    step1: 'POST /api/v1/auth/customer/signup/send-otp',
                    step2: 'POST /api/v1/auth/customer/signup/verify-otp'
                },
                customerLogin: {
                    step1: 'POST /api/v1/auth/customer/login/send-otp',
                    step2: 'POST /api/v1/auth/customer/login/verify-otp'
                },
                deliverySignup: {
                    step1: 'POST /api/v1/auth/delivery/signup/send-otp',
                    step2: 'POST /api/v1/auth/delivery/signup/verify-otp'
                },
                deliveryLogin: {
                    step1: 'POST /api/v1/auth/delivery/login/send-otp',
                    step2: 'POST /api/v1/auth/delivery/login/verify-otp'
                }
            }
        }
    });
});

// Mount route modules
router.use('/auth', authRoutes);
router.use('/marts', martRoutes);
router.use('/orders', orderRoutes);
router.use('/carts', cartRoutes);
router.use('/dashboard', dashboardRoutes);
router.use('/services', serviceRoutes);
router.use('/clothes', clothesRoutes);
router.use('/customer-info', customerInfoRoutes);
router.use('/admin/orders', adminOrderManagementRoutes);
router.use('/admin/customers', adminCustomerManagementRoutes);
router.use('/payments', paymentRoutes);

module.exports = router;

