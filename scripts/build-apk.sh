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
if [[ "${RELEASE:-0}" == "1" ]]; then
  flutter build apk --release
  APK_SRC="$APP/build/app/outputs/flutter-apk/app-release.apk"
else
  flutter build apk --debug
  APK_SRC="$APP/build/app/outputs/flutter-apk/app-debug.apk"
fi

mkdir -p "$OUT_DIR"

# A stub/missing NDK makes the strip task emit empty output and the APK ships
# without libflutter.so, which crashes on launch. Refuse to publish such an APK.
if ! unzip -l "$APK_SRC" | grep -q "lib/arm64-v8a/libflutter.so"; then
  echo "ERROR: $APK_SRC has no lib/arm64-v8a/libflutter.so — install a real NDK (sdkmanager 'ndk;27.0.12077973') and rebuild."
  exit 1
fi

cp "$APK_SRC" "$OUT_DIR/wamemory-test.apk"
ls -lh "$OUT_DIR/wamemory-test.apk"
echo ""
echo "APK ready for Contabo:"
echo "  $OUT_DIR/wamemory-test.apk"
echo "Upload:"
echo "  ./scripts/deploy-contabo.sh user@YOUR_SERVER_IP"
