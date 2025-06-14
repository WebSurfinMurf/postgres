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
  -v /home/websurfinmurf/projects/secrets/postgresservers.json:/pgadmin4/servers.json \
  -v /home/websurfinmurf/projects/secrets/.pgpass:/home/pgadmin/.pgpass \
  -p 8901:80 \
  dpage/pgadmin4
