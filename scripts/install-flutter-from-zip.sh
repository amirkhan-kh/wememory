#!/usr/bin/env bash
set -euo pipefail

ZIP_CANDIDATES=(
  "/tmp/flutter_macos_arm64.zip"
  "$HOME/Downloads/flutter_macos_arm64_3.35.5-stable.zip"
  "$HOME/Downloads/flutter_macos_arm64.zip"
)

ZIP=""
for c in "${ZIP_CANDIDATES[@]}"; do
  if [[ -f "$c" ]]; then
    SIZE=$(stat -f%z "$c" 2>/dev/null || echo 0)
    # expect ~1.8GB; allow >= 1.5GB
    if (( SIZE >= 1500000000 )); then
      ZIP="$c"
      break
    fi
    echo "Found incomplete zip: $c ($(numfmt --to=iec "$SIZE" 2>/dev/null || echo "$SIZE" bytes))"
  fi
done

if [[ -z "$ZIP" ]]; then
  echo "Complete Flutter ZIP not found (>= 1.5 GB)."
  echo "Download:"
  echo "  https://storage.googleapis.com/flutter_infra_release/releases/stable/macos/flutter_macos_arm64_3.35.5-stable.zip"
  echo "Or wait for /tmp/flutter_macos_arm64.zip to finish."
  exit 1
fi

echo "Using: $ZIP"
mkdir -p "$HOME/development"
rm -rf "$HOME/development/flutter"
unzip -q "$ZIP" -d "$HOME/development"

# ZIP extracts to ~/development/flutter
if [[ ! -x "$HOME/development/flutter/bin/flutter" ]]; then
  echo "Flutter binary missing after unzip"
  exit 1
fi

if ! grep -q 'development/flutter/bin' "$HOME/.zshrc" 2>/dev/null; then
  echo 'export PATH="$PATH:$HOME/development/flutter/bin"' >> "$HOME/.zshrc"
fi

export PATH="$PATH:$HOME/development/flutter/bin"
# skipped
flutter --version
echo ""
echo "Next:"
echo "  source ~/.zshrc"
echo "  flutter doctor"
echo "  cd $(cd "$(dirname "$0")/.." && pwd) && ./scripts/bootstrap-flutter.sh"
