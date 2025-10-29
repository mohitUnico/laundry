import express from 'express'
// Import route modules here as they are created
// import orderRoutes from './order.routes.js'
// import customerRoutes from './customer.routes.js'
// import deliveryRoutes from './delivery.routes.js'

const router = express.Router()

// API information endpoint
router.get('/', (req, res) => {
    res.json({
        name: 'Laundry App API',
        version: '1.0.0',
        description: 'REST API for Laundry App platform',
        endpoints: {
            health: '/health',
            api: '/api/v1',
            // auth: '/api/v1/auth',
            // orders: '/api/v1/orders',
            // customers: '/api/v1/customers',
            // delivery: '/api/v1/delivery',
            // services: '/api/v1/services',
        },
    })
})

// Mount route modules
// router.use('/orders', orderRoutes)
// router.use('/customers', customerRoutes)
// router.use('/delivery', deliveryRoutes)

export default router

