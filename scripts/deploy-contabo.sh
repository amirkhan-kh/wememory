#!/usr/bin/env bash
# Contabo sync = GitHub pull only (no rsync, no Docker up).
# Usage: ./scripts/deploy-contabo.sh [user@HOST]
# Default host: adminamirdev@13.140.202.159
set -euo pipefail

REMOTE="${1:-adminamirdev@13.140.202.159}"
REMOTE_DIR="${2:-projects/wememory-mobile}"
REPO_URL="https://github.com/amirkhan-kh/wememory-mobile.git"

echo "→ Ensure clone on $REMOTE:~/$REMOTE_DIR"
ssh "$REMOTE" "set -euo pipefail
if [[ ! -d \$HOME/$REMOTE_DIR/.git ]]; then
  mkdir -p \"\$(dirname \$HOME/$REMOTE_DIR)\"
  git clone '$REPO_URL' \"\$HOME/$REMOTE_DIR\"
fi
cd \"\$HOME/$REMOTE_DIR\"
git remote set-url origin '$REPO_URL'
./scripts/server-update.sh
"

echo ""
echo "Done. Code on server matches GitHub main."
echo "Dev containers: Mac → kdev on && kdev up (Kiri)."
echo "APK (optional): ./scripts/build-apk.sh then rsync deploy/web/download/*.apk if needed."
