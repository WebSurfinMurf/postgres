#!/bin/bash
set -e

echo "Pulling latest from GitHub..."
git pull origin main

echo "Starting PostgreSQL container..."
docker compose --env-file .env up -d

echo "Deployment complete."
