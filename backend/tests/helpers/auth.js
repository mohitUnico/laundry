const { generateToken } = require('../../src/utils/jwt');

function tokenFor({ userId, email, role, fullName }) {
    return generateToken({
        userId,
        email,
        role,
        fullName,
    });
}

function bearer(token) {
    return { Authorization: `Bearer ${token}` };
}

module.exports = {
    tokenFor,
    bearer,
};
