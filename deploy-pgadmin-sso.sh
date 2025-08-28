#!/bin/bash
set -e

echo "Loading environment variables..."
set -a
source /home/administrator/projects/secrets/postgres.env
set +a

echo "Removing existing containers if they exist..."
docker rm -f "$PGADMIN_CONTAINER_NAME" 2>/dev/null || true
docker rm -f pgadmin-auth-proxy 2>/dev/null || true

echo "Starting pgAdmin with native OAuth2 support..."
docker run -d \
  --name "$PGADMIN_CONTAINER_NAME" \
  --network postgres-net \
  -e PGADMIN_DEFAULT_EMAIL="$PGADMIN_EMAIL" \
  -e PGADMIN_DEFAULT_PASSWORD="$PGADMIN_PASSWORD" \
  -e PGADMIN_DISABLE_POSTFIX="true" \
  -e PGADMIN_OAUTH2_CLIENT_ID="$PGADMIN_OAUTH2_CLIENT_ID" \
  -e PGADMIN_OAUTH2_CLIENT_SECRET="$PGADMIN_OAUTH2_CLIENT_SECRET" \
  -e PGPASSFILE=/home/pgadmin/.pgpass \
  -v /home/administrator/projects/secrets/postgresservers.json:/pgadmin4/servers.json \
  -v /home/administrator/projects/secrets/.pgpass:/home/pgadmin/.pgpass \
  -v /home/administrator/projects/postgres/pgadmin-oauth2-config.py:/pgadmin4/config_local.py:ro \
  -p 8901:80 \
  --label "traefik.enable=true" \
  --label "traefik.docker.network=traefik-proxy" \
  --label "traefik.http.routers.pgadmin.rule=Host(\`pgadmin.ai-servicers.com\`)" \
  --label "traefik.http.routers.pgadmin.entrypoints=websecure" \
  --label "traefik.http.routers.pgadmin.tls=true" \
  --label "traefik.http.routers.pgadmin.tls.certresolver=letsencrypt" \
  --label "traefik.http.services.pgadmin.loadbalancer.server.port=80" \
  dpage/pgadmin4

# Connect pgAdmin to traefik-proxy network for external access
echo "Connecting pgAdmin to traefik-proxy network..."
docker network connect traefik-proxy "$PGADMIN_CONTAINER_NAME"

echo "✅ pgAdmin with native OAuth2 SSO deployed successfully!"
echo ""
echo "External access: https://pgadmin.ai-servicers.com"
echo "  - Click 'Sign in with Keycloak SSO' button"
echo "  - Users will be auto-provisioned based on groups:"
echo "    • administrators -> Admin access"
echo "    • developers -> User access (coming soon)"
echo ""
echo "Fallback login (if needed):"
echo "  Email: $PGADMIN_EMAIL"
echo "  Password: (see secrets/postgres.env)"
echo ""
echo "To check status:"
echo "  docker logs pgadmin --tail 20"
echo ""
echo "Note: First login may take a moment as the user is provisioned"