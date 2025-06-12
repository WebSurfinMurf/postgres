#!/bin/bash
set -e

echo "Loading environment variables..."
set -a
source /home/websurfinmurf/projects/secrets/postgres.env
set +a

docker run -d \
  --name pgadmin \
  -e PGADMIN_DEFAULT_EMAIL="$PGADMIN_EMAIL" \
  -e PGADMIN_DEFAULT_PASSWORD="$PGADMIN_PASSWORD" \
  -p 8080:80 \
  dpage/pgadmin4
