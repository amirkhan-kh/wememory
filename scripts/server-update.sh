#!/usr/bin/env bash
# Contabo: git pull + bring up API stack (phone-reachable).
# Run ON the server:
#   cd ~/projects/wememory-mobile && ./scripts/server-update.sh
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

echo "→ git fetch + pull (main)"
git fetch origin
git checkout main
git pull --ff-only origin main

echo "→ HEAD: $(git log -1 --oneline)"

DEPLOY="$ROOT/deploy"
cd "$DEPLOY"

if [[ ! -f .env ]]; then
  echo "deploy/.env missing."
  echo "  cp deploy/.env.example deploy/.env"
  echo "  nano deploy/.env   # set JWT_SECRET + POSTGRES_PASSWORD"
  echo "  Then re-run this script."
  exit 2
fi

# shellcheck disable=SC1091
set -a
# shellcheck source=/dev/null
source .env
set +a

HTTP_PORT="${HTTP_PORT:-8090}"

echo "→ docker compose -p wamemory up -d --build"
docker compose -p wamemory up -d --build

echo "→ health (port $HTTP_PORT)"
ok=0
for i in 1 2 3 4 5 6 7 8 9 10; do
  if curl -fsS "http://127.0.0.1:${HTTP_PORT}/api/health" >/dev/null 2>&1; then
    curl -fsS "http://127.0.0.1:${HTTP_PORT}/api/health"
    echo
    ok=1
    break
  fi
  sleep 2
done
if [[ "$ok" -ne 1 ]]; then
  echo "WARN: health not ready yet. Check: docker compose -p wamemory ps"
  exit 1
fi

echo ""
echo "Phone API: http://13.140.202.159:${HTTP_PORT}/api"
echo "APK page:  http://13.140.202.159:${HTTP_PORT}/"
echo "APK file:  http://13.140.202.159:${HTTP_PORT}/download/wamemory-test.apk"
