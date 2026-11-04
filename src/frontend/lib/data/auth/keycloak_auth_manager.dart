import 'package:oidc/oidc.dart';

class KeycloakIdentity {
  const KeycloakIdentity({required this.id, required this.claims});

  final String id;
  final Map<String, dynamic> claims;

  factory KeycloakIdentity.fromOidcUser(OidcUser user) =>
      KeycloakIdentity(id: user.uidRequired, claims: user.aggregatedClaims);
}

abstract interface class KeycloakAuthManager {
  KeycloakIdentity? get currentUser;

  Stream<KeycloakIdentity?> get userChanges;

  Future<String?> getAccessToken();

  Future<void> init();

  Future<KeycloakIdentity?> signInWithGoogle();

  Future<void> logout();
}

class OidcKeycloakAuthManager implements KeycloakAuthManager {
  OidcKeycloakAuthManager(this._manager);

  final OidcUserManager _manager;

  @override
  KeycloakIdentity? get currentUser => _toIdentity(_manager.currentUser);

  @override
  Stream<KeycloakIdentity?> get userChanges =>
      _manager.userChangesAfterInit().map(_toIdentity);

  @override
  Future<String?> getAccessToken() => _manager.getAccessToken();

  @override
  Future<void> init() => _manager.init();

  @override
  Future<KeycloakIdentity?> signInWithGoogle() async {
    final user = await _manager.loginAuthorizationCodeFlow(
      originalUri: Uri.parse('/'),
      extraParameters: const {'kc_idp_hint': 'google'},
    );
    return _toIdentity(user);
  }

  @override
  Future<void> logout() => _manager.logout();

  KeycloakIdentity? _toIdentity(OidcUser? user) =>
      user == null ? null : KeycloakIdentity.fromOidcUser(user);
}
