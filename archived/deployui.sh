#!/bin/bash
set -e

echo "Loading environment variables..."
set -a
source $HOME/projects/secrets/postgres.env
set +a

echo "Removing existing pgAdmin container if exists..."
docker rm -f "$PGADMIN_CONTAINER_NAME" 2>/dev/null || true

echo "Starting pgAdmin container..."
docker run -d \
  --name "$PGADMIN_CONTAINER_NAME" \
  --network postgres-net \
  -e PGADMIN_DEFAULT_EMAIL="$PGADMIN_EMAIL" \
  -e PGADMIN_DEFAULT_PASSWORD="$PGADMIN_PASSWORD" \
  -e PGPASSFILE=/home/pgadmin/.pgpass \
  -v $HOME/projects/secrets/postgresservers.json:/pgadmin4/servers.json \
  -v $HOME/projects/secrets/.pgpass:/home/pgadmin/.pgpass \
  -p 8901:80 \
  dpage/pgadmin4
