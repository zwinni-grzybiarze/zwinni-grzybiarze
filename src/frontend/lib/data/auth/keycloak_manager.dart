import 'package:oidc/oidc.dart';
import 'package:oidc_default_store/oidc_default_store.dart';
import 'package:onlyshrooms/core/config.dart';

final keycloakManager = OidcUserManager.lazy(
  discoveryDocumentUri: OidcUtils.getOpenIdConfigWellKnownUri(
    Uri.parse(AppConfig.keycloakIssuer),
),
clientCredentials: OidcClientAuthentication.none(
    clientId: AppConfig.keycloakClientId,
),
store: OidcDefaultStore(),
settings: OidcUserManagerSettings(
    redirectUri: Uri.parse(AppConfig.oidcRedirectUri),
    postLogoutRedirectUri: Uri.parse(AppConfig.oidcPostLogoutRedirectUri),
    scope: const ['openid', 'profile', 'email'],
  ),
);