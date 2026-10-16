const configService = require('../services/config.service');

exports.getPublicConfig = async (req, res, next) => {
    try {
        const v2 = await configService.getPublicClientConfig();
        res.status(200).json({
            success: true,
            data: {
                polling: {
                    ordersIntervalMs: parseInt(process.env.POLLING_ORDERS_MS || '15000', 10),
                    couponsIntervalMs: parseInt(process.env.POLLING_COUPONS_MS || '30000', 10),
                    trackingIntervalMs: parseInt(process.env.POLLING_TRACKING_MS || '5000', 10),
                    deliveryHomeIntervalMs: parseInt(process.env.POLLING_DELIVERY_HOME_MS || '15000', 10),
                },
                ...v2,
            },
        });
    } catch (error) {
        next(error);
    }
};

exports.listAdminConfig = async (req, res, next) => {
    try {
        const keys = await configService.listAll();
        res.status(200).json({
            success: true,
            data: { keys },
        });
    } catch (error) {
        next(error);
    }
};

exports.updateAdminConfig = async (req, res, next) => {
    try {
        const updated = await configService.setValue(
            req.params.key,
            req.body.value,
            req.user?.user_id || null
        );
        res.status(200).json({
            success: true,
            data: updated,
        });
    } catch (error) {
        next(error);
    }
};
