import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:onlyshrooms/data/auth/auth_repository.dart';
import 'package:onlyshrooms/core/api_client.dart';
import 'package:onlyshrooms/data/auth/google_auth_repository.dart';
import 'package:onlyshrooms/domain/grzybiarz.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return GoogleAuthRepository(createApiClient());
});

final authControllerProvider = ChangeNotifierProvider<AuthController>((ref) {
  final controller = AuthController(ref.watch(authRepositoryProvider));
  unawaited(controller.init());
  return controller;
});

class AuthController extends ChangeNotifier {
  AuthController(this._auth);

  final AuthRepository _auth;
  StreamSubscription<Grzybiarz?>? _sub;
  bool _ready = false;
  bool _busy = false;
  String? _error;

  bool get ready => _ready;
  bool get busy => _busy;
  String? get error => _error;
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
    _error = null;
    notifyListeners();
    try {
      await _auth.signInWithGoogle(register: register);
    } catch (e) {
      _error = e.toString();
      rethrow;
    } finally {
      _busy = false;
      notifyListeners();
    }
  }

  Future<void> completeGoogleLogin(String token, {String? email}) async {
    await _auth.completeGoogleLogin(token, email: email);
    notifyListeners();
  }

  Future<void> registerWithEmail({
    required String email,
    required String password,
    required String imie,
    required String nazwisko,
  }) async {
    _busy = true;
    _error = null;
    notifyListeners();
    try {
      await _auth.registerWithEmail(
        email: email,
        password: password,
        imie: imie,
        nazwisko: nazwisko,
      );
    } catch (e) {
      _error = e.toString().replaceFirst('Bad state: ', '');
      rethrow;
    } finally {
      _busy = false;
      notifyListeners();
    }
  }

  Future<void> confirmEmail(String token) async {
    _busy = true;
    _error = null;
    notifyListeners();
    try {
      await _auth.confirmEmail(token);
    } catch (e) {
      _error = e.toString().replaceFirst('Bad state: ', '');
      rethrow;
    } finally {
      _busy = false;
      notifyListeners();
    }
  }

  Future<void> loginWithEmail({
    required String email,
    required String password,
  }) async {
    _busy = true;
    _error = null;
    notifyListeners();
    try {
      await _auth.loginWithEmail(email: email, password: password);
    } catch (e) {
      _error = e.toString().replaceFirst('Bad state: ', '');
      rethrow;
    } finally {
      _busy = false;
      notifyListeners();
    }
  }

  Future<void> requestPasswordReset(String email) async {
    _busy = true;
    _error = null;
    notifyListeners();
    try {
      await _auth.requestPasswordReset(email);
    } catch (e) {
      _error = e.toString().replaceFirst('Bad state: ', '');
      rethrow;
    } finally {
      _busy = false;
      notifyListeners();
    }
  }

  Future<void> resetPassword({
    required String token,
    required String newPassword,
  }) async {
    _busy = true;
    _error = null;
    notifyListeners();
    try {
      await _auth.resetPassword(token: token, newPassword: newPassword);
    } catch (e) {
      _error = e.toString().replaceFirst('Bad state: ', '');
      rethrow;
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
