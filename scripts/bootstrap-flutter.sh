#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
APP="$ROOT/wamemory"
FLUTTER_HOME="${FLUTTER_HOME:-$HOME/development/flutter}"
ZIP="/tmp/flutter_macos_arm64.zip"

if [[ ! -x "$FLUTTER_HOME/bin/flutter" ]]; then
  echo "Installing Flutter SDK to $FLUTTER_HOME ..."
  mkdir -p "$(dirname "$FLUTTER_HOME")"
  if [[ ! -f "$ZIP" ]] || [[ $(stat -f%z "$ZIP" 2>/dev/null || echo 0) -lt 1500000000 ]]; then
    echo "Downloading Flutter stable (resume supported)..."
    curl -L --http1.1 -C - -o "$ZIP" \
      "https://storage.googleapis.com/flutter_infra_release/releases/stable/macos/flutter_macos_arm64_3.35.5-stable.zip"
  fi
  rm -rf "$FLUTTER_HOME"
  unzip -q "$ZIP" -d "$(dirname "$FLUTTER_HOME")"
fi

export PATH="$PATH:$FLUTTER_HOME/bin"
# flutter config --no-analytics (skipped)
# flutter doctor skipped

# Preserve custom Kotlin + manifest
TMP_KT=$(mktemp -d)
cp -R "$APP/android/app/src/main/kotlin" "$TMP_KT/" 2>/dev/null || true
cp "$APP/android/app/src/main/AndroidManifest.xml" "$TMP_KT/AndroidManifest.xml" 2>/dev/null || true

cd "$APP"
flutter create . --project-name app --org com.wamemory --platforms=android

# Restore native bridge
if [[ -d "$TMP_KT/kotlin" ]]; then
  mkdir -p android/app/src/main
  rm -rf android/app/src/main/kotlin
  cp -R "$TMP_KT/kotlin" android/app/src/main/
fi
if [[ -f "$TMP_KT/AndroidManifest.xml" ]]; then
  cp "$TMP_KT/AndroidManifest.xml" android/app/src/main/AndroidManifest.xml
fi

flutter pub get
echo ""
echo "Done. Run:"
echo "  export PATH=\"\$PATH:$FLUTTER_HOME/bin\""
echo "  cd $APP && flutter run"
