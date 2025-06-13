#!/bin/bash
set -e

echo "🔐 Loading environment variables..."
set -a
source /home/websurfinmurf/projects/secrets/postgres.env
set +a

# Optional DB name (unused in full backup but kept for naming consistency)
DB_NAME="${1:-$POSTGRES_DB}"

TIMESTAMP=$(date +"%Y-%m-%d_%H-%M-%S")

# Use POSTGRES_BACKUP_DIR from env
ARCHIVE_FILE="$POSTGRES_BACKUP_DIR/${DB_NAME}_${TIMESTAMP}.tar.gz"

echo "📁 Ensuring backup directory exists at: $POSTGRES_BACKUP_DIR"
mkdir -p "$POSTGRES_BACKUP_DIR"

echo "🧠 Creating full volume backup for Docker volume: $POSTGRES_VOLUME"
docker run --rm \
  -v "$POSTGRES_VOLUME":/volume \
  -v "$POSTGRES_BACKUP_DIR":/backup \
  alpine \
  tar czf "/backup/$(basename "$ARCHIVE_FILE")" -C /volume .

echo "✅ Full volume backup complete: $ARCHIVE_FILE"
