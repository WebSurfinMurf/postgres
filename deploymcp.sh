#!/bin/bash
set -e

echo "Loading environment variables..."
set -a
source /home/websurfinmurf/projects/secrets/postgres.env
source /home/websurfinmurf/projects/secrets/postgres-mcp.env
set +a

echo "Stopping and removing any existing MCP server container..."
echo "docker rm -f ${MCP_SERVER_NAME}"
docker rm -f "${MCP_SERVER_NAME}" 2>/dev/null || true

echo "Starting MCP server container..."
echo "docker run --rm -it --name ${MCP_SERVER_NAME} -p ${EPORT}:${IPORT} ${MCP_IMAGE} ${DATABASE_URI} --access-mode=unrestricted"
docker run -d \
  --name "${MCP_SERVER_NAME}" \
  -p "${EPORT}:${IPORT}" \
  "${MCP_IMAGE}" \
  "${DATABASE_URI}" \
  --access-mode=unrestricted

echo "✅ MCP Server connection '$DATABASE_URI' running on port ${IPORT}"
echo "✅ MCP server '$MCP_SERVER_NAME' running on port ${EPORT}"
