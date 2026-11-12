import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:onlyshrooms/core/api_client.dart';
import 'package:onlyshrooms/core/page_response.dart';
import 'package:onlyshrooms/data/zadanie/zadanie_repository.dart';
import 'package:onlyshrooms/data/zadanie/http_zadanie_repository.dart';
import 'package:onlyshrooms/domain/zadanie.dart';
import 'package:onlyshrooms/domain/grzybiarz.dart';


final zadanieRepositoryProvider = Provider<ZadanieRepository>((ref) {
  return HttpZadanieRepository(createApiClient());
});

final zadaniaControllerProvider =
    ChangeNotifierProvider<ZadaniaController>((ref) {
  return ZadaniaController(ref.watch(zadanieRepositoryProvider));
});

class ZadaniaController extends ChangeNotifier {
  ZadaniaController(this._repo);

  final ZadanieRepository _repo;

  PageResponse<Zadanie>? page;
  String search = '';
  int pageIndex = 0;
  int pageSize = 5;
  bool loading = false;
  String? error;

  Zadanie? selected;
  bool detailLoading = false;

  Future<void> loadList({int? page, String? nazwa}) async {
    loading = true;
    error = null;
    if (page != null) pageIndex = page;
    if (nazwa != null) search = nazwa;
    notifyListeners();
    try {
      this.page = await _repo.list(
        nazwa: search.isEmpty ? null : search,
        page: pageIndex,
        size: pageSize,
      );
    } catch (e) {
      error = e.toString();
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  Future<void> loadDetail(String id) async {
    detailLoading = true;
    error = null;
    notifyListeners();
    try {
      selected = await _repo.getById(id);
    } catch (e) {
      error = e.toString();
      selected = null;
    } finally {
      detailLoading = false;
      notifyListeners();
    }
  }

  Future<Zadanie> save(Zadanie item, {required bool isNew}) async {
    final saved = isNew ? await _repo.create(item) : await _repo.update(item);
    selected = saved;
    await loadList();
    return saved;
  }

  Future<void> addMember(String zadanieId, Grzybiarz member) async {
    await _repo.addCzlonnek(zadanieId, member);
    await loadDetail(zadanieId);
  }

  Future<void> removeMember(String zadanieId, String memberId) async {
    await _repo.removeCzlonnek(zadanieId, memberId);
    await loadDetail(zadanieId);
  }
}
