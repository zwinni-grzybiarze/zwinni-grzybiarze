import 'package:dio/dio.dart';
import 'package:onlyshrooms/core/page_response.dart';
import 'package:onlyshrooms/data/zadanie/zadanie_repository.dart';
import 'package:onlyshrooms/domain/grzybiarz.dart';
import 'package:onlyshrooms/domain/zadanie.dart';

/// HTTP impl — enabled when USE_MOCK_DATA=false and exposed domain APIs.
class HttpZadanieRepository implements ZadanieRepository {
  HttpZadanieRepository(this._dio);

  final Dio _dio;

  @override
  Future<PageResponse<Zadanie>> list({
    String? nazwa,
    int page = 0,
    int size = 10,
    String? sort,
  }) async {
    final response = await _dio.get<List<dynamic>>('/api/zadania');
    var items = (response.data ?? const <dynamic>[])
        .map((e) => Zadanie.fromJson(e as Map<String, dynamic>))
        .toList();
    if (nazwa != null && nazwa.trim().isNotEmpty) {
      final q = nazwa.trim().toLowerCase();
      items = items.where((g) => g.nazwa.toLowerCase().contains(q)).toList();
    }
    return PageResponse.fromList(items, page: page, size: size);
  }

  @override
  Future<Zadanie?> getById(String id) async {
    try {
      final response =
          await _dio.get<Map<String, dynamic>>('/api/zadania/$id');
      final data = response.data;
      if (data == null) return null;
      return Zadanie.fromJson(data);
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) return null;
      rethrow;
    }
  }

  @override
  Future<Zadanie> create(Zadanie item) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/api/zadania',
      data: item.toJson()..remove('zadanieId'),
    );
    if (response.data != null) {
      return Zadanie.fromJson(response.data!);
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
  Future<Zadanie> update(Zadanie item) async {
    await _dio.put('/api/zadania/${item.id}', data: item.toJson());
    return (await getById(item.id)) ?? item;
  }

  @override
  Future<List<Grzybiarz>> listCzlonkowie(String zadanieId) async {
    final response = await _dio.get<List<dynamic>>(
      '/api/zadania/$zadanieId/czlonkowie',
    );
    final list = response.data ?? const [];
    return list
        .map((e) => Grzybiarz.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  @override
  Future<void> addCzlonnek(String zadanieId, Grzybiarz member) async {
    await _dio.post(
      '/api/zadania/$zadanieId/czlonkowie',
      data: member.toJson(),
    );
  }

  @override
  Future<void> removeCzlonnek(String zadanieId, String grzybiarzId) async {
    await _dio.delete(
      '/api/zadania/$zadanieId/czlonkowie/$grzybiarzId',
    );
  }
}
