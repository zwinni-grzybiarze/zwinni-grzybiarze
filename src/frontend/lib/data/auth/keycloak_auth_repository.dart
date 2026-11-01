import 'package:oidc/oidc.dart';
import 'package:onlyshrooms/data/auth/auth_repository.dart';
import 'package:onlyshrooms/domain/grzybiarz.dart';
import 'package:dio/dio.dart';

class KeycloakAuthRepository implements AuthRepository {
  KeycloakAuthRepository(this._manager, this._api);

  final OidcUserManager _manager;
  final Dio _api;  
  @override
  Grzybiarz? get currentUser => _toGrzybiarz(_manager.currentUser);

  @override
  bool get isSignedIn => _manager.currentUser != null;

  @override
  Stream<Grzybiarz?> get authStateChanges =>
      _manager.userChangesAfterInit().map(_toGrzybiarz);

  Future<Grzybiarz> _provisionCurrentUser() async {
    final accessToken = await _manager.getAccessToken();
    if (accessToken == null) {
      throw StateError('Keycloak did not provide an access token.');
    }

    final response = await _api.post<Map<String, dynamic>>(
      '/api/auth/me',
      options: Options(
        headers: {'Authorization': 'Bearer $accessToken'},
      ),
    );

    final data = response.data;
    if (data == null || data['keycloakId'] is! String) {
      throw StateError('The API returned an invalid user response.');
    }

    return Grzybiarz(
      id: data['keycloakId'] as String,
      imie: data['imie'] as String? ?? '',
      nazwisko: data['nazwisko'] as String? ?? '',
      email: data['email'] as String?,
    );
  }

  @override
  Future<void> restoreSession() async {
    await _manager.init();
    if(_manager.currentUser != null) {
      await _provisionCurrentUser();
    }
  }

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
    return _provisionCurrentUser();
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