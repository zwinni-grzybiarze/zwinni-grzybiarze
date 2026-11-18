import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:onlyshrooms/core/config.dart';
import 'package:onlyshrooms/data/auth/auth_repository.dart';
import 'package:onlyshrooms/domain/grzybiarz.dart';
import 'package:url_launcher/url_launcher.dart';

/// Backend-driven auth: Google OAuth + email/password.
class GoogleAuthRepository implements AuthRepository {
  GoogleAuthRepository(this._dio);

  final Dio _dio;
  static const _storage = FlutterSecureStorage();
  static const _jwtKey = 'jwt';

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
      await _storage.delete(key: _jwtKey);
    }
  }

  @override
  Future<void> signInWithGoogle({bool register = false}) async {
    final base = AppConfig.apiBase;
    final uri = Uri.parse('$base/api/auth/google/login');

    if (!await launchUrl(
      uri,
      webOnlyWindowName: '_self',
    )) {
      throw StateError('Could not launch $uri');
    }
  }

  @override
  Future<void> completeGoogleLogin(String token, {String? email}) async {
    await _persistTokenAndLoadMe(token, email: email);
  }

  @override
  Future<void> registerWithEmail({
    required String email,
    required String password,
    required String imie,
    required String nazwisko,
  }) async {
    try {
      await _dio.post<Map<String, dynamic>>(
        '/api/auth/register',
        data: {
          'email': email,
          'password': password,
          'imie': imie,
          'nazwisko': nazwisko,
        },
      );
    } on DioException catch (e) {
      throw StateError(_dioMessage(e, 'Rejestracja nie powiodła się.'));
    }
  }

  @override
  Future<void> confirmEmail(String token) async {
    try {
      await _dio.post<Map<String, dynamic>>(
        '/api/auth/confirm-email',
        data: {'token': token},
      );
    } on DioException catch (e) {
      throw StateError(
        _dioMessage(e, 'Link potwierdzenia jest nieprawidłowy lub wygasł.'),
      );
    }
  }

  @override
  Future<void> loginWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/api/auth/login',
        data: {
          'email': email,
          'password': password,
        },
      );
      final data = response.data;
      final token = data?['token'] as String?;
      if (token == null || token.isEmpty) {
        throw StateError('Brak tokenu w odpowiedzi logowania.');
      }
      await _persistTokenAndLoadMe(token, email: data?['email'] as String?);
    } on DioException catch (e) {
      throw StateError(_dioMessage(e, 'Logowanie nie powiodło się.'));
    }
  }

  @override
  Future<void> requestPasswordReset(String email) async {
    try {
      await _dio.post<Map<String, dynamic>>(
        '/api/auth/forgot-password',
        data: {'email': email},
      );
    } on DioException catch (e) {
      throw StateError(_dioMessage(e, 'Nie udało się wysłać resetu hasła.'));
    }
  }

  @override
  Future<void> resetPassword({
    required String token,
    required String newPassword,
  }) async {
    try {
      await _dio.post<Map<String, dynamic>>(
        '/api/auth/reset-password',
        data: {
          'token': token,
          'newPassword': newPassword,
        },
      );
    } on DioException catch (e) {
      throw StateError(_dioMessage(e, 'Reset hasła nie powiódł się.'));
    }
  }

  @override
  Future<void> signOut() async {
    _user = null;
    await _storage.delete(key: _jwtKey);
    _controller.add(null);
  }

  Future<void> _persistTokenAndLoadMe(String token, {String? email}) async {
    if (token.trim().isEmpty) return;

    await _storage.write(key: _jwtKey, value: token);

    // Resolve the real user before notifying signed-in state. Emitting a
    // placeholder "pending" id first made chat connect with the wrong senderId.
    try {
      final response =
          await _dio.get<Map<String, dynamic>>('/api/grzybiarze/me');
      final data = response.data;
      if (data != null) {
        _user = Grzybiarz.fromJson(data);
        _controller.add(_user);
        return;
      }
    } on DioException catch (e) {
      final status = e.response?.statusCode;
      if (status == 401 || status == 403 || status == 404) {
        _user = null;
        await _storage.delete(key: _jwtKey);
        throw StateError('Sesja jest nieprawidłowa lub wygasła.');
      }
      // Fall through to JWT claims only on transient network / 5xx errors.
    }

    final fromJwt = _grzybiarzFromJwt(token, fallbackEmail: email);
    if (fromJwt != null) {
      _user = fromJwt;
      _controller.add(_user);
    }
  }

  /// Reads NameIdentifier / name / email claims when `/me` is unavailable.
  static Grzybiarz? _grzybiarzFromJwt(String token, {String? fallbackEmail}) {
    final payload = _decodeJwtPayload(token);
    if (payload == null) return null;

    const nameId =
        'http://schemas.xmlsoap.org/ws/2005/05/identity/claims/nameidentifier';
    const givenName =
        'http://schemas.xmlsoap.org/ws/2005/05/identity/claims/givenname';
    const surname =
        'http://schemas.xmlsoap.org/ws/2005/05/identity/claims/surname';
    const emailClaim =
        'http://schemas.xmlsoap.org/ws/2005/05/identity/claims/emailaddress';

    final id = (payload[nameId] ?? payload['sub'])?.toString();
    if (id == null || id.isEmpty) return null;

    return Grzybiarz(
      id: id,
      imie: (payload[givenName] ?? '').toString(),
      nazwisko: (payload[surname] ?? '').toString(),
      email: (payload[emailClaim] ?? payload['email'] ?? fallbackEmail)
          ?.toString(),
    );
  }

  static Map<String, dynamic>? _decodeJwtPayload(String token) {
    final parts = token.split('.');
    if (parts.length != 3) return null;
    try {
      final normalized = base64Url.normalize(parts[1]);
      final json = utf8.decode(base64Url.decode(normalized));
      final decoded = jsonDecode(json);
      return decoded is Map<String, dynamic>
          ? decoded
          : decoded is Map
              ? Map<String, dynamic>.from(decoded)
              : null;
    } catch (_) {
      return null;
    }
  }

  static String _dioMessage(DioException e, String fallback) {
    final data = e.response?.data;
    if (data is Map) {
      final message = data['message'] ?? data['detail'] ?? data['title'];
      if (message is String && message.trim().isNotEmpty) return message;
    }
    return fallback;
  }

  void dispose() {
    _controller.close();
  }
}
