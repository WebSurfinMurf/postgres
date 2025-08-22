#!/bin/bash
set -e

echo "🔐 Loading environment variables..."
set -a
source /home/administrator/projects/secrets/postgres.env
set +a

# Required: database name (used for naming, not SQL-specific)
DB_NAME="$1"
if [[ -z "$DB_NAME" ]]; then
  echo "❌ Usage: $0 <db_name> [backup_file.tar.gz]"
  exit 1
fi

# Optional: specific backup filename
BACKUP_NAME="$2"

# Determine latest backup if not specified
if [[ -z "$BACKUP_NAME" ]]; then
  echo "🔎 Locating latest backup for database '$DB_NAME'..."
  BACKUP_NAME=$(ls -t "$POSTGRES_BACKUP_DIR"/${DB_NAME}_*.tar.gz 2>/dev/null | head -n 1)
  if [[ -z "$BACKUP_NAME" ]]; then
    echo "❌ No .tar.gz backups found for database '$DB_NAME' in $POSTGRES_BACKUP_DIR"
    exit 1
  fi
else
  BACKUP_NAME="$POSTGRES_BACKUP_DIR/$BACKUP_NAME"
  if [[ ! -f "$BACKUP_NAME" ]]; then
    echo "❌ Specified backup file does not exist: $BACKUP_NAME"
    exit 1
  fi
fi

echo "📦 Restoring from backup file: $BACKUP_NAME"

# Stop and remove container if running
echo "🛑 Stopping and removing existing container (if running)..."
docker rm -f "$POSTGRES_CONTAINER_NAME" 2>/dev/null || true

# Remove and recreate the volume
echo "🧼 Removing existing Docker volume: $POSTGRES_VOLUME"
docker volume rm "$POSTGRES_VOLUME" 2>/dev/null || true

echo "📁 Creating new Docker volume: $POSTGRES_VOLUME"
docker volume create "$POSTGRES_VOLUME"

# Restore backup contents into new volume
echo "📥 Extracting backup into volume..."
docker run --rm \
  -v "$POSTGRES_VOLUME":/volume \
  -v "$(dirname "$BACKUP_NAME")":/backup \
  alpine \
  sh -c "cd /volume && tar xzf /backup/$(basename "$BACKUP_NAME")"

# Relaunch PostgreSQL container
echo "🚀 Restarting PostgreSQL container..."
docker run -d \
  --name "$POSTGRES_CONTAINER_NAME" \
  -e POSTGRES_USER="$POSTGRES_USER" \
  -e POSTGRES_PASSWORD="$POSTGRES_PASSWORD" \
  -e POSTGRES_DB="$POSTGRES_DB" \
  -p "$POSTGRES_PORT":5432 \
  -v "$POSTGRES_VOLUME":/var/lib/postgresql/data \
  "$POSTGRES_IMAGE"

echo "✅ Restore complete. PostgreSQL is running from: $BACKUP_NAME"
