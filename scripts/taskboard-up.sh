#!/bin/bash
# taskboard-up.sh — starts TaskBoard's pieces with docker run
# Run it from the project folder: ./scripts/taskboard-up.sh

set -e

if [ ! -f .env ]; then
  echo "❌ .env not found. Run me from the project folder."
  exit 1
fi

docker network create taskboard-net || true
docker volume create taskboard-db-data

docker run -d --name taskboard-db \
  --network taskboard-net \
  --env-file .env \
  -v taskboard-db-data:/var/lib/postgresql \
  postgres:18-alpine

docker run -d --name taskboard-web \
  --network taskboard-net \
  -p 127.0.0.1:8080:80 \
  -v "$PWD/app/frontend:/usr/share/nginx/html:ro" \
  nginx:1.29-alpine

echo "✅ TaskBoard is up: http://localhost:8080"
