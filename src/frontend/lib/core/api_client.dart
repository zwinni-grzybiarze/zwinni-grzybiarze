import 'dart:convert';

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

  final credentials = base64Encode(
    utf8.encode('${AppConfig.basicAuthUser}:${AppConfig.basicAuthPassword}'),
  );
  dio.options.headers['Authorization'] = 'Basic $credentials';

  return dio;
}
