const crypto = require('crypto');
const prisma = require('../config/database');
const { generateToken } = require('../utils/jwt');
const { AuthenticationError, ValidationError, NotFoundError } = require('../utils/errors');

// NOTE:
// Prisma client generation is flaky on some Windows setups (EPERM when renaming query engine DLL).
// To keep the backend reliable, this service uses raw SQL against the `refresh_tokens` table
// instead of relying on the generated Prisma model.

const REFRESH_TOKEN_BYTES = parseInt(process.env.REFRESH_TOKEN_BYTES || '48', 10);
const REFRESH_TOKEN_EXPIRY_DAYS = parseInt(process.env.REFRESH_TOKEN_EXPIRY_DAYS || '90', 10); // Increased to 90 days

function _hashRefreshToken(token) {
  return crypto.createHash('sha256').update(token).digest('hex');
}

function _expiresAt() {
  return new Date(Date.now() + REFRESH_TOKEN_EXPIRY_DAYS * 24 * 60 * 60 * 1000);
}

function _generateRefreshToken() {
  return crypto.randomBytes(REFRESH_TOKEN_BYTES).toString('hex');
}

function _generateTokenId() {
  if (typeof crypto.randomUUID === 'function') return crypto.randomUUID();
  // Fallback: UUIDv4-ish from random bytes
  const b = crypto.randomBytes(16);
  b[6] = (b[6] & 0x0f) | 0x40;
  b[8] = (b[8] & 0x3f) | 0x80;
  const hex = b.toString('hex');
  return `${hex.slice(0, 8)}-${hex.slice(8, 12)}-${hex.slice(12, 16)}-${hex.slice(16, 20)}-${hex.slice(20)}`;
}

async function _loadUserForToken({ userId, userType }) {
  switch (userType) {
    case 'owner':
    case 'manager': {
      const user = await prisma.user.findUnique({ where: { user_id: userId } });
      if (!user) throw new NotFoundError('User');
      return { email: user.email, fullName: user.full_name, role: user.role };
    }
    case 'collection_manager':
    case 'distribution_manager':
    case 'service_man': {
      const staff = await prisma.staff.findUnique({ where: { staff_id: userId } });
      if (!staff) throw new NotFoundError('Staff');
      return { email: staff.email, fullName: staff.full_name, role: staff.role };
    }
    case 'customer': {
      const customer = await prisma.customer.findUnique({ where: { customer_id: userId } });
      if (!customer) throw new NotFoundError('Customer');
      return { email: customer.email, fullName: customer.full_name, role: 'customer' };
    }
    case 'delivery_staff': {
      const delivery = await prisma.deliveryStaff.findUnique({ where: { staff_id: userId } });
      if (!delivery) throw new NotFoundError('Delivery staff');
      return { email: delivery.email, fullName: delivery.full_name, role: 'delivery_staff' };
    }
    default:
      throw new ValidationError('Invalid user type');
  }
}

async function _insertRefreshToken(tx, { userId, userType, tokenHash, expiresAt }) {
  const tokenId = _generateTokenId();
  const rows = await tx.$queryRaw`
    INSERT INTO refresh_tokens (token_id, user_id, user_type, token_hash, expires_at)
    VALUES (${tokenId}, ${userId}, ${userType}, ${tokenHash}, ${expiresAt})
    RETURNING token_id
  `;
  const returned = Array.isArray(rows) && rows[0] ? rows[0].token_id : null;
  return returned || tokenId;
}

async function issueTokens({ userId, userType, email, role, fullName }) {
  const accessToken = generateToken({
    userId,
    email,
    role: role || userType,
    fullName,
  });

  const rawRefresh = _generateRefreshToken();
  const tokenHash = _hashRefreshToken(rawRefresh);

  const tokenId = await _insertRefreshToken(prisma, {
    userId,
    userType,
    tokenHash,
    expiresAt: _expiresAt(),
  });

  return {
    token: accessToken,
    refreshToken: rawRefresh,
    refreshTokenId: tokenId,
  };
}

async function rotateRefreshToken(rawRefreshToken) {
  if (!rawRefreshToken || typeof rawRefreshToken !== 'string') {
    throw new ValidationError('Refresh token is required');
  }

  const tokenHash = _hashRefreshToken(rawRefreshToken);

  const existingRows = await prisma.$queryRaw`
    SELECT token_id, user_id, user_type, expires_at, revoked_at
    FROM refresh_tokens
    WHERE token_hash = ${tokenHash}
    LIMIT 1
  `;

  const existing = Array.isArray(existingRows) ? existingRows[0] : null;
  if (!existing || existing.revoked_at) {
    throw new AuthenticationError('Invalid refresh token');
  }
  if (new Date() > existing.expires_at) {
    throw new AuthenticationError('Refresh token expired');
  }

  const user = await _loadUserForToken({ userId: existing.user_id, userType: existing.user_type });

  return prisma.$transaction(async (tx) => {
    // Re-check within tx (avoid double-rotation)
    const lockedRows = await tx.$queryRaw`
      SELECT token_id, user_id, user_type, expires_at, revoked_at
      FROM refresh_tokens
      WHERE token_hash = ${tokenHash}
      LIMIT 1
    `;
    const locked = Array.isArray(lockedRows) ? lockedRows[0] : null;

    if (!locked || locked.revoked_at) throw new AuthenticationError('Invalid refresh token');
    if (new Date() > locked.expires_at) throw new AuthenticationError('Refresh token expired');

    const newRaw = _generateRefreshToken();
    const newHash = _hashRefreshToken(newRaw);
    const newTokenId = await _insertRefreshToken(tx, {
      userId: locked.user_id,
      userType: locked.user_type,
      tokenHash: newHash,
      expiresAt: _expiresAt(),
    });

    await tx.$executeRaw`
      UPDATE refresh_tokens
      SET revoked_at = ${new Date()}, replaced_by_token_id = ${newTokenId}
      WHERE token_hash = ${tokenHash}
    `;

    const accessToken = generateToken({
      userId: locked.user_id,
      email: user.email,
      role: user.role || locked.user_type,
      fullName: user.fullName,
    });

    return {
      token: accessToken,
      refreshToken: newRaw,
      user: {
        userId: locked.user_id,
        email: user.email,
        fullName: user.fullName,
        role: user.role || locked.user_type,
      },
    };
  });
}

module.exports = {
  issueTokens,
  rotateRefreshToken,
};


