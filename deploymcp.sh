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
  -p "${EPORT}:${IPORT}" \
  "${MCP_IMAGE}" \
  "${DATABASE_URI}" \
  --access-mode=unrestricted

echo "✅ MCP Server connection '$DATABASE_URI' running on port ${IPORT}"
echo "✅ MCP server '$MCP_SERVER_NAME' running on port ${EPORT}"
