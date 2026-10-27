import 'package:onlyshrooms/core/page_response.dart';
import 'package:onlyshrooms/domain/grzybobranie.dart';
import 'package:onlyshrooms/domain/grzybiarz.dart';
import 'package:onlyshrooms/domain/zadanie.dart';

abstract class GrzybobranieRepository {
  Future<PageResponse<Grzybobranie>> list({
    String? nazwa,
    int page = 0,
    int size = 10,
    String? sort,
  });

  Future<Grzybobranie?> getById(String id);

  Future<Grzybobranie> create(Grzybobranie item);

  Future<Grzybobranie> update(Grzybobranie item);

  Future<List<Zadanie>> listZadania(String grzybobranieId);

  Future<Zadanie> createZadanie(String grzybobranieId, Zadanie zadanie);

  Future<Zadanie> updateZadanie(Zadanie zadanie);

  Future<void> deleteZadanie(String zadanieId);

  Future<List<Grzybiarz>> listCzlonkowie(String grzybobranieId);

  Future<void> addCzlonnek(String grzybobranieId, Grzybiarz member);

  Future<void> removeCzlonnek(String grzybobranieId, String grzybiarzId);
}
