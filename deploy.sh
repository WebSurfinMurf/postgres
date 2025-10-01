#!/bin/bash
set -e

echo "🚀 Deploying PostgreSQL Database"
echo "=================================="
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
required_vars=("POSTGRES_USER" "POSTGRES_PASSWORD")

for var in "${required_vars[@]}"; do
    if [[ -z "${!var:-}" ]]; then
        echo -e "${RED}❌ Required variable $var is not set${NC}"
        exit 1
    fi
done
echo -e "${GREEN}✅ Environment variables validated${NC}"

# Check if network exists
if ! docker network inspect postgres-net &>/dev/null; then
    echo -e "${RED}❌ postgres-net network not found${NC}"
    echo "Run: /home/administrator/projects/infrastructure/setup-networks.sh"
    exit 1
fi
echo -e "${GREEN}✅ postgres-net network exists${NC}"

# Check/create volume
if ! docker volume inspect postgres_data &>/dev/null; then
    echo "Creating postgres_data volume..."
    docker volume create postgres_data
fi
echo -e "${GREEN}✅ PostgreSQL data volume ready${NC}"

# Validate docker-compose.yml syntax
echo ""
echo "✅ Validating docker-compose.yml..."
if ! docker compose config > /dev/null 2>&1; then
    echo -e "${RED}❌ docker-compose.yml validation failed${NC}"
    docker compose config
    exit 1
fi
echo -e "${GREEN}✅ docker-compose.yml is valid${NC}"

# --- Deployment ---
echo ""
echo "🚀 Deploying PostgreSQL..."
docker compose up -d --remove-orphans

# --- Post-deployment Validation ---
echo ""
echo "⏳ Waiting for PostgreSQL to be ready..."
timeout 60 bash -c 'until docker exec postgres pg_isready -U ${POSTGRES_USER:-admin} -d ${POSTGRES_DB:-defaultdb} 2>/dev/null; do sleep 2; done' || {
    echo -e "${RED}❌ PostgreSQL failed to start${NC}"
    docker logs postgres --tail 30
    exit 1
}
echo -e "${GREEN}✅ PostgreSQL is ready${NC}"

# Get database list
echo ""
echo "📊 Database Status:"
docker exec postgres psql -U "${POSTGRES_USER}" -d postgres -c "\l" 2>/dev/null | grep -E "Name|-------|${POSTGRES_DB:-defaultdb}|postgres|template" | head -10

# --- Summary ---
echo ""
echo "=========================================="
echo "✅ PostgreSQL Deployment Summary"
echo "=========================================="
echo "Container: ${POSTGRES_CONTAINER_NAME:-postgres}"
echo "Image: ${POSTGRES_IMAGE:-postgres:15}"
echo "Network: postgres-net"
echo "Port: ${POSTGRES_PORT:-5432}"
echo ""
echo "Database Configuration:"
echo "  - Admin User: ${POSTGRES_USER}"
echo "  - Default Database: ${POSTGRES_DB:-defaultdb}"
echo "  - Data Volume: postgres_data"
echo ""
echo "Connection Strings:"
echo "  - Internal: postgresql://${POSTGRES_USER}:***@postgres:5432/${POSTGRES_DB:-defaultdb}"
echo "  - External: postgresql://${POSTGRES_USER}:***@localhost:${POSTGRES_PORT:-5432}/${POSTGRES_DB:-defaultdb}"
echo ""
echo "=========================================="
echo ""
echo "📊 View logs:"
echo "   docker logs postgres -f"
echo ""
echo "🔍 Connect via psql:"
echo "   docker exec -it postgres psql -U ${POSTGRES_USER} -d ${POSTGRES_DB:-defaultdb}"
echo ""
echo "📋 List databases:"
echo "   docker exec postgres psql -U ${POSTGRES_USER} -d postgres -c '\l'"
echo ""
echo "✅ Deployment complete!"
