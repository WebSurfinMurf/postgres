#!/bin/bash
set -e

echo "🚀 Deploying pgAdmin"
echo "==================================="
echo ""

# Script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

# Environment file
ENV_FILE="/home/administrator/secrets/postgres.env"

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# --- Pre-deployment Checks ---
echo "🔍 Pre-deployment checks..."

# Check environment file
if [ ! -f "$ENV_FILE" ]; then
    echo -e "${RED}❌ Environment file not found: $ENV_FILE${NC}"
    exit 1
fi
echo -e "${GREEN}✅ Environment file exists${NC}"

# Source environment variables
set -o allexport
source "$ENV_FILE"
set +o allexport

# Validate required variables
required_vars=("PGADMIN_EMAIL" "PGADMIN_PASSWORD" "PGADMIN_OAUTH2_CLIENT_ID" "PGADMIN_OAUTH2_CLIENT_SECRET")

for var in "${required_vars[@]}"; do
    if [[ -z "${!var:-}" ]]; then
        echo -e "${RED}❌ Required variable $var is not set${NC}"
        exit 1
    fi
done
echo -e "${GREEN}✅ Environment variables validated${NC}"

# Check if networks exist
for network in postgres-net traefik-net; do
    if ! docker network inspect "$network" &>/dev/null; then
        echo -e "${RED}❌ $network network not found${NC}"
        echo "Run: /home/administrator/projects/infrastructure/setup-networks.sh"
        exit 1
    fi
done
echo -e "${GREEN}✅ All required networks exist${NC}"

# Check required files
if [ ! -f "/home/administrator/secrets/postgresservers.json" ]; then
    echo -e "${RED}❌ postgresservers.json not found${NC}"
    exit 1
fi

if [ ! -f "/home/administrator/secrets/.pgpass" ]; then
    echo -e "${RED}❌ .pgpass not found${NC}"
    exit 1
fi

if [ ! -f "$SCRIPT_DIR/pgadmin-oauth2-config.py" ]; then
    echo -e "${RED}❌ pgadmin-oauth2-config.py not found${NC}"
    exit 1
fi
echo -e "${GREEN}✅ Configuration files exist${NC}"

# Check/create volume
if ! docker volume inspect pgadmin_data &>/dev/null; then
    echo "Creating pgadmin_data volume..."
    docker volume create pgadmin_data
fi
echo -e "${GREEN}✅ pgAdmin data volume ready${NC}"

# Validate docker-compose.yml syntax
echo ""
echo "✅ Validating docker-compose.pgadmin.yml..."
if ! docker compose -f docker-compose.pgadmin.yml config > /dev/null 2>&1; then
    echo -e "${RED}❌ docker-compose.pgadmin.yml validation failed${NC}"
    docker compose -f docker-compose.pgadmin.yml config
    exit 1
fi
echo -e "${GREEN}✅ docker-compose.pgadmin.yml is valid${NC}"

# --- Deployment ---
echo ""
echo "🚀 Deploying pgAdmin..."
docker compose -f docker-compose.pgadmin.yml up -d --remove-orphans

# --- Post-deployment Validation ---
echo ""
echo "⏳ Waiting for pgAdmin to be ready..."
timeout 30 bash -c 'until docker logs pgadmin 2>&1 | grep -q "Listening at:"; do sleep 2; done' || {
    echo -e "${RED}❌ pgAdmin failed to start${NC}"
    docker logs pgadmin --tail 30
    exit 1
}
echo -e "${GREEN}✅ pgAdmin is ready${NC}"

# --- Summary ---
echo ""
echo "=========================================="
echo "✅ pgAdmin Deployment Summary"
echo "=========================================="
echo "Container: ${PGADMIN_CONTAINER_NAME:-pgadmin}"
echo "Image: dpage/pgadmin4:latest"
echo "Networks: postgres-net, traefik-net"
echo ""
echo "Access:"
echo "  - External: https://pgadmin.ai-servicers.com"
echo "  - Local: http://localhost:${PGADMIN_PORT:-8901}"
echo ""
echo "Authentication:"
echo "  - SSO: Click 'Sign in with Keycloak SSO'"
echo "  - Fallback: ${PGADMIN_EMAIL}"
echo ""
echo "Pre-configured Servers:"
echo "  - Main PostgreSQL (postgres:5432)"
echo "  - Keycloak PostgreSQL (keycloak-postgres:5432)"
echo "  - TimescaleDB (timescaledb:5432)"
echo ""
echo "=========================================="
echo ""
echo "📊 View logs:"
echo "   docker logs pgadmin -f"
echo ""
echo "✅ Deployment complete!"
