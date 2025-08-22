#!/bin/bash
set -e

echo "Loading environment variables..."
set -a
source /home/administrator/projects/secrets/postgres.env
set +a

echo "Cleaning up existing container if it exists..."
docker rm -f $POSTGRES_CONTAINER_NAME 2>/dev/null || true

echo "Creating volume if not already created..."
docker volume create $POSTGRES_VOLUME >/dev/null

echo "Creating network if not exists..."
docker network create postgres-net 2>/dev/null || true

echo "Starting PostgreSQL container..."
docker run -d \
  --name "$POSTGRES_CONTAINER_NAME" \
  --network postgres-net \
  --label hidden=true \
  -e POSTGRES_USER="$POSTGRES_USER" \
  -e POSTGRES_PASSWORD="$POSTGRES_PASSWORD" \
  -e POSTGRES_DB="$POSTGRES_DB" \
  -p "$POSTGRES_PORT":5432 \
  -v "$POSTGRES_VOLUME":/var/lib/postgresql/data \
  "$POSTGRES_IMAGE"

echo "✅ PostgreSQL container '$POSTGRES_CONTAINER_NAME' is running on port $POSTGRES_PORT"
