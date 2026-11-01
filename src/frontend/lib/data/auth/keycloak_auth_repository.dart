import 'package:oidc/oidc.dart';
import 'package:onlyshrooms/data/auth/auth_repository.dart';
import 'package:onlyshrooms/domain/grzybiarz.dart';

class KeycloakAuthRepository implements AuthRepository {
  KeycloakAuthRepository(this._manager);

  final OidcUserManager _manager;

  @override
  Grzybiarz? get currentUser => _toGrzybiarz(_manager.currentUser);

  @override
  bool get isSignedIn => _manager.currentUser != null;

  @override
  Stream<Grzybiarz?> get authStateChanges =>
      _manager.userChangesAfterInit().map(_toGrzybiarz);

  @override
  Future<void> restoreSession() => _manager.init();

  @override
  Future<Grzybiarz> signInWithGoogle({bool register = false}) async {
    final user = await _manager.loginAuthorizationCodeFlow(
      originalUri: Uri.parse('/'),
      extraParameters: const {'kc_idp_hint': 'google'},
    );

    final grzybiarz = _toGrzybiarz(user ?? _manager.currentUser);
    if (grzybiarz == null) {
      throw StateError('Google sign-in completed without a user.');
    }
    return grzybiarz;
  }

  @override
  Future<void> signOut() => _manager.logout();

  Grzybiarz? _toGrzybiarz(OidcUser? user) {
    if (user == null) return null;

    final claims = user.aggregatedClaims;
    String stringClaim(String key) =>
        claims[key] is String ? claims[key] as String : '';

    return Grzybiarz(
      id: user.uidRequired,
      imie: stringClaim('given_name'),
      nazwisko: stringClaim('family_name'),
      email: claims['email'] is String ? claims['email'] as String : null,
    );
  }
}