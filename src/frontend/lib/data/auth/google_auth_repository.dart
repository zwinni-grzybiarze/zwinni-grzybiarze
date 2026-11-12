import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:onlyshrooms/core/config.dart';
import 'package:onlyshrooms/data/auth/auth_repository.dart';
import 'package:onlyshrooms/domain/grzybiarz.dart';
import 'package:url_launcher/url_launcher.dart';

/// Google OAuth implementation (backend-driven flow).
///
/// Login flow:
///   1. [signInWithGoogle] navigates the **current tab** to
///      `GET /api/auth/google/login` on the backend.
///   2. The backend challenges Google, which redirects the user through the
///      consent screen and back to `GET /api/auth/google/callback`.
///   3. The backend mints a JWT and redirects the browser to
///      `{frontendUrl}/#/auth/callback?token=<jwt>&email=<email>`.
///   4. [AuthCallbackPage] picks up the callback and calls
///      [completeGoogleLogin] with the received JWT.
///   5. The JWT is stored in [FlutterSecureStorage] under key `jwt` so that
///      [createApiClient] can attach it as a Bearer header on every request.
class GoogleAuthRepository implements AuthRepository {
  GoogleAuthRepository(this._dio);

  final Dio _dio;
  static const _storage = FlutterSecureStorage();
  static const _jwtKey = 'jwt';

  final _controller = StreamController<Grzybiarz?>.broadcast();
  Grzybiarz? _user;

  // ── AuthRepository ──────────────────────────────────────────────────────────

  @override
  Grzybiarz? get currentUser => _user;

  @override
  bool get isSignedIn => _user != null;

  @override
  Stream<Grzybiarz?> get authStateChanges => _controller.stream;

  // ── Session ─────────────────────────────────────────────────────────────────

  @override
  Future<void> restoreSession() async {
    final token = await _storage.read(key: _jwtKey);
    if (token == null || token.isEmpty) return;

    try {
      final response =
          await _dio.get<Map<String, dynamic>>('/api/grzybiarze/me');
      final data = response.data;
      if (data == null) return;
      _user = Grzybiarz.fromJson(data);
      _controller.add(_user);
    } on DioException {
      // Token may be expired; silently clear so the user is prompted to log in.
      await _storage.delete(key: _jwtKey);
    }
  }

  // ── Sign-in ──────────────────────────────────────────────────────────────────

  @override
  Future<void> signInWithGoogle({bool register = false}) async {
    final base = AppConfig.apiBase;
    // Backend route: GET /api/auth/google/login  (register uses same flow for now)
    final uri = Uri.parse('$base/api/auth/google/login');

    // On web, navigate the current tab/window (_self) rather than opening a new tab.
    if (!await launchUrl(
      uri,
      webOnlyWindowName: '_self',
    )) {
      throw StateError('Could not launch $uri');
    }
    // Sign-in is completed via [completeGoogleLogin] when the backend
    // redirects back to /#/auth/callback?token=<jwt>&email=<email>.
  }

  @override
  Future<void> completeGoogleLogin(String token, {String? email}) async {
    if (token.trim().isEmpty) return;

    await _storage.write(key: _jwtKey, value: token);

    // Optimistically build a local user object from what the callback gave us,
    // then refresh from the server in the background.
    _user = Grzybiarz(
      id: 'pending',
      imie: '',
      nazwisko: '',
      email: email,
    );
    _controller.add(_user);

    try {
      final response =
          await _dio.get<Map<String, dynamic>>('/api/grzybiarze/me');
      final data = response.data;
      if (data != null) {
        _user = Grzybiarz.fromJson(data);
        _controller.add(_user);
      }
    } on DioException {
      // Keep the optimistic user; the next /me call will fix it.
    }
  }

  // ── Sign-out ─────────────────────────────────────────────────────────────────

  @override
  Future<void> signOut() async {
    _user = null;
    await _storage.delete(key: _jwtKey);
    _controller.add(null);
  }

  void dispose() {
    _controller.close();
  }
}
