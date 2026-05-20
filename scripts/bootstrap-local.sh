#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

if ! command -v docker >/dev/null 2>&1; then
  echo "Docker is required to start the local stack." >&2
  exit 1
fi

if [[ ! -f .env ]]; then
  cp config.example.env .env
  echo "Created .env from config.example.env."
fi

if docker compose version >/dev/null 2>&1; then
  COMPOSE_CMD=(docker compose)
elif command -v docker-compose >/dev/null 2>&1; then
  COMPOSE_CMD=(docker-compose)
else
  echo "Docker Compose is required." >&2
  exit 1
fi

echo "Starting InfraOps Agent Hub local mock services."
"${COMPOSE_CMD[@]}" up -d postgres n8n

echo "Local stack requested. n8n will be available at http://localhost:${N8N_PORT:-5678} after startup."
echo "This scaffold runs in mock mode and does not call real AWS, Slack, GitHub, or LLM APIs."
