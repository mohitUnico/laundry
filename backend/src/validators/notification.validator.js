const Joi = require('joi');

exports.saveFcmTokenSchema = Joi.object({
    fcmToken: Joi.string().min(20).required(),
});


