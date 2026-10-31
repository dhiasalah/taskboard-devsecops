#!/bin/bash
# taskboard-up.sh — starts TaskBoard's pieces with docker run
# Run it from the project folder: ./scripts/taskboard-up.sh

set -e

if [ ! -f .env ]; then
  echo "❌ .env not found. Run me from the project folder."
  exit 1
fi

docker build -t taskboard-api:0.1 app/api
docker build -t taskboard-web:0.1 app/frontend

docker rm -f taskboard-db taskboard-api taskboard-web 2>/dev/null || true
docker network create taskboard-net 2>/dev/null || true
docker volume create taskboard-db-data

docker run -d --name taskboard-db \
  --network taskboard-net \
  --env-file .env \
  -v taskboard-db-data:/var/lib/postgresql \
  postgres:18-alpine

docker run -d --name taskboard-api \
  --network taskboard-net \
  --env-file .env \
  -e DB_HOST=taskboard-db \
  -p 127.0.0.1:5000:5000 \
  taskboard-api:0.1

docker run -d --name taskboard-web \
  --network taskboard-net \
  -p 127.0.0.1:8080:8080 \
  taskboard-web:0.1

echo "✅ TaskBoard is up: http://localhost:8080"

