#!/bin/bash
################################################################################
# PostgreSQL Manual Checkpoint/Save All Databases
################################################################################
# Location: /home/administrator/projects/postgres/manualsavealldb.sh
#
# Purpose: Forces PostgreSQL to flush all pending writes to disk before backup
# This ensures database consistency during backup operations.
#
# Called by: backup scripts before creating tar archives
################################################################################

set -e

echo "=== PostgreSQL: Forcing checkpoint to save all data to disk ==="

# Get the admin username from postgres container
POSTGRES_USER=$(docker exec postgres env | grep POSTGRES_USER | cut -d= -f2)

if [ -z "$POSTGRES_USER" ]; then
    echo "ERROR: Could not determine PostgreSQL admin user"
    exit 1
fi

echo "Using PostgreSQL user: $POSTGRES_USER"

# Run CHECKPOINT command to flush all dirty buffers to disk
echo "Running CHECKPOINT command..."
docker exec postgres psql -U "$POSTGRES_USER" -d postgres -c "CHECKPOINT;" >/dev/null 2>&1

if [ $? -eq 0 ]; then
    echo "✓ PostgreSQL checkpoint completed successfully"
    echo "  All dirty buffers have been written to disk"
    echo "  Database is in consistent state for backup"
else
    echo "✗ PostgreSQL checkpoint failed"
    exit 1
fi

# Also checkpoint keycloak-postgres if it exists
if docker ps --format "{{.Names}}" | grep -q "^keycloak-postgres$"; then
    echo ""
    echo "=== Keycloak PostgreSQL: Forcing checkpoint ==="

    KEYCLOAK_USER=$(docker exec keycloak-postgres env | grep POSTGRES_USER | cut -d= -f2)
    echo "Using PostgreSQL user: $KEYCLOAK_USER"

    docker exec keycloak-postgres psql -U "$KEYCLOAK_USER" -d postgres -c "CHECKPOINT;" >/dev/null 2>&1

    if [ $? -eq 0 ]; then
        echo "✓ Keycloak PostgreSQL checkpoint completed successfully"
    else
        echo "✗ Keycloak PostgreSQL checkpoint failed"
    fi
fi

echo ""
echo "=== PostgreSQL save operation complete ==="
