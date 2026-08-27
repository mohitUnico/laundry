# Multi-stage build for Node.js backend

# Stage 1: Build
FROM node:18-alpine AS builder

WORKDIR /app

# Copy package files
COPY package*.json ./
COPY prisma ./prisma/
COPY scripts ./scripts/

# Install dependencies
RUN npm ci --only=production

# Generate Prisma Client
RUN npx prisma generate

# Copy application code
COPY . .

# Stage 2: Production
FROM node:18-alpine

WORKDIR /app

# Install dumb-init and OpenSSL for Prisma
RUN apk add --no-cache dumb-init openssl libc6-compat

# Create non-root user
RUN addgroup -g 1001 -S nodejs && \
    adduser -S nodejs -u 1001

# Copy built files from builder
COPY --from=builder --chown=nodejs:nodejs /app/node_modules ./node_modules
COPY --from=builder --chown=nodejs:nodejs /app/prisma ./prisma
COPY --chown=nodejs:nodejs . .

# Create necessary directories
RUN mkdir -p logs uploads && \
    chown -R nodejs:nodejs logs uploads

USER nodejs

EXPOSE 3000

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=40s \
    CMD node -e "require('http').get('http://localhost:3000/health', (r) => {process.exit(r.statusCode === 200 ? 0 : 1)})"

# Use dumb-init to handle signals properly
ENTRYPOINT ["dumb-init", "--"]

CMD ["node", "src/server.js"]

