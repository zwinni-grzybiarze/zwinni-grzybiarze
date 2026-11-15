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
  
  static const keycloakIssuer = String.fromEnvironment(
  'KEYCLOAK_ISSUER',
  defaultValue: 'http://localhost:8081/realms/onlyshrooms',
  );
    
  static const keycloakClientId = String.fromEnvironment(
    'KEYCLOAK_CLIENT_ID',
    defaultValue: 'onlyshrooms-web',
  );
  
  static const oidcRedirectUri = String.fromEnvironment(
    'OIDC_REDIRECT_URI',
    defaultValue: 'http://localhost:8080/redirect.html',
  );
  
  static const oidcPostLogoutRedirectUri = String.fromEnvironment(
    'OIDC_POST_LOGOUT_REDIRECT_URI',
    defaultValue: 'http://localhost:8080/redirect.html',
  );
}
