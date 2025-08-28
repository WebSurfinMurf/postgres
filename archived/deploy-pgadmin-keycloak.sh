#!/bin/bash
set -e

echo "Loading environment variables..."
set -a
source /home/administrator/projects/secrets/postgres.env
set +a

echo "Removing existing containers if they exist..."
docker rm -f "$PGADMIN_CONTAINER_NAME" 2>/dev/null || true
docker rm -f pgadmin-auth-proxy 2>/dev/null || true

echo "Starting pgAdmin container (internal only)..."
docker run -d \
  --name "$PGADMIN_CONTAINER_NAME" \
  --network postgres-net \
  -e PGADMIN_DEFAULT_EMAIL="$PGADMIN_EMAIL" \
  -e PGADMIN_DEFAULT_PASSWORD="$PGADMIN_PASSWORD" \
  -e PGPASSFILE=/home/pgadmin/.pgpass \
  -v /home/administrator/projects/secrets/postgresservers.json:/pgadmin4/servers.json \
  -v /home/administrator/projects/secrets/.pgpass:/home/pgadmin/.pgpass \
  dpage/pgadmin4

# Connect pgAdmin to traefik-proxy network for OAuth2 proxy access
echo "Connecting pgAdmin to traefik-proxy network..."
docker network connect traefik-proxy "$PGADMIN_CONTAINER_NAME"

echo "Starting OAuth2 Proxy for pgAdmin..."
docker run -d \
  --name pgadmin-auth-proxy \
  --network traefik-proxy \
  -e OAUTH2_PROXY_UPSTREAMS="http://pgadmin:80/" \
  -e OAUTH2_PROXY_PROVIDER="keycloak-oidc" \
  -e OAUTH2_PROXY_OIDC_ISSUER_URL="https://keycloak.ai-servicers.com/realms/master" \
  -e OAUTH2_PROXY_SKIP_OIDC_DISCOVERY="true" \
  -e OAUTH2_PROXY_OIDC_JWKS_URL="http://keycloak:8080/realms/master/protocol/openid-connect/certs" \
  -e OAUTH2_PROXY_LOGIN_URL="https://keycloak.ai-servicers.com/realms/master/protocol/openid-connect/auth" \
  -e OAUTH2_PROXY_REDEEM_URL="http://keycloak:8080/realms/master/protocol/openid-connect/token" \
  -e OAUTH2_PROXY_CLIENT_ID="$PGADMIN_OAUTH2_CLIENT_ID" \
  -e OAUTH2_PROXY_CLIENT_SECRET="$PGADMIN_OAUTH2_CLIENT_SECRET" \
  -e OAUTH2_PROXY_COOKIE_SECRET="$PGADMIN_OAUTH2_COOKIE_SECRET" \
  -e OAUTH2_PROXY_EMAIL_DOMAINS="*" \
  -e OAUTH2_PROXY_COOKIE_SECURE="true" \
  -e OAUTH2_PROXY_COOKIE_HTTPONLY="true" \
  -e OAUTH2_PROXY_HTTP_ADDRESS="0.0.0.0:4180" \
  -e OAUTH2_PROXY_REDIRECT_URL="https://pgadmin.ai-servicers.com/oauth2/callback" \
  -e OAUTH2_PROXY_SKIP_PROVIDER_BUTTON="true" \
  -e OAUTH2_PROXY_SCOPE="openid email profile" \
  -e OAUTH2_PROXY_PASS_HOST_HEADER="false" \
  -e OAUTH2_PROXY_PROXY_PREFIX="/oauth2" \
  -e OAUTH2_PROXY_SET_AUTHORIZATION_HEADER="true" \
  -e OAUTH2_PROXY_PASS_USER_HEADERS="true" \
  -e OAUTH2_PROXY_SET_XAUTHREQUEST="true" \
  -e OAUTH2_PROXY_ALLOWED_GROUPS="/administrators" \
  --label "traefik.enable=true" \
  --label "traefik.docker.network=traefik-proxy" \
  --label "traefik.http.routers.pgadmin-auth.rule=Host(\`pgadmin.ai-servicers.com\`)" \
  --label "traefik.http.routers.pgadmin-auth.entrypoints=websecure" \
  --label "traefik.http.routers.pgadmin-auth.tls=true" \
  --label "traefik.http.routers.pgadmin-auth.tls.certresolver=letsencrypt" \
  --label "traefik.http.services.pgadmin-auth.loadbalancer.server.port=4180" \
  quay.io/oauth2-proxy/oauth2-proxy:latest

echo "✅ pgAdmin with Keycloak authentication deployed successfully!"
echo ""
echo "External access: https://pgadmin.ai-servicers.com"
echo "  - Requires Keycloak login (administrators group only)"
echo ""
echo "Direct pgAdmin credentials (if needed):"
echo "  Email: $PGADMIN_EMAIL"
echo "  Password: (see secrets/postgres.env)"
echo ""
echo "To check status:"
echo "  docker logs pgadmin-auth-proxy --tail 20"
echo "  docker logs pgadmin --tail 20"