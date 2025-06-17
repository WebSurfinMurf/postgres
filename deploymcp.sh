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

HOST_IP=$(getent hosts "${MCP_DB_HOST}" | awk '{ print $1 }')
if [ -z "$HOST_IP" ]; then
  echo "❌ Failed to resolve IP for '${MCP_DB_HOST}'"
  exit 1
fi

echo "📡 Resolved ${MCP_DB_HOST} to ${HOST_IP}"

echo "Starting MCP server container..."
echo "docker run --rm -it --name ${MCP_SERVER_NAME}   --add-host=host.docker.internal:${HOST_IP} -p ${EPORT}:${IPORT} ${MCP_IMAGE} ${DATABASE_URI} --access-mode=unrestricted"
docker run -d \
  --name "${MCP_SERVER_NAME}" \
  --add-host=host.docker.internal:"${HOST_IP}" \
  -p "${EPORT}:${IPORT}" \
  "${MCP_IMAGE}" \
  "${DATABASE_URI}" \
  --access-mode=unrestricted

echo "✅ MCP Server connection '$DATABASE_URI' running on port ${IPORT}"
echo "✅ MCP server '$MCP_SERVER_NAME' running on port ${EPORT}"
