import 'package:dio/dio.dart';
import 'package:onlyshrooms/core/page_response.dart';
import 'package:onlyshrooms/data/grzybobranie/grzybobranie_repository.dart';
import 'package:onlyshrooms/domain/grzybobranie.dart';
import 'package:onlyshrooms/domain/grzybiarz.dart';
import 'package:onlyshrooms/domain/zadanie.dart';

/// HTTP impl — enabled when USE_MOCK_DATA=false and exposed domain APIs.
class HttpGrzybobranieRepository implements GrzybobranieRepository {
  HttpGrzybobranieRepository(this._dio);

  final Dio _dio;

  @override
  Future<PageResponse<Grzybobranie>> list({
    String? nazwa,
    int page = 0,
    int size = 10,
    String? sort,
  }) async {
    final response = await _dio.get<List<dynamic>>('/api/grzybobrania');
    var items = (response.data ?? const <dynamic>[])
        .map((e) => Grzybobranie.fromJson(e as Map<String, dynamic>))
        .toList();
    if (nazwa != null && nazwa.trim().isNotEmpty) {
      final q = nazwa.trim().toLowerCase();
      items = items.where((g) => g.nazwa.toLowerCase().contains(q)).toList();
    }
    return PageResponse.fromList(items, page: page, size: size);
  }

  @override
  Future<Grzybobranie?> getById(String id) async {
    try {
      final response =
          await _dio.get<Map<String, dynamic>>('/api/grzybobrania/$id');
      final data = response.data;
      if (data == null) return null;
      return Grzybobranie.fromJson(data);
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) return null;
      rethrow;
    }
  }

  @override
  Future<Grzybobranie> create(Grzybobranie item) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/api/grzybobrania',
      data: item.toJson()..remove('grzybobranieId'),
    );
    if (response.data != null) {
      return Grzybobranie.fromJson(response.data!);
    }
    final location = response.headers.value('location');
    if (location != null) {
      final id = location.split('/').last;
      final created = await getById(id);
      if (created != null) return created;
    }
    return item;
  }

  @override
  Future<Grzybobranie> update(Grzybobranie item) async {
    await _dio.put('/api/grzybobrania/${item.id}', data: item.toJson());
    return (await getById(item.id)) ?? item;
  }

  @override
  Future<void> delete(String id) async {
    await _dio.delete('/api/grzybobrania/$id');
  }

  @override
  Future<List<Zadanie>> listZadania(String grzybobranieId) async {
    final response = await _dio.get<dynamic>(
      '/api/grzybobrania/$grzybobranieId/zadania',
    );
    final data = response.data;
    if (data is Map<String, dynamic> && data['content'] is List) {
      return PageResponse.fromJson(data, Zadanie.fromJson).content;
    }
    final list = data as List<dynamic>? ?? const [];
    return list
        .map((e) => Zadanie.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  @override
  Future<Zadanie> createZadanie(String grzybobranieId, Zadanie zadanie) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/api/grzybobrania/$grzybobranieId/zadania',
      data: zadanie.toJson()..remove('zadanieId'),
    );
    if (response.data != null) return Zadanie.fromJson(response.data!);
    return zadanie;
  }

  @override
  Future<Zadanie> updateZadanie(Zadanie zadanie) async {
    await _dio.put('/api/zadania/${zadanie.id}', data: zadanie.toJson());
    return zadanie;
  }

  @override
  Future<void> deleteZadanie(String zadanieId) async {
    await _dio.delete('/api/zadania/$zadanieId');
  }

  @override
  Future<List<Grzybiarz>> listCzlonkowie(String grzybobranieId) async {
    final response = await _dio.get<List<dynamic>>(
      '/api/grzybobrania/$grzybobranieId/czlonkowie',
    );
    final list = response.data ?? const [];
    return list
        .map((e) => Grzybiarz.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  @override
  Future<void> addCzlonnek(String grzybobranieId, Grzybiarz member) async {
    await _dio.post(
      '/api/grzybobrania/$grzybobranieId/czlonkowie',
      data: member.toJson(),
    );
  }

  @override
  Future<void> removeCzlonnek(String grzybobranieId, String grzybiarzId) async {
    await _dio.delete(
      '/api/grzybobrania/$grzybobranieId/czlonkowie/$grzybiarzId',
    );
  }
}
