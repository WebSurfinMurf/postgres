#!/bin/bash
set -e

echo "📥 Loading environment variables..."
set -a
source /home/websurfinmurf/projects/secrets/postgres.env
source /home/websurfinmurf/projects/secrets/postgres-mcp.env
set +a

echo "🛑 Stopping and removing existing MCP server container if present..."
docker rm -f "${MCP_SERVER_NAME}" 2>/dev/null || true

echo "🚀 Starting new Postgres MCP container using ${MCP_IMAGE}..."
docker run -d \
  --name "${MCP_SERVER_NAME}" \
  -p "${EPORT}:${IPORT}" \
  "${MCP_IMAGE}" \
  --uri "${DATABASE_URI}" \
  --unrestricted

echo "✅ MCP Server '${MCP_SERVER_NAME}' running"
echo "🌐 Accessible at http://localhost:${EPORT}"
