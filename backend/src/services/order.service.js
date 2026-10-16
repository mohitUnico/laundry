const { AppError } = require('../utils/errors');

exports.createOrder = require('./order-create.v2').createOrder;

exports.confirmOrder = async () => {
    throw new AppError('Draft confirm is removed. Place the order directly.', 410, 'ORDER_FLOW_CHANGED');
};
