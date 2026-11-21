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

# Default RELEASE — debug APK is ~140MB and often truncates on phone → "Parse error".
# Debug override: DEBUG=1 ./scripts/build-apk.sh
flutter pub get

# Contabo download APK must hit the public demo API (not Mac LAN / emulator).
# Local override: WAMEMORY_API_BASE=http://192.168.x.x:3100/api ./scripts/build-apk.sh
# Emulator: WAMEMORY_API_BASE=http://10.0.2.2:3100/api ./scripts/build-apk.sh
API_BASE="${WAMEMORY_API_BASE:-http://13.140.202.159:8090/api}"
echo "WAMEMORY_API_BASE=$API_BASE"
DART_DEFINES=(--dart-define="WAMEMORY_API_BASE=$API_BASE")

# Phone ABIs only (skip x86_64) → smaller download, fewer truncated installs.
PLATFORMS=(--target-platform=android-arm,android-arm64)

if [[ "${DEBUG:-0}" == "1" ]]; then
  flutter build apk --debug "${PLATFORMS[@]}" "${DART_DEFINES[@]}"
  APK_SRC="$APP/build/app/outputs/flutter-apk/app-debug.apk"
else
  flutter build apk --release "${PLATFORMS[@]}" "${DART_DEFINES[@]}"
  APK_SRC="$APP/build/app/outputs/flutter-apk/app-release.apk"
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

# Refuse oversized sideload APKs (debug bloat / bad strip) — phones truncate → parse failed.
_apk_bytes="$(wc -c <"$APK_SRC" | tr -d ' ')"
_max_bytes=$((80 * 1024 * 1024))
if [[ "$_apk_bytes" -gt "$_max_bytes" ]]; then
  echo "ERROR: $APK_SRC is ${_apk_bytes} bytes (>80MB). Use release build (default); DEBUG=1 is for USB only."
  exit 1
fi
unset _apk_bytes _max_bytes

cp "$APK_SRC" "$OUT_DIR/wamemory-test.apk"

# Ensure v1+v2(+v3) for OEM sideload parsers (AGP may skip v1 when minSdk>=24).
_apksigner=""
for _bt in "$HOME/Library/Android/sdk/build-tools"/*; do
  if [[ -x "$_bt/apksigner" ]]; then _apksigner="$_bt/apksigner"; fi
done
_debug_ks="${HOME}/.android/debug.keystore"
if [[ -n "$_apksigner" && -f "$_debug_ks" ]]; then
  _tmp_unsigned="$(mktemp /tmp/wamemory-unsigned.XXXXXX.apk)"
  cp "$OUT_DIR/wamemory-test.apk" "$_tmp_unsigned"
  zip -q -d "$_tmp_unsigned" 'META-INF/*.SF' 'META-INF/*.RSA' 'META-INF/*.MF' 2>/dev/null || true
  "$_apksigner" sign \
    --ks "$_debug_ks" \
    --ks-pass pass:android \
    --key-pass pass:android \
    --min-sdk-version 21 \
    --v1-signing-enabled true \
    --v2-signing-enabled true \
    --v3-signing-enabled true \
    --out "$OUT_DIR/wamemory-test.apk" \
    "$_tmp_unsigned"
  rm -f "$_tmp_unsigned"
  "$_apksigner" verify --print-certs "$OUT_DIR/wamemory-test.apk" >/dev/null
  echo "Signed with apksigner (v1+v2+v3)"
fi
unset _apksigner _bt _debug_ks _tmp_unsigned

(
  cd "$OUT_DIR"
  shasum -a 256 wamemory-test.apk | tee wamemory-test.apk.sha256
)
ls -lh "$OUT_DIR/wamemory-test.apk"
echo ""
echo "APK ready for Contabo:"
echo "  $OUT_DIR/wamemory-test.apk"
echo "Upload:"
echo "  rsync -az deploy/web/download/wamemory-test.apk* adminamirdev@13.140.202.159:projects/wememory-mobile/deploy/web/download/"
