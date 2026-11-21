/// Public Contabo endpoints used by the phone APK.
/// Override at build: `--dart-define=WAMEMORY_API_BASE=…`
class AppConfig {
  AppConfig._();

  static const contaboHost = '13.140.202.159';
  static const contaboHttpPort = '8090';

  /// Default Nest base including `/api` suffix.
  static const apiBase = String.fromEnvironment(
    'WAMEMORY_API_BASE',
    defaultValue: 'http://$contaboHost:$contaboHttpPort/api',
  );

  static String get apkDownloadUrl =>
      'http://$contaboHost:$contaboHttpPort/download/wamemory-test.apk';

  static String get healthUrl =>
      'http://$contaboHost:$contaboHttpPort/api/health';
}
