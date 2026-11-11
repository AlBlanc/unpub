# ------------------------------------------------------------------------------
# Build Stage: Compile unpub_next to a native AOT binary
# ------------------------------------------------------------------------------
FROM dart:stable AS build

WORKDIR /app

# Copy package manifests first to optimize layer caching
COPY unpub/pubspec.yaml ./
COPY unpub/lib/unpub_api/ ./lib/unpub_api/

# Fetch dependencies
RUN dart pub get

# Copy source code
COPY unpub/ ./

# Compile native AOT executable
RUN dart compile exe bin/unpub_next.dart -o /app/bin/unpub_next

# ------------------------------------------------------------------------------
# Production Stage: Minimal runtime environment with docker-compose-wait
# ------------------------------------------------------------------------------
FROM debian:bookworm-slim

# Install CA certificates for outbound HTTPS calls (pub.dev upstream, oauth, etc.) and curl
RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates \
    curl \
    && rm -rf /var/lib/apt/lists/*

# Add docker-compose-wait tool (https://github.com/ufoscout/docker-compose-wait)
# Ensures MongoDB is fully up and ready before unpub_next starts
ADD https://github.com/ufoscout/docker-compose-wait/releases/download/2.12.1/wait /wait
RUN chmod +x /wait

WORKDIR /app

# Copy compiled executable from build stage
COPY --from=build /app/bin/unpub_next /app/bin/unpub_next

# Copy entrypoint script
COPY docker/entrypoint.sh /app/entrypoint.sh
RUN chmod +x /app/entrypoint.sh

# Create directory for package tarballs and data storage
RUN mkdir -p /app/data

# Default environment configuration
ENV UNPUB_HOST=0.0.0.0 \
    UNPUB_PORT=4000 \
    UNPUB_DATA_DIR=/app/data \
    MONGO_HOST=mongo \
    MONGO_PORT=27017 \
    MONGO_DB=dart_pub

EXPOSE 4000

VOLUME ["/app/data"]

ENTRYPOINT ["/app/entrypoint.sh"]
