#!/bin/bash
set -e

echo "Loading environment variables..."
set -a
source /home/websurfinmurf/projects/secrets/postgres.env
source /home/websurfinmurf/projects/secrets/postgres-mcp.env
set +a

echo "Stopping existing container if running..."
docker rm -f "${MCP_SERVER_NAME}" 2>/dev/null || true

echo "Starting MCP container with SSE enabled..."
docker run -d \
  --name "${MCP_SERVER_NAME}" \
  -p "${EPORT}:${IPORT}" \
  "${MCP_IMAGE}" \
  --transport=sse \
  --access-mode=unrestricted \
  --sse-host=0.0.0.0 \
  --sse-port="${IPORT}" \
  "${DATABASE_URI}"

echo "✅ MCP server '${MCP_SERVER_NAME}' running:"
echo "   ➤ Access via: http://localhost:${EPORT}/sse"
