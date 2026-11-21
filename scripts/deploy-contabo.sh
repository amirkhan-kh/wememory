#!/usr/bin/env bash
# Mac → Contabo: ensure git clone + server-update (API + Caddy for phone).
# Usage: ./scripts/deploy-contabo.sh [user@HOST]
set -euo pipefail

REMOTE="${1:-adminamirdev@13.140.202.159}"
REMOTE_DIR="${2:-projects/wememory-mobile}"
REPO_URL="https://github.com/amirkhan-kh/wememory-mobile.git"

echo "→ Clone/pull on $REMOTE:~/$REMOTE_DIR"
ssh "$REMOTE" "set -euo pipefail
if [[ ! -d \$HOME/$REMOTE_DIR/.git ]]; then
  mkdir -p \"\$(dirname \$HOME/$REMOTE_DIR)\"
  git clone '$REPO_URL' \"\$HOME/$REMOTE_DIR\"
fi
cd \"\$HOME/$REMOTE_DIR\"
git remote set-url origin '$REPO_URL'
if [[ ! -f deploy/.env ]]; then
  cp deploy/.env.example deploy/.env
  # random secrets (first boot only)
  JWT=\$(openssl rand -hex 32)
  DBP=\$(openssl rand -hex 16)
  sed -i \"s/^JWT_SECRET=.*/JWT_SECRET=\$JWT/\" deploy/.env
  sed -i \"s/^POSTGRES_PASSWORD=.*/POSTGRES_PASSWORD=\$DBP/\" deploy/.env
  chmod 600 deploy/.env
  echo 'Created deploy/.env with random secrets'
fi
chmod +x scripts/*.sh
./scripts/server-update.sh
"

echo ""
echo "Optional APK upload (after ./scripts/build-apk.sh):"
echo "  rsync -az deploy/web/download/wamemory-test.apk \\"
echo "    $REMOTE:$REMOTE_DIR/deploy/web/download/"
