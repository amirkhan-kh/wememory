#!/usr/bin/env bash
# Build a shareable test APK for Contabo download page.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
APP="$ROOT/wamemory"
OUT_DIR="$ROOT/deploy/web/download"
export PATH="$PATH:$HOME/development/flutter/bin"

# Prefer OpenJDK 17 — Android Studio JBR 25+ often breaks current AGP.
# Override even if JAVA_HOME already points at Studio.
_jdk17=""
for candidate in \
  "$HOME/development/jdk-17/Contents/Home" \
  /opt/homebrew/opt/openjdk@17/libexec/openjdk.jdk/Contents/Home \
  /Library/Java/JavaVirtualMachines/temurin-17.jdk/Contents/Home
do
  if [[ -x "$candidate/bin/java" ]]; then
    _jdk17="$candidate"
    break
  fi
done
if [[ -n "$_jdk17" ]]; then
  export JAVA_HOME="$_jdk17"
fi
if [[ -n "${JAVA_HOME:-}" ]]; then
  export PATH="$JAVA_HOME/bin:$PATH"
  echo "Using JAVA_HOME=$JAVA_HOME"
  java -version
fi

if ! command -v flutter >/dev/null 2>&1; then
  echo "flutter not found. Run ./scripts/install-flutter-from-zip.sh first."
  exit 1
fi

cd "$APP"
if [[ ! -f android/app/build.gradle && ! -f android/app/build.gradle.kts ]]; then
  echo "Android project incomplete. Run ./scripts/bootstrap-flutter.sh first."
  exit 1
fi

# Prefer debug APK for owner test (faster, no signing hassle); RELEASE=1 for release
flutter pub get

# Contabo download APK must hit the public demo API (not Mac LAN / emulator).
# Local override: WAMEMORY_API_BASE=http://192.168.x.x:3100/api ./scripts/build-apk.sh
# Emulator: WAMEMORY_API_BASE=http://10.0.2.2:3100/api ./scripts/build-apk.sh
API_BASE="${WAMEMORY_API_BASE:-http://13.140.202.159:8090/api}"
echo "WAMEMORY_API_BASE=$API_BASE"
DART_DEFINES=(--dart-define="WAMEMORY_API_BASE=$API_BASE")

if [[ "${RELEASE:-0}" == "1" ]]; then
  flutter build apk --release "${DART_DEFINES[@]}"
  APK_SRC="$APP/build/app/outputs/flutter-apk/app-release.apk"
else
  flutter build apk --debug "${DART_DEFINES[@]}"
  APK_SRC="$APP/build/app/outputs/flutter-apk/app-debug.apk"
fi

mkdir -p "$OUT_DIR"

# A stub/missing NDK makes the strip task emit empty output and the APK ships
# without libflutter.so, which crashes on launch. Refuse to publish such an APK.
# List into a var first — `grep -q` + pipefail + SIGPIPE falsely fails while lib exists.
_apk_listing="$(unzip -Z1 "$APK_SRC" 2>/dev/null || unzip -l "$APK_SRC")"
if ! grep -Fq "lib/arm64-v8a/libflutter.so" <<<"$_apk_listing"; then
  echo "ERROR: $APK_SRC has no lib/arm64-v8a/libflutter.so — install a real NDK (sdkmanager 'ndk;27.0.12077973') and rebuild."
  exit 1
fi
unset _apk_listing

cp "$APK_SRC" "$OUT_DIR/wamemory-test.apk"
ls -lh "$OUT_DIR/wamemory-test.apk"
echo ""
echo "APK ready for Contabo:"
echo "  $OUT_DIR/wamemory-test.apk"
echo "Upload:"
echo "  ./scripts/deploy-contabo.sh user@YOUR_SERVER_IP"
