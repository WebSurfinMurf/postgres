#!/bin/bash
set -e

echo "Loading environment variables..."
set -a
source /home/websurfinmurf/projects/secrets/postgres.env
set +a

docker run -d \
  --name "$PGADMIN_CONTAINER_NAME" \
  -e PGADMIN_DEFAULT_EMAIL="$PGADMIN_EMAIL" \
  -e PGADMIN_DEFAULT_PASSWORD="$PGADMIN_PASSWORD" \
  -p 8080:8901 \
  dpage/pgadmin4
