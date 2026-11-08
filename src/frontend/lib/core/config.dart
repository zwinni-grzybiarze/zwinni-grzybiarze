import 'package:flutter/foundation.dart';

/// Compile-time configuration. Override with `--dart-define=...`.
class AppConfig {
  static const useMockData = bool.fromEnvironment(
    'USE_MOCK_DATA',
    defaultValue: false,
  );

  /// Docker/PWA builds pass `--dart-define=API_BASE=` (empty) so the app
  /// calls the same origin it was installed from (works on LAN phones).
  static const apiBaseDefine = String.fromEnvironment(
    'API_BASE',
    defaultValue: 'http://localhost:8080',
  );

  /// Resolved API origin used by Dio.
  static String get apiBase {
    if (apiBaseDefine.isNotEmpty) return apiBaseDefine;
    if (kIsWeb) return Uri.base.origin;
    return 'http://localhost:8080';
  }

  static const basicAuthUser = String.fromEnvironment(
    'BASIC_AUTH_USER',
    defaultValue: 'admin',
  );

  static const basicAuthPassword = String.fromEnvironment(
    'BASIC_AUTH_PASSWORD',
    defaultValue: 'admin',
  );
}
