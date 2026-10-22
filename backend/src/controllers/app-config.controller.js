const configService = require('../services/config.service');

function money(value) {
    const num = Number(value);
    return Number.isFinite(num) ? num.toFixed(2) : '0.00';
}

exports.getPublicConfig = async (req, res, next) => {
    try {
        const [v2, deliveryFee, expressFee, bufferDays] = await Promise.all([
            configService.getPublicClientConfig(),
            configService.getNumber('DELIVERY_FEE'),
            configService.getNumber('EXPRESS_FEE'),
            configService.getInt('PICKUP_DELIVERY_BUFFER_DAYS'),
        ]);
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
                delivery_fee: money(deliveryFee),
                express_fee: money(expressFee),
                pickup_delivery_buffer_days: bufferDays,
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
