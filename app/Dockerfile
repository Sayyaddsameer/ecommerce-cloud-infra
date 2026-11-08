# ===========================================================================
# Stage 1 — Builder: install production dependencies
# ===========================================================================
FROM node:20-alpine AS builder

WORKDIR /app

# Copy only the manifest files first to leverage Docker layer caching
COPY package.json package-lock.json* ./

# Install production dependencies only (no devDependencies)
RUN npm ci --only=production

# ===========================================================================
# Stage 2 — Runtime: lean production image
# ===========================================================================
FROM node:20-alpine

# Create a non-root user for security
RUN addgroup -S appgroup && adduser -S appuser -G appgroup

WORKDIR /app

# Copy installed node_modules from the builder stage
COPY --from=builder /app/node_modules ./node_modules

# Copy package.json (needed at runtime for metadata)
COPY package.json ./

# Copy application source code
COPY src/ ./src/

# Expose the default application port
EXPOSE 8080

# Health check — ensures the container is marked unhealthy if the API is down
HEALTHCHECK --interval=30s --timeout=5s --start-period=10s --retries=3 \
  CMD wget -qO- http://localhost:8080/health || exit 1

# Run as the non-root user
USER appuser

CMD ["node", "src/index.js"]
