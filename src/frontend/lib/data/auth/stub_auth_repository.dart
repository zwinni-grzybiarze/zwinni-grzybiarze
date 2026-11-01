import 'dart:async';

import 'package:onlyshrooms/data/auth/auth_repository.dart';
import 'package:onlyshrooms/domain/grzybiarz.dart';
import 'package:shared_preferences/shared_preferences.dart';

class StubAuthRepository implements AuthRepository {
  StubAuthRepository();

  static const _prefsKey = 'onlyshrooms_stub_user';
  static const _tokenKey = 'onlyshrooms_stub_token';

  final _controller = StreamController<Grzybiarz?>.broadcast();
  Grzybiarz? _user;

  @override
  Grzybiarz? get currentUser => _user;

  @override
  bool get isSignedIn => _user != null;

  @override
  Stream<Grzybiarz?> get authStateChanges => _controller.stream;

  @override
  Future<void> restoreSession() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_prefsKey);

    if (raw == null || raw.isEmpty) return;

    final parts = raw.split('|');
    if (parts.length < 3) return;

    _user = Grzybiarz(
      id: parts[0],
      imie: parts[1],
      nazwisko: parts[2],
      email: parts.length > 3 && parts[3].isNotEmpty ? parts[3] : null,
    );
    _controller.add(_user);
  }

  @override
  Future<Grzybiarz> signInWithGoogle({bool register = false}) async {
    final user = Grzybiarz(
      id: 'stub-google-${DateTime.now().microsecondsSinceEpoch}',
      imie: register ? 'Nowy' : 'Demo',
      nazwisko: 'Grzybiarz',
      email: 'demo@onlyshrooms.app',
    );

    await _saveSession(user, token: 'stub-google-token-${user.id}');
    return user;
  }

  @override
  Future<void> completeGoogleLogin(String token, {String? email}) async {
    if (token.trim().isEmpty) return;

    final user = _user ??
        Grzybiarz(
          id: 'stub-google-${DateTime.now().microsecondsSinceEpoch}',
          imie: 'Google',
          nazwisko: '',
          email: 'google-user@example.com',
        );

    await _saveSession(user, token: token);
  }

  Future<void> _saveSession(Grzybiarz user, {required String token}) async {
    _user = user;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _prefsKey,
      '${user.id}|${user.imie}|${user.nazwisko}|${user.email ?? ''}',
    );
    await prefs.setString(_tokenKey, token);

    _controller.add(_user);
  }

  @override
  Future<void> signOut() async {
    _user = null;

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_prefsKey);
    await prefs.remove(_tokenKey);

    _controller.add(null);
  }

  void dispose() {
    _controller.close();
  }
}