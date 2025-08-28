#!/bin/bash
set -e

echo "Loading environment variables..."
set -a
source /home/administrator/projects/secrets/postgres.env
set +a

echo "Removing existing pgAdmin container if exists..."
docker rm -f "$PGADMIN_CONTAINER_NAME" 2>/dev/null || true

echo "Starting pgAdmin container with Traefik routing..."
docker run -d \
  --name "$PGADMIN_CONTAINER_NAME" \
  --network postgres-net \
  -e PGADMIN_DEFAULT_EMAIL="$PGADMIN_EMAIL" \
  -e PGADMIN_DEFAULT_PASSWORD="$PGADMIN_PASSWORD" \
  -e PGPASSFILE=/home/pgadmin/.pgpass \
  -v /home/administrator/projects/secrets/postgresservers.json:/pgadmin4/servers.json \
  -v /home/administrator/projects/secrets/.pgpass:/home/pgadmin/.pgpass \
  -p 8901:80 \
  --label "traefik.enable=true" \
  --label "traefik.docker.network=traefik-proxy" \
  --label "traefik.http.routers.pgadmin.rule=Host(\`pgadmin.ai-servicers.com\`)" \
  --label "traefik.http.routers.pgadmin.entrypoints=websecure" \
  --label "traefik.http.routers.pgadmin.tls=true" \
  --label "traefik.http.routers.pgadmin.tls.certresolver=letsencrypt" \
  --label "traefik.http.services.pgadmin.loadbalancer.server.port=80" \
  dpage/pgadmin4

# Connect to traefik-proxy network for external access
echo "Connecting pgAdmin to traefik-proxy network..."
docker network connect traefik-proxy "$PGADMIN_CONTAINER_NAME"

echo "✅ pgAdmin deployed successfully!"
echo "External access: https://pgadmin.ai-servicers.com"
echo "Local access: http://linuxserver.lan:8901"
echo ""
echo "Login credentials:"
echo "  Email: $PGADMIN_EMAIL"
echo "  Password: (see secrets/postgres.env)"