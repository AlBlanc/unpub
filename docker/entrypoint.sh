#!/bin/sh
set -e

# If WAIT_HOSTS is not explicitly configured, but MONGO_HOST is defined, set default WAIT_HOSTS
if [ -z "$WAIT_HOSTS" ] && [ -n "$MONGO_HOST" ]; then
  export WAIT_HOSTS="${MONGO_HOST}:${MONGO_PORT:-27017}"
fi

# Run docker-compose-wait to ensure dependent services (e.g. MongoDB) are accepting connections
if [ -x "/wait" ]; then
  /wait
fi

# Hand over to the unpub_next server
exec /app/bin/unpub_next "$@"
