#!/bin/bash
set -e

echo " Loading environment variables..."
set -a
source /home/websurfinmurf/projects/secrets/postgres.env
source /home/websurfinmurf/projects/secrets/postgres-mcp.env
set +a

echo " Stopping and removing any existing MCP server container..."
docker rm -f "${MCP_SERVER_NAME}" 2>/dev/null || true

echo " Starting MCP server container..."
docker run -d \
  --name "${MCP_SERVER_NAME}" \
  -p "${EPORT}:${IPORT}" \
  "${MCP_IMAGE}" \
  "${DATABASE_URI}" \
  --access-mode=unrestricted \
  --transport=stdio

echo "✅ MCP Server is running:"
echo "    URI: ${DATABASE_URI}"
echo "    Internal Port: ${IPORT}"
echo "    External Port: ${EPORT}"
echo "    Container Name: ${MCP_SERVER_NAME}"
