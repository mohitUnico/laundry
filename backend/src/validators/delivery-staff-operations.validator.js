const Joi = require('joi');

exports.updateLocationSchema = Joi.object({
    latitude: Joi.number().min(-90).max(90).required(),
    longitude: Joi.number().min(-180).max(180).required(),
});

exports.listAssignmentRequestsQuerySchema = Joi.object({
    status: Joi.string().valid('pending', 'accepted', 'rejected', 'expired', 'cancelled').default('pending'),
});

exports.rejectAssignmentSchema = Joi.object({
    rejectionNote: Joi.string().max(500).allow('', null).default(null),
});

