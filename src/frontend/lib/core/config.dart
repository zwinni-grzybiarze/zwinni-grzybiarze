/// Compile-time configuration. Override with `--dart-define=...`.
class AppConfig {
  static const useMockData = bool.fromEnvironment(
    'USE_MOCK_DATA',
    defaultValue: true,
  );

  static const apiBase = String.fromEnvironment(
    'API_BASE',
    defaultValue: 'http://localhost:8080',
  );

  static const basicAuthUser = String.fromEnvironment(
    'BASIC_AUTH_USER',
    defaultValue: 'admin',
  );

  static const basicAuthPassword = String.fromEnvironment(
    'BASIC_AUTH_PASSWORD',
    defaultValue: 'admin',
  );
}
