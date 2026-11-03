import 'package:dio/dio.dart';
import 'package:onlyshrooms/data/auth/auth_repository.dart';
import 'package:onlyshrooms/data/auth/keycloak_auth_manager.dart';
import 'package:onlyshrooms/domain/grzybiarz.dart';

class KeycloakAuthRepository implements AuthRepository {
  KeycloakAuthRepository(this._manager, this._api);

  final KeycloakAuthManager _manager;
  final Dio _api;

  @override
  Grzybiarz? get currentUser => _toGrzybiarz(_manager.currentUser);

  @override
  bool get isSignedIn => _manager.currentUser != null;

  @override
  Stream<Grzybiarz?> get authStateChanges =>
      _manager.userChanges.map(_toGrzybiarz);

  Future<Grzybiarz> _provisionUser(KeycloakIdentity user) async {
    final accessToken = await _manager.getAccessToken();
    if (accessToken == null) {
      throw StateError('Keycloak did not provide an access token.');
    }

    final claims = user.claims;
    final response = await _api.post<Map<String, dynamic>>(
      '/api/auth/me',
      data: {
        'keycloakId': user.id,
        'email': claims['email'],
        'imie': claims['given_name'],
        'nazwisko': claims['family_name'],
      },
      options: Options(headers: {'Authorization': 'Bearer $accessToken'}),
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
    final user = _manager.currentUser;
    if (user != null) {
      await _provisionUser(user);
    }
  }

  @override
  Future<Grzybiarz> signInWithGoogle({bool register = false}) async {
    final user = await _manager.signInWithGoogle();
    if (user == null) {
      throw StateError('Google sign-in completed without a user.');
    }
    return _provisionUser(user);
  }

  @override
  Future<void> signOut() => _manager.logout();

  Grzybiarz? _toGrzybiarz(KeycloakIdentity? user) {
    if (user == null) return null;

    final claims = user.claims;
    String stringClaim(String key) =>
        claims[key] is String ? claims[key] as String : '';

    return Grzybiarz(
      id: user.id,
      imie: stringClaim('given_name'),
      nazwisko: stringClaim('family_name'),
      email: claims['email'] is String ? claims['email'] as String : null,
    );
  }
}
