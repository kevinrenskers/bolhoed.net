# Multi-stage build for bolhoed.net static site

# Stage 1: Build environment
# Using Ubuntu 24.04 (Noble)
FROM swift:6.1-noble AS builder

# Set working directory
WORKDIR /app

# Pre-fetch Swift dependencies (cached unless the Package files change)
COPY Package.swift Package.resolved ./
RUN echo "Prefetching dependencies..." \
    && swift package resolve

# Pre-build the site generator (cached unless the sources change)
COPY Sources ./Sources
RUN echo "Prebuilding..." \
    && swift build --product Bolhoed -c release

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
    && .build/release/Bolhoed

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
