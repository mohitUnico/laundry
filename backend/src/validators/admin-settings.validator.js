const Joi = require('joi');

/**
 * Admin Settings Validators
 * - Team members (staff + owners)
 */

const listTeamMembersQuerySchema = Joi.object({
    // Placeholder for future filters (isActive, role, etc.)
});

const createTeamMemberSchema = Joi.object({
    fullName: Joi.string().min(2).max(255).required(),
    email: Joi.string().email().max(255).required(),
    phone: Joi.string().max(20).allow(null, ''),
    role: Joi.string()
        .valid('owner')
        .required(),
    isActive: Joi.boolean().default(true),
});

module.exports = {
    listTeamMembersQuerySchema,
    createTeamMemberSchema,
};

