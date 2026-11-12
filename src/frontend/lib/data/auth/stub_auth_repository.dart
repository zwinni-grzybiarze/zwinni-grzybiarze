import 'dart:async';
import 'dart:math';

import 'package:onlyshrooms/data/auth/auth_repository.dart';
import 'package:onlyshrooms/domain/grzybiarz.dart';
import 'package:shared_preferences/shared_preferences.dart';

class StubAuthRepository implements AuthRepository {
  StubAuthRepository();

  static const _prefsKey = 'onlyshrooms_stub_user';

  final _controller = StreamController<Grzybiarz?>.broadcast();
  Grzybiarz? _user;

  @override
  Grzybiarz? get currentUser => _user;

  @override
  bool get isSignedIn => _user != null;

  @override
  Stream<Grzybiarz?> get authStateChanges => _controller.stream;

  static final _randomStubId = RegExp(r'^stub-google-[0-9a-f]{6}$');

  @override
  Future<void> restoreSession() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_prefsKey);
    if (raw == null) return;
    // Minimal restore: "id|imie|nazwisko|email"
    final parts = raw.split('|');
    if (parts.length < 3) return;

    // Old fixed stub (`stub-google-1` / "Demo Grzybiarz") — re-issue a random
    // identity so chat sessions are distinguishable after the stub upgrade.
    if (!_randomStubId.hasMatch(parts[0])) {
      await signInWithGoogle(register: parts[1] == 'Nowy');
      return;
    }

    _user = Grzybiarz(
      id: parts[0],
      imie: parts[1],
      nazwisko: parts[2],
      email: parts.length > 3 ? parts[3] : null,
    );
    _controller.add(_user);
  }

  @override
  Future<Grzybiarz> signInWithGoogle({bool register = false}) async {
    // Instant stub — no network. Next sprint: real Google redirect + tokens.
    // Random id/name so separate browser sessions look like different chat users
    // until a real users table / JWT exists.
    final suffix = Random().nextInt(0xffffff).toRadixString(16).padLeft(6, '0');
    final user = Grzybiarz(
      id: 'stub-google-$suffix',
      imie: register ? 'Nowy' : 'Demo',
      nazwisko: 'Grzybiarz-$suffix',
      email: 'demo-$suffix@onlyshrooms.app',
    );
    _user = user;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _prefsKey,
      '${user.id}|${user.imie}|${user.nazwisko}|${user.email ?? ''}',
    );
    _controller.add(_user);
    return user;
  }

  @override
  Future<void> signOut() async {
    _user = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_prefsKey);
    _controller.add(null);
  }

  void dispose() {
    _controller.close();
  }
}
