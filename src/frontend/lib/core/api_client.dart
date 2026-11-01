import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dio/dio.dart';
import 'package:onlyshrooms/core/config.dart';

Dio createApiClient() {
  final dio = Dio(
    BaseOptions(
      baseUrl: AppConfig.apiBase,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 20),
      headers: {'Content-Type': 'application/json'},
    ),
  );

 final storage = const FlutterSecureStorage();

  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) async {
        String? token;
        try {
          token = await storage.read(key: 'jwt');
        } catch (_) {}
        if (token == null || token.isEmpty) {
          final prefs = await SharedPreferences.getInstance();
          token = prefs.getString('jwt');
        }

        if (token != null && token.isNotEmpty) {
          options.headers['Authorization'] = 'Bearer $token';
        }

        handler.next(options);
      },
    ),
  );

  return dio;
}