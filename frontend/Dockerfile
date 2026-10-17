# ==============================================================================
# BusSense AI - Authority Frontend Dockerfile (Multi-stage Next.js Standalone)
# ==============================================================================
# Security & Hygiene:
# - Multi-stage build producing lightweight standalone Node.js output
# - Dedicated non-root user (nextjs:nodejs / UID:GID 1001:1001)
# - No development dependencies or private secrets in final image
# - Bounded healthcheck probe against root HTTP endpoint
# ==============================================================================

# ------------------------------------------------------------------------------
# Base Node Alpine Image
# ------------------------------------------------------------------------------
FROM node:20-alpine AS base

# ------------------------------------------------------------------------------
# Stage 1: Install Dependencies
# ------------------------------------------------------------------------------
FROM base AS deps
RUN apk add --no-cache libc6-compat
WORKDIR /app

COPY package.json package-lock.json ./
RUN npm ci

# ------------------------------------------------------------------------------
# Stage 2: Application Builder
# ------------------------------------------------------------------------------
FROM base AS builder
WORKDIR /app
COPY --from=deps /app/node_modules ./node_modules
COPY . .

# Disable telemetry and set production build environment
ENV NEXT_TELEMETRY_DISABLED=1
ENV NODE_ENV=production

# Public API URL build arguments for client-side bundle baking
ARG NEXT_PUBLIC_API_URL="http://localhost:8000/api"
ARG NEXT_PUBLIC_WS_URL="ws://localhost:8000/ws/telemetry"
ENV NEXT_PUBLIC_API_URL=${NEXT_PUBLIC_API_URL}
ENV NEXT_PUBLIC_WS_URL=${NEXT_PUBLIC_WS_URL}

RUN npm run build

# ------------------------------------------------------------------------------
# Stage 3: Minimal Production Runner
# ------------------------------------------------------------------------------
FROM base AS runner
WORKDIR /app

ENV NODE_ENV=production
ENV NEXT_TELEMETRY_DISABLED=1
ENV PORT=3000
ENV HOSTNAME="0.0.0.0"

# Create non-root system group and user
RUN addgroup --system --gid 1001 nodejs && \
    adduser --system --uid 1001 nextjs

# Copy static assets and standalone build output
COPY --from=builder /app/public ./public
RUN mkdir .next && chown nextjs:nodejs .next

COPY --from=builder --chown=nextjs:nodejs /app/.next/standalone ./
COPY --from=builder --chown=nextjs:nodejs /app/.next/static ./.next/static

# Switch to non-root user
USER nextjs

EXPOSE 3000

# Container liveness health check
HEALTHCHECK --interval=30s --timeout=5s --start-period=15s --retries=3 \
    CMD wget --no-verbose --tries=1 --spider http://127.0.0.1:3000/ || exit 1

# Start standalone Next.js server
CMD ["node", "server.js"]
