// Sample Order Routes
// This is a template - implement full routes as needed

import express from 'express'
import * as orderController from '../controllers/order.controller.js'
import { authenticate } from '../middleware/auth.middleware.js'
// import { validate } from '../middleware/validation.middleware.js'
// import { orderSchemas } from '../validators/order.validator.js'

const router = express.Router()

// All routes require authentication
router.use(authenticate)

// Order routes
router.post('/', orderController.createOrder)
router.get('/', orderController.getOrders)
router.get('/:id', orderController.getOrderById)
router.patch('/:id/status', orderController.updateOrderStatus)
router.delete('/:id', orderController.cancelOrder)

export default router

