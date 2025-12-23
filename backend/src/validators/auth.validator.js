/**
 * Authentication Validators - Email-First OTP Flow
 */

const Joi = require('joi');

// ============================================================================
// COMMON SCHEMAS
// ============================================================================

const emailSchema = Joi.string()
  .email()
  .lowercase()
  .trim()
  .required()
  .messages({
    'string.email': 'Must be a valid email address',
    'any.required': 'Email is required'
  });

const identifierSchema = Joi.string()
  .trim()
  .min(4)
  .max(255)
  .required()
  .messages({
    'string.min': 'Identifier must be at least 4 characters',
    'string.max': 'Identifier must not exceed 255 characters',
    'any.required': 'Identifier is required'
  });

const phoneSchema = Joi.string()
  .pattern(/^[0-9]{10}$/)
  .allow(null, '')
  .optional()
  .messages({
    'string.pattern.base': 'Phone number must be exactly 10 digits'
  });

const flexiblePhoneSchema = Joi.string()
  .pattern(/^[0-9]{6,15}$/)
  .allow(null, '')
  .optional()
  .messages({
    'string.pattern.base': 'Phone number must contain between 6 and 15 digits'
  });

const otpSchema = Joi.string()
  .pattern(/^[0-9]{6}$/)
  .required()
  .messages({
    'string.pattern.base': 'OTP must be exactly 6 digits',
    'any.required': 'OTP is required'
  });

const sessionTokenSchema = Joi.string()
  .required()
  .messages({
    'any.required': 'Session token is required'
  });

const userTypeSchema = Joi.string()
  .valid('owner', 'manager', 'customer', 'delivery_staff')
  .required()
  .messages({
    'any.only': 'User type must be owner, manager, customer, or delivery_staff',
    'any.required': 'User type is required'
  });

// ============================================================================
// SEND OTP VALIDATORS
// ============================================================================

const sendOtpSchema = Joi.object({
  email: emailSchema
});

const sendPortalOtpSchema = Joi.object({
  identifier: identifierSchema
});

// ============================================================================
// VERIFY OTP VALIDATORS
// ============================================================================

const verifyOtpSchema = Joi.object({
  email: emailSchema,
  otp: otpSchema
});

const verifyPortalOtpSchema = Joi.object({
  identifier: identifierSchema,
  otp: otpSchema
});

const completePortalRegistrationSchema = Joi.object({
  sessionToken: sessionTokenSchema,
  profile: Joi.object({
    name: Joi.string().min(2).max(255).required().messages({
      'string.min': 'Name must be at least 2 characters',
      'string.max': 'Name must not exceed 255 characters',
      'any.required': 'Name is required'
    }),
    email: Joi.string()
      .email()
      .lowercase()
      .trim()
      .allow(null, '')
      .optional()
      .messages({
        'string.email': 'Email must be a valid email address'
      }),
    phone: flexiblePhoneSchema
  }).required()
});

// ============================================================================
// OWNER REGISTRATION VALIDATORS
// ============================================================================

const completeOwnerRegistrationSchema = Joi.object({
  sessionToken: sessionTokenSchema,
  martData: Joi.object({
    // Backward compatible naming (martName/martEmail == businessName/businessEmail)
    martName: Joi.string().min(2).max(255).optional(),
    martEmail: Joi.string().email().optional(),
    businessName: Joi.string().min(2).max(255).optional(),
    businessEmail: Joi.string().email().optional(),
    martContact: Joi.string()
      .pattern(/^\+?[0-9]{10,15}$/)
      .optional()
      .allow(null, '')
      .messages({
        'string.pattern.base': 'Mart contact must be a valid phone number (10-15 digits)'
      }),
    address: Joi.string().min(10).max(500).optional().allow(null, '').messages({
      'string.min': 'Address must be at least 10 characters',
      'string.max': 'Address must not exceed 500 characters'
    }),
    profileImageUrl: Joi.string()
      .uri()
      .optional()
      .allow(null, '')
      .messages({
        'string.uri': 'Profile image URL must be a valid URL'
      })
      .description('URL to mart profile image (uploaded to S3)'),
    martCoordinates: Joi.object({
      latitude: Joi.number().min(-90).max(90).required().messages({
        'number.min': 'Latitude must be between -90 and 90',
        'number.max': 'Latitude must be between -90 and 90',
        'any.required': 'Latitude is required'
      }),
      longitude: Joi.number().min(-180).max(180).required().messages({
        'number.min': 'Longitude must be between -180 and 180',
        'number.max': 'Longitude must be between -180 and 180',
        'any.required': 'Longitude is required'
      })
    }).optional().allow(null).messages({
      'object.base': 'Mart coordinates must be a valid object'
    }),
    serviceRadiusKm: Joi.object().optional()
  })
    .or('martName', 'businessName')
    .or('martEmail', 'businessEmail')
    .required()
    .messages({
      'object.missing': 'Business name and email are required',
    }),
  ownerData: Joi.object({
    ownerName: Joi.string().min(2).max(255).required().messages({
      'string.min': 'Owner name must be at least 2 characters',
      'string.max': 'Owner name must not exceed 255 characters',
      'any.required': 'Owner name is required'
    }),
    ownerPhone: flexiblePhoneSchema.optional().allow(null, ''),
    ownerEmail: Joi.string()
      .email()
      .optional()
      .allow(null, '')
      .messages({
        'string.email': 'Owner email must be a valid email address'
      })
      .description('Owner email (optional, will use session identifier if not provided)')
  }).required()
});

// ============================================================================
// MANAGER REGISTRATION VALIDATORS
// ============================================================================

const completeManagerRegistrationSchema = Joi.object({
  sessionToken: sessionTokenSchema,
  managerData: Joi.object({
    martId: Joi.string().uuid().required().messages({
      'string.guid': 'Mart ID must be a valid UUID',
      'any.required': 'Mart ID is required'
    }),
    fullName: Joi.string().min(2).max(255).required().messages({
      'string.min': 'Manager name must be at least 2 characters',
      'string.max': 'Manager name must not exceed 255 characters',
      'any.required': 'Manager name is required'
    }),
    phone: phoneSchema
  }).required()
});

// ============================================================================
// CUSTOMER REGISTRATION VALIDATORS
// ============================================================================

const completeCustomerRegistrationSchema = Joi.object({
  sessionToken: sessionTokenSchema,
  customerData: Joi.object({
    fullName: Joi.string().min(2).max(255).required().messages({
      'string.min': 'Customer name must be at least 2 characters',
      'string.max': 'Customer name must not exceed 255 characters',
      'any.required': 'Customer name is required'
    }),
    phone: phoneSchema,
    address: Joi.object({
      addressLabel: Joi.string()
        .valid('home', 'work', 'friend', 'other')
        .required()
        .messages({
          'any.only': 'Address label must be home, work, friend, or other',
          'any.required': 'Address label is required'
        }),
      address: Joi.string()
        .min(10)
        .max(500)
        .required()
        .messages({
          'string.min': 'Address must be at least 10 characters',
          'string.max': 'Address must not exceed 500 characters',
          'any.required': 'Address is required'
        }),
      latitude: Joi.number()
        .min(-90)
        .max(90)
        .required()
        .messages({
          'number.min': 'Latitude must be between -90 and 90',
          'number.max': 'Latitude must be between -90 and 90',
          'any.required': 'Latitude is required'
        }),
      longitude: Joi.number()
        .min(-180)
        .max(180)
        .required()
        .messages({
          'number.min': 'Longitude must be between -180 and 180',
          'number.max': 'Longitude must be between -180 and 180',
          'any.required': 'Longitude is required'
        })
    }).required().messages({
      'object.base': 'Address is required',
      'any.required': 'Address is required'
    })
  }).required()
});

// ============================================================================
// DELIVERY STAFF REGISTRATION VALIDATORS
// ============================================================================

const completeDeliveryRegistrationSchema = Joi.object({
  sessionToken: sessionTokenSchema,
  deliveryData: Joi.object({
    fullName: Joi.string().min(2).max(255).required().messages({
      'string.min': 'Delivery staff name must be at least 2 characters',
      'string.max': 'Delivery staff name must not exceed 255 characters',
      'any.required': 'Delivery staff name is required'
    }),
    phone: phoneSchema,
    vehicleType: Joi.string()
      .valid('bike', 'car', 'scooter')
      .required()
      .messages({
        'any.only': 'Vehicle type must be bike, car, or scooter',
        'any.required': 'Vehicle type is required'
      }),
    vehicleNumber: Joi.string().min(5).max(50).required().messages({
      'string.min': 'Vehicle number must be at least 5 characters',
      'string.max': 'Vehicle number must not exceed 50 characters',
      'any.required': 'Vehicle number is required'
    }),
    licenseNumber: Joi.string().min(5).max(50).required().messages({
      'string.min': 'License number must be at least 5 characters',
      'string.max': 'License number must not exceed 50 characters',
      'any.required': 'License number is required'
    })
  }).required()
});

// ============================================================================
// COMMON VALIDATORS
// ============================================================================

const resendOtpSchema = Joi.object({
  email: emailSchema,
  userType: userTypeSchema
});

// ============================================================================
// EXPORTS
// ============================================================================

module.exports = {
  // Send OTP
  sendOtpSchema,
  sendPortalOtpSchema,

  // Verify OTP
  verifyOtpSchema,
  verifyPortalOtpSchema,

  // Registration completion
  completePortalRegistrationSchema,
  completeOwnerRegistrationSchema,
  completeManagerRegistrationSchema,
  completeCustomerRegistrationSchema,
  completeDeliveryRegistrationSchema,

  // Common
  resendOtpSchema
};
