const serviceManAppService = require('../services/service-man-app.service');
const { AuthorizationError } = require('../utils/errors');

exports.listQueue = async (req, res, next) => {
    try {
        if (req.user.role !== 'service_man') {
            throw new AuthorizationError('Only service men can access this endpoint');
        }

        const staffId = req.user.user_id;
        const { status, page, limit } = req.query;
        const data = await serviceManAppService.listQueue({ staffId, status, page, limit });

        res.status(200).json({
            success: true,
            data: data.queue,
            pagination: data.pagination,
            message: 'Queue fetched successfully',
        });
    } catch (error) {
        next(error);
    }
};

exports.updateQueueItem = async (req, res, next) => {
    try {
        if (req.user.role !== 'service_man') {
            throw new AuthorizationError('Only service men can access this endpoint');
        }

        const staffId = req.user.user_id;
        const { queueId } = req.params;
        const { action, comments } = req.body;
        const data = await serviceManAppService.updateQueueItem({ staffId, queueId, action, comments });

        res.status(200).json({
            success: true,
            data,
            message: 'Queue item updated successfully',
        });
    } catch (error) {
        next(error);
    }
};

exports.listCompleted = async (req, res, next) => {
    try {
        if (req.user.role !== 'service_man') {
            throw new AuthorizationError('Only service men can access this endpoint');
        }

        const staffId = req.user.user_id;
        const { page, limit } = req.query;
        const data = await serviceManAppService.listCompleted({ staffId, page, limit });

        res.status(200).json({
            success: true,
            data: data.completed,
            pagination: data.pagination,
            message: 'Completed items fetched successfully',
        });
    } catch (error) {
        next(error);
    }
};

module.exports = exports;

