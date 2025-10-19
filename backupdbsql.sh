#!/bin/bash
set -e

echo "🔐 Loading environment variables..."
set -a
source $HOME/projects/secrets/postgres.env
set +a

# Allow optional DB name override
DB_NAME="${1:-$POSTGRES_DB}"

TIMESTAMP=$(date +"%Y-%m-%d_%H-%M-%S")

# Use POSTGRES_BACKUP_DIR from env
SQL_FILE="$POSTGRES_BACKUP_DIR/${DB_NAME}_${TIMESTAMP}.sql"
GZ_FILE="$SQL_FILE.gz"

echo "📁 Ensuring backup directory exists at: $POSTGRES_BACKUP_DIR"
mkdir -p "$POSTGRES_BACKUP_DIR"

echo "🧠 Dumping PostgreSQL database '$DB_NAME' to:"
echo "    $SQL_FILE"
docker exec -t "$POSTGRES_CONTAINER_NAME" pg_dump -U "$POSTGRES_USER" "$DB_NAME" > "$SQL_FILE"

echo "📦 Compressing SQL dump to:"
echo "    $GZ_FILE"
gzip "$SQL_FILE"

echo "✅ Backup complete: $GZ_FILE"
