#!/bin/bash
set -e

echo "Pulling latest from GitHub..."
git pull origin main

echo "Loading environment variables..."
set -a
source /home/websurfinmurf/projects/secrets/postgres.env
set +a

echo "Starting PostgreSQL container..."
docker-compose up -d

echo "Deployment complete."
