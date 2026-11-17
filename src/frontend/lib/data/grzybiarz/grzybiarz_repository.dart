import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:onlyshrooms/core/api_client.dart';
import 'package:onlyshrooms/domain/grzybiarz.dart';

final grzybiarzRepositoryProvider = Provider<GrzybiarzRepository>((ref) {
  return GrzybiarzRepository(createApiClient());
});

class GrzybiarzRepository {
  GrzybiarzRepository(this._dio);

  final Dio _dio;

  Future<List<Grzybiarz>> list() async {
    final response = await _dio.get<List<dynamic>>('/api/grzybiarze');
    final data = response.data ?? const [];
    return data
        .whereType<Map<String, dynamic>>()
        .map(Grzybiarz.fromJson)
        .toList();
  }

  Future<Grzybiarz> getById(String id) async {
    final response =
        await _dio.get<Map<String, dynamic>>('/api/grzybiarze/$id');
    final data = response.data;
    if (data == null) {
      throw StateError('Nie znaleziono użytkownika.');
    }
    return Grzybiarz.fromJson(data);
  }
}
