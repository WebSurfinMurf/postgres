#!/bin/bash
set -e

echo "Deploying pgAdmin with OAuth2 Proxy (Keycloak SSO)"
echo "==================================================="

# Load environment
set -a
source /home/administrator/secrets/postgres.env
set +a

# Remove existing containers
echo "Removing existing containers..."
docker rm -f pgadmin pgadmin-auth-proxy 2>/dev/null || true

# Create component network
docker network create pgadmin-net 2>/dev/null || true

# Deploy pgAdmin backend (isolated)
echo "Deploying pgAdmin backend..."
docker run -d \
  --name pgadmin \
  --restart unless-stopped \
  --network pgadmin-net \
  -e PGADMIN_DEFAULT_EMAIL="$PGADMIN_EMAIL" \
  -e PGADMIN_DEFAULT_PASSWORD="$PGADMIN_PASSWORD" \
  -e PGADMIN_DISABLE_POSTFIX="true" \
  -e PGPASSFILE=/home/pgadmin/.pgpass \
  -v /home/administrator/secrets/postgresservers.json:/pgadmin4/servers.json \
  -v /home/administrator/secrets/.pgpass:/home/pgadmin/.pgpass:ro \
  -v pgadmin_data:/var/lib/pgadmin \
  dpage/pgadmin4

# Connect to postgres-net for database access
docker network connect postgres-net pgadmin

# Deploy OAuth2 Proxy
echo "Deploying OAuth2 proxy..."
docker run -d \
  --name pgadmin-auth-proxy \
  --restart unless-stopped \
  --network keycloak-net \
  --env-file /home/administrator/secrets/pgadmin-oauth2.env \
  --label "traefik.enable=true" \
  --label "traefik.docker.network=traefik-net" \
  --label "traefik.http.routers.pgadmin.rule=Host(\`pgadmin.ai-servicers.com\`)" \
  --label "traefik.http.routers.pgadmin.entrypoints=websecure" \
  --label "traefik.http.routers.pgadmin.tls=true" \
  --label "traefik.http.routers.pgadmin.tls.certresolver=letsencrypt" \
  --label "traefik.http.services.pgadmin.loadbalancer.server.port=4180" \
  quay.io/oauth2-proxy/oauth2-proxy:latest

# Connect OAuth2 proxy to traefik and pgadmin networks
docker network connect traefik-net pgadmin-auth-proxy
docker network connect pgadmin-net pgadmin-auth-proxy

echo ""
echo "✅ pgAdmin with OAuth2 Proxy deployed successfully!"
echo ""
echo "Access: https://pgadmin.ai-servicers.com"
echo "  - Automatically redirects to Keycloak SSO"
echo "  - Requires 'administrators' group membership"
echo ""
echo "Architecture:"
echo "  User → Traefik → OAuth2 Proxy → Keycloak (validates)"
echo "                     ↓"
echo "                  pgAdmin (isolated on pgadmin-net)"
echo ""
echo "Check status:"
echo "  docker logs pgadmin --tail 20"
echo "  docker logs pgadmin-auth-proxy --tail 20"
