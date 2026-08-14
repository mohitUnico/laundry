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
const adminDeliveryStaffManagementRoutes = require('./admin-delivery-staff-management.routes');
const adminDeliveryOperationsRoutes = require('./delivery-operations.routes');
const adminSettingsRoutes = require('./admin-settings.routes');
const adminDashboardRoutes = require('./admin-dashboard.routes');
const paymentRoutes = require('./payment.routes');
const deliveryStaffOperationsRoutes = require('./delivery-staff-operations.routes');
const deliveryStaffAppRoutes = require('./delivery-staff-app.routes');
const collectionManagerAppRoutes = require('./collection-manager-app.routes');
const distributionManagerAppRoutes = require('./distribution-manager-app.routes');
const serviceManAppRoutes = require('./service-man-app.routes');
const couponsRoutes = require('./coupons.routes');
const configRoutes = require('./config.routes');
const notificationRoutes = require('./notification.routes');
const pickupAssignmentWebhookRoutes = require('./pickup-assignment-webhook.routes');

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
            coupons: '/api/v1/coupons',
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
router.use('/admin/delivery-staff', adminDeliveryStaffManagementRoutes);
router.use('/admin/delivery-ops', adminDeliveryOperationsRoutes);
router.use('/admin/settings', adminSettingsRoutes);
router.use('/admin/dashboard', adminDashboardRoutes);
router.use('/payments', paymentRoutes);
router.use('/coupons', couponsRoutes);
router.use('/delivery-staff', deliveryStaffOperationsRoutes);
router.use('/delivery-staff-app', deliveryStaffAppRoutes);
router.use('/staff-app/collection-manager', collectionManagerAppRoutes);
router.use('/staff-app/distribution-manager', distributionManagerAppRoutes);
router.use('/staff-app/service-man', serviceManAppRoutes);
router.use('/config', configRoutes);
router.use('/notifications', notificationRoutes);
router.use('/webhooks/pickup-assignment', pickupAssignmentWebhookRoutes);

module.exports = router;

