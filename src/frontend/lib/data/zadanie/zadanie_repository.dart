import 'package:onlyshrooms/core/page_response.dart';
import 'package:onlyshrooms/domain/grzybiarz.dart';
import 'package:onlyshrooms/domain/zadanie.dart';

abstract class ZadanieRepository {
  Future<PageResponse<Zadanie>> list({
    String? nazwa,
    int page = 0,
    int size = 10,
    String? sort,
  });

  Future<Zadanie?> getById(String id);

  Future<Zadanie> create(Zadanie item);

  Future<Zadanie> update(Zadanie item);

  Future<List<Grzybiarz>> listCzlonkowie(String zadanieId);

  Future<void> addCzlonnek(String zadanieId, Grzybiarz member);

  Future<void> removeCzlonnek(String zadaieId, String grzybiarzId);
}
