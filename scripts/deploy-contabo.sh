#!/usr/bin/env bash
# Sync project + bring up Contabo test stack.
# Usage: ./scripts/deploy-contabo.sh user@SERVER_IP [/remote/path]
set -euo pipefail

if [[ $# -lt 1 ]]; then
  echo "Usage: $0 user@SERVER_IP [/opt/wamemory]"
  exit 1
fi

REMOTE="$1"
REMOTE_DIR="${2:-/opt/wamemory}"
ROOT="$(cd "$(dirname "$0")/.." && pwd)"

echo "→ Sync to $REMOTE:$REMOTE_DIR"
ssh "$REMOTE" "mkdir -p '$REMOTE_DIR'"
rsync -avz --delete \
  --exclude node_modules \
  --exclude .git \
  --exclude wamemory/build \
  --exclude wamemory/.dart_tool \
  --exclude '**/__pycache__' \
  "$ROOT/" "$REMOTE:$REMOTE_DIR/"

echo "→ Ensure .env exists"
ssh "$REMOTE" "cd '$REMOTE_DIR/deploy' && if [[ ! -f .env ]]; then cp .env.example .env; echo 'EDIT deploy/.env then re-run'; exit 2; fi"

echo "→ Docker compose up"
ssh "$REMOTE" "cd '$REMOTE_DIR/deploy' && docker compose up -d --build"

echo "→ Health"
ssh "$REMOTE" "sleep 3; curl -fsS http://127.0.0.1:3000/api/health || curl -fsS https://\$(grep ^DOMAIN= '$REMOTE_DIR/deploy/.env' | cut -d= -f2)/api/health || true"

echo ""
echo "Done. Open https://YOUR_DOMAIN/ and download the APK if present."
echo "If APK missing: build locally with ./scripts/build-apk.sh then re-run this script."
