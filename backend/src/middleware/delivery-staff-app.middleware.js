const { ValidationError } = require('../utils/errors');
const { uuidParamSchema } = require('../validators/delivery-staff-app.validator');

exports.validateUuidParam = (paramName) => {
    return (req, _res, next) => {
        const { error } = uuidParamSchema.validate(req.params[paramName]);
        if (error) {
            return next(new ValidationError('Validation failed', [{ field: paramName, message: error.message }]));
        }
        next();
    };
};

module.exports = exports;

