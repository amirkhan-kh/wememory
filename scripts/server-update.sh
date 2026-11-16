#!/usr/bin/env bash
# Run ON THE SERVER inside the checkout: pull latest code and restart the stack.
# Usage: ~/projects/wamemory/scripts/server-update.sh
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

echo "→ git pull"
git pull --ff-only

if [[ ! -f deploy/.env ]]; then
  echo "deploy/.env missing — copy deploy/.env.example and fill it in."
  exit 2
fi

echo "→ docker compose up -d --build"
cd deploy
docker compose -p wamemory up -d --build

echo "→ health"
sleep 5
PORT="$(grep -E '^HTTP_PORT=' .env | cut -d= -f2)"
curl -fsS "http://127.0.0.1:${PORT:-80}/api/health" && echo
