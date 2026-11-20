#!/usr/bin/env bash
# Contabo: pull latest from GitHub. No Docker restart (stack moved to local Kiri).
# Run on the server inside the clone:
#   ~/projects/wememory-mobile/scripts/server-update.sh
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

echo "→ git fetch + pull (main)"
git fetch origin
git checkout main
git pull --ff-only origin main

echo "→ HEAD"
git log -1 --oneline
echo ""
echo "Done. Local/dev runtime: Mac da kdev on && kdev up"
echo "Serverda Docker stack bu loyiha uchun o‘chirilgan."
