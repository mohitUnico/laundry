const logger = require('../utils/logger');
const deliveryOperationsService = require('../services/delivery-operations.service');
const { getPickupAssignmentConfig } = require('../config/delivery-assignment.config');
const prisma = require('../config/database');
const { ValidationError } = require('../utils/errors');

/**
 * Webhook endpoint for processing pickup assignments
 * This can be called by database triggers, pg_cron, or external schedulers
 * 
 * Security: Should be protected by a secret token in production
 */
exports.processPickupAssignments = async (req, res, next) => {
    try {
        // Optional: Verify webhook secret token for security
        const webhookSecret = process.env.PICKUP_ASSIGNMENT_WEBHOOK_SECRET;
        if (webhookSecret) {
            const providedSecret = req.headers['x-webhook-secret'] || req.body?.secret;
            if (providedSecret !== webhookSecret) {
                return res.status(401).json({
                    success: false,
                    message: 'Invalid webhook secret',
                });
            }
        }

        const now = new Date();

        // Find orders that:
        // 1. Have reached their preferred pickup time (pickup_time_from <= now)
        // 2. Are in 'placed' status (not yet assigned for pickup)
        // 3. Have pickup_time_from set (not null)
        // 4. Don't already have an active pickup assignment request
        const ordersReadyForPickup = await prisma.order.findMany({
            where: {
                order_status: 'placed',
                pickup_time_from: {
                    lte: now,
                    not: null,
                },
                // Ensure no active pickup assignment request exists
                deliveryAssignmentRequests: {
                    none: {
                        delivery_type: 'pickup',
                        status: 'pending',
                        expires_at: { gt: now },
                    },
                },
                // Ensure no pickup delivery is already assigned
                deliveries: {
                    none: {
                        delivery_type: 'pickup',
                        delivery_status: { in: ['assigned', 'en_route', 'reached'] },
                    },
                },
            },
            select: {
                order_id: true,
                pickup_time_from: true,
                pickup_time_to: true,
            },
            take: getPickupAssignmentConfig().batchSize,
        });

        if (ordersReadyForPickup.length === 0) {
            return res.status(200).json({
                success: true,
                message: 'No orders ready for pickup assignment',
                processed: 0,
                successful: 0,
                failed: 0,
            });
        }

        logger.info('Webhook: Found orders ready for pickup assignment', {
            count: ordersReadyForPickup.length,
            orderIds: ordersReadyForPickup.map((o) => o.order_id),
        });

        // Create assignment requests for each order
        const results = await Promise.allSettled(
            ordersReadyForPickup.map(async (order) => {
                try {
                    const config = getPickupAssignmentConfig();

                    const result = await deliveryOperationsService.createAssignmentRequest({
                        orderId: order.order_id,
                        deliveryType: 'pickup',
                        sendToAll: config.sendToAll,
                        limit: config.maxStaffLimit,
                        expiresInSeconds: config.expirySeconds,
                    });

                    logger.info('Webhook: Pickup assignment request created', {
                        orderId: order.order_id,
                        requestId: result.request?.request_id,
                        recipientCount: result.recipients?.length || 0,
                    });

                    return { orderId: order.order_id, success: true, result };
                } catch (error) {
                    logger.error('Webhook: Failed to create pickup assignment request', {
                        orderId: order.order_id,
                        error: error?.message || String(error),
                    });
                    return { orderId: order.order_id, success: false, error: error?.message };
                }
            })
        );

        const successful = results.filter((r) => r.status === 'fulfilled' && r.value.success).length;
        const failed = results.length - successful;

        logger.info('Webhook: Pickup assignment processing completed', {
            total: ordersReadyForPickup.length,
            successful,
            failed,
        });

        res.status(200).json({
            success: true,
            message: 'Pickup assignment processing completed',
            processed: ordersReadyForPickup.length,
            successful,
            failed,
            orderIds: ordersReadyForPickup.map((o) => o.order_id),
        });
    } catch (error) {
        logger.error('Webhook: Pickup assignment processing failed', {
            error: error?.message || String(error),
            stack: error?.stack,
        });
        next(error);
    }
};

/**
 * Process a specific order for pickup assignment
 * Useful for immediate processing when pickup_time_from is set
 */
exports.processOrderPickupAssignment = async (req, res, next) => {
    try {
        const webhookSecret = process.env.PICKUP_ASSIGNMENT_WEBHOOK_SECRET;
        if (webhookSecret) {
            const providedSecret = req.headers['x-webhook-secret'] || req.body?.secret;
            if (providedSecret !== webhookSecret) {
                return res.status(401).json({
                    success: false,
                    message: 'Invalid webhook secret',
                });
            }
        }

        const { orderId } = req.params;
        if (!orderId) {
            throw new ValidationError('orderId is required');
        }

        const now = new Date();

        // Check if order is eligible for pickup assignment
        const order = await prisma.order.findUnique({
            where: { order_id: orderId },
            select: {
                order_id: true,
                order_status: true,
                pickup_time_from: true,
                deliveryAssignmentRequests: {
                    where: {
                        delivery_type: 'pickup',
                        status: 'pending',
                        expires_at: { gt: now },
                    },
                    take: 1,
                },
                deliveries: {
                    where: {
                        delivery_type: 'pickup',
                        delivery_status: { in: ['assigned', 'en_route', 'reached'] },
                    },
                    take: 1,
                },
            },
        });

        if (!order) {
            return res.status(404).json({
                success: false,
                message: 'Order not found',
            });
        }

        // Validate eligibility
        if (order.order_status !== 'placed') {
            return res.status(400).json({
                success: false,
                message: `Order is not in 'placed' status. Current status: ${order.order_status}`,
            });
        }

        if (!order.pickup_time_from || order.pickup_time_from > now) {
            return res.status(400).json({
                success: false,
                message: 'Order pickup time has not been reached yet',
            });
        }

        if (order.deliveryAssignmentRequests.length > 0) {
            return res.status(400).json({
                success: false,
                message: 'Order already has an active pickup assignment request',
            });
        }

        if (order.deliveries.length > 0) {
            return res.status(400).json({
                success: false,
                message: 'Order already has an assigned pickup delivery',
            });
        }

        // Create assignment request
        const config = getPickupAssignmentConfig();
        const result = await deliveryOperationsService.createAssignmentRequest({
            orderId: order.order_id,
            deliveryType: 'pickup',
            sendToAll: config.sendToAll,
            limit: config.maxStaffLimit,
            expiresInSeconds: config.expirySeconds,
        });

        logger.info('Webhook: Pickup assignment request created for specific order', {
            orderId: order.order_id,
            requestId: result.request?.request_id,
            recipientCount: result.recipients?.length || 0,
        });

        res.status(200).json({
            success: true,
            message: 'Pickup assignment request created',
            data: {
                orderId: order.order_id,
                requestId: result.request?.request_id,
                recipientCount: result.recipients?.length || 0,
            },
        });
    } catch (error) {
        logger.error('Webhook: Failed to process order pickup assignment', {
            orderId: req.params.orderId,
            error: error?.message || String(error),
        });
        next(error);
    }
};

