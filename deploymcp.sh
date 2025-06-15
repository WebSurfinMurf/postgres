#!/bin/bash
set -e

echo "Loading environment variables..."
set -a
source /home/websurfinmurf/projects/secrets/postgres.env
source /home/websurfinmurf/projects/secrets/postgres-mcp.env
set +a

echo "Starting MCP server container..."
docker run -d \
  --name "${MCP_SERVER_NAME}" \
  --env DATABASE_URI="${DATABASE_URI}" \
  --env MCP_DB_HOST="${MCP_DB_HOST}" \
  --env MCP_DB_NAME="${MCP_DB_NAME}" \
  --env MCP_DB_USER="${MCP_DB_USER}" \
  --env MCP_DB_PASS="${MCP_DB_PASS}" \
  -p "${EPORT}:${IPORT}" \
  "${MCP_IMAGE}" \
  --access-mode=unrestricted

echo "✅ PostgreSQL '$POSTGRES_CONTAINER_NAME' running on port ${IPORT}"
echo "✅ MCP server '$MCP_SERVER_NAME' running on port ${EPORT}"
