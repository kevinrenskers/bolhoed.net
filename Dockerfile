# Multi-stage build for bolhoed.net static site

# Stage 1: Build environment
# Using Ubuntu 24.04 (Noble)
FROM swift:6.1-noble AS builder

# Set working directory
WORKDIR /app

# Pre-fetch Swift dependencies (cached unless the Package files change)
COPY Package.swift Package.resolved ./
RUN --mount=type=cache,target=/app/.build,sharing=locked \
    echo "Prefetching dependencies..." \
    && swift package resolve

# Pre-build the site generator (cached unless the sources change).
# .build is a cache mount so SwiftPM's incremental state survives between
# deploys: only the changed module recompiles instead of all ~419 units.
# Because a cache mount isn't part of the image layer, the binary has to be
# copied out of it here, and is run from /usr/local/bin below.
COPY Sources ./Sources
RUN --mount=type=cache,target=/app/.build,sharing=locked \
    echo "Prebuilding..." \
    && swift build --product Bolhoed -c release \
    && cp .build/release/Bolhoed /usr/local/bin/bolhoed

# Copy all remaining files
COPY . .

# Environment variables coming from Coolify. Add an ARG + ENV pair per variable,
# and mark the variable as available at buildtime in Coolify, otherwise it won't
# be passed to the build. These are declared after the expensive layers above so
# that changing a value doesn't invalidate the dependency cache.
ARG TMDB_ACCESS_TOKEN
ENV TMDB_ACCESS_TOKEN=${TMDB_ACCESS_TOKEN}

# Build the site, reusing the downloaded Tailwind binary between builds
RUN --mount=type=cache,target=/root/.swifttailwind \
    echo "Starting website build..." \
    && bolhoed

# Stage 2: Nginx runtime
FROM nginx:alpine

# Copy custom nginx configuration
COPY nginx.conf /etc/nginx/conf.d/default.conf

# Copy built static files from builder
COPY --from=builder /app/deploy /usr/share/nginx/html

# Expose port 80
EXPOSE 80

# Start nginx
CMD ["nginx", "-g", "daemon off;"]
