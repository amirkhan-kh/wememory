Put the test APK here as:

  wamemory-test.apk

Build on Mac:
  ./scripts/build-apk.sh

Upload to Contabo:
  scp wamemory/build/app/outputs/flutter-apk/app-release.apk \
    user@YOUR_SERVER:/path/to/mobile/deploy/web/download/wamemory-test.apk
