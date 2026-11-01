import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:onlyshrooms/data/auth/auth_repository.dart';
import 'package:onlyshrooms/data/auth/keycloak_auth_repository.dart';
import 'package:onlyshrooms/data/auth/keycloak_manager.dart';

import 'package:onlyshrooms/domain/grzybiarz.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return KeycloakAuthRepository(keycloakManager);
});

final authControllerProvider =
    ChangeNotifierProvider<AuthController>((ref) {
  final controller = AuthController(ref.watch(authRepositoryProvider));
  unawaited(controller.init());
  ref.onDispose(controller.dispose);
  return controller;
});

class AuthController extends ChangeNotifier {
  AuthController(this._auth);

  final AuthRepository _auth;
  StreamSubscription<Grzybiarz?>? _sub;
  bool _ready = false;
  bool _busy = false;

  bool get ready => _ready;
  bool get busy => _busy;
  bool get isSignedIn => _auth.isSignedIn;
  Grzybiarz? get user => _auth.currentUser;

  Future<void> init() async {
    await _auth.restoreSession();
    _sub = _auth.authStateChanges.listen((_) => notifyListeners());
    _ready = true;
    notifyListeners();
  }

  Future<void> signInWithGoogle({bool register = false}) async {
    _busy = true;
    notifyListeners();
    try {
      await _auth.signInWithGoogle(register: register);
    } finally {
      _busy = false;
      notifyListeners();
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
    notifyListeners();
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}
