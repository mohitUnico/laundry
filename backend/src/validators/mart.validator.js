const Joi = require('joi');

/**
 * Validation schema for mart registration
 */
exports.registerMartSchema = Joi.object({
    martName: Joi.string().min(3).max(255).required().messages({
        'string.empty': 'Mart name is required',
        'string.min': 'Mart name must be at least 3 characters',
        'string.max': 'Mart name cannot exceed 255 characters',
    }),

    contactEmail: Joi.string().email().required().messages({
        'string.empty': 'Contact email is required',
        'string.email': 'Please provide a valid email address',
    }),

    contactPhone: Joi.string()
        .pattern(/^[6-9]\d{9}$/)
        .required()
        .messages({
            'string.empty': 'Contact phone is required',
            'string.pattern.base': 'Please provide a valid 10-digit Indian mobile number',
        }),

    address: Joi.string().min(10).max(1000).required().messages({
        'string.empty': 'Address is required',
        'string.min': 'Address must be at least 10 characters',
        'string.max': 'Address cannot exceed 1000 characters',
    }),

    latitude: Joi.number().min(-90).max(90).required().messages({
        'number.base': 'Latitude must be a valid number',
        'number.min': 'Latitude must be between -90 and 90',
        'number.max': 'Latitude must be between -90 and 90',
    }),

    longitude: Joi.number().min(-180).max(180).required().messages({
        'number.base': 'Longitude must be a valid number',
        'number.min': 'Longitude must be between -180 and 180',
        'number.max': 'Longitude must be between -180 and 180',
    }),

    serviceRadiusKm: Joi.object({
        maxRadius: Joi.number().positive().required(),
        tiers: Joi.array()
            .items(
                Joi.object({
                    minKm: Joi.number().min(0).required(),
                    maxKm: Joi.number().positive().required(),
                    pricePerKm: Joi.number().positive().required(),
                })
            )
            .min(1)
            .required(),
    })
        .required()
        .messages({
            'object.base': 'Service radius configuration is required',
        }),

    isActive: Joi.boolean().default(true),

    // Owner details for first user
    owner: Joi.object({
        fullName: Joi.string().min(3).max(255).required(),
        email: Joi.string().email().required(),
        phone: Joi.string()
            .pattern(/^[6-9]\d{9}$/)
            .required(),
        password: Joi.string().min(8).required().messages({
            'string.min': 'Password must be at least 8 characters',
        }),
    }).required(),
});

/**
 * Validation schema for adding a user to existing mart
 */
exports.addUserSchema = Joi.object({
    martId: Joi.string().uuid().required().messages({
        'string.empty': 'Mart ID is required',
        'string.guid': 'Invalid mart ID format',
    }),

    fullName: Joi.string().min(3).max(255).required().messages({
        'string.empty': 'Full name is required',
        'string.min': 'Full name must be at least 3 characters',
    }),

    email: Joi.string().email().required().messages({
        'string.empty': 'Email is required',
        'string.email': 'Please provide a valid email address',
    }),

    phone: Joi.string()
        .pattern(/^[6-9]\d{9}$/)
        .required()
        .messages({
            'string.empty': 'Phone number is required',
            'string.pattern.base': 'Please provide a valid 10-digit Indian mobile number',
        }),

    password: Joi.string().min(8).required().messages({
        'string.empty': 'Password is required',
        'string.min': 'Password must be at least 8 characters',
    }),

    role: Joi.string()
        .valid('admin', 'manager', 'staff')
        .default('staff')
        .messages({
            'any.only': 'Role must be one of: admin, manager, staff',
        }),

    isActive: Joi.boolean().default(true),
});

/**
 * Validation schema for adding a manager to a mart
 * Simplified schema - role is automatically set to 'manager'
 */
exports.addManagerSchema = Joi.object({
    fullName: Joi.string().min(3).max(255).required().messages({
        'string.empty': 'Full name is required',
        'string.min': 'Full name must be at least 3 characters',
        'string.max': 'Full name cannot exceed 255 characters',
    }),

    email: Joi.string().email().required().messages({
        'string.empty': 'Email is required',
        'string.email': 'Please provide a valid email address',
    }),

    phone: Joi.string()
        .pattern(/^[6-9]\d{9}$/)
        .required()
        .messages({
            'string.empty': 'Phone number is required',
            'string.pattern.base': 'Please provide a valid 10-digit Indian mobile number',
        }),

    password: Joi.string().min(8).required().messages({
        'string.empty': 'Password is required',
        'string.min': 'Password must be at least 8 characters',
    }),

    isActive: Joi.boolean().default(true),
});

/**
 * Validation schema for updating mart details
 */
exports.updateMartSchema = Joi.object({
    martName: Joi.string().min(3).max(255),
    contactEmail: Joi.string().email(),
    contactPhone: Joi.string().pattern(/^[6-9]\d{9}$/),
    address: Joi.string().min(10).max(1000),
    latitude: Joi.number().min(-90).max(90),
    longitude: Joi.number().min(-180).max(180),
    serviceRadiusKm: Joi.object({
        maxRadius: Joi.number().positive(),
        tiers: Joi.array().items(
            Joi.object({
                minKm: Joi.number().min(0),
                maxKm: Joi.number().positive(),
                pricePerKm: Joi.number().positive(),
            })
        ),
    }),
    isActive: Joi.boolean(),
}).min(1); // At least one field must be provided

