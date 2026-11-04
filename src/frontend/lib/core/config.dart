/// Compile-time configuration. Override with `--dart-define=...`.
class AppConfig {
  static const useMockData = bool.fromEnvironment(
    'USE_MOCK_DATA',
    defaultValue: false,
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
