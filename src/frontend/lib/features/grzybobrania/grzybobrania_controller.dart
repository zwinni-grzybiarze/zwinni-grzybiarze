import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:onlyshrooms/core/api_client.dart';
import 'package:onlyshrooms/core/config.dart';
import 'package:onlyshrooms/core/page_response.dart';
import 'package:onlyshrooms/data/grzybobranie/grzybobranie_repository.dart';
import 'package:onlyshrooms/data/grzybobranie/http_grzybobranie_repository.dart';
import 'package:onlyshrooms/data/grzybobranie/mock_grzybobranie_repository.dart';
import 'package:onlyshrooms/domain/grzybobranie.dart';
import 'package:onlyshrooms/domain/grzybiarz.dart';
import 'package:onlyshrooms/domain/status.dart';
import 'package:onlyshrooms/domain/zadanie.dart';

final grzybobranieRepositoryProvider = Provider<GrzybobranieRepository>((ref) {
  if (AppConfig.useMockData) {
    return MockGrzybobranieRepository();
  }
  return HttpGrzybobranieRepository(createApiClient());
});

final grzybobraniaControllerProvider =
    ChangeNotifierProvider<GrzybobraniaController>((ref) {
  return GrzybobraniaController(ref.watch(grzybobranieRepositoryProvider));
});

class GrzybobraniaController extends ChangeNotifier {
  GrzybobraniaController(this._repo);

  final GrzybobranieRepository _repo;

  PageResponse<Grzybobranie>? page;
  String search = '';
  int pageIndex = 0;
  int pageSize = 5;
  Set<GrzybobranieStatus> selectedStatuses =
      GrzybobranieStatus.defaultListFilters;
  bool loading = false;
  String? error;

  Grzybobranie? selected;
  bool detailLoading = false;

  Future<void> loadList({
    int? page,
    String? nazwa,
    Set<GrzybobranieStatus>? statuses,
  }) async {
    loading = true;
    error = null;
    if (page != null) pageIndex = page;
    if (nazwa != null) search = nazwa;
    if (statuses != null) selectedStatuses = Set.of(statuses);
    notifyListeners();
    try {
      this.page = await _repo.list(
        nazwa: search.isEmpty ? null : search,
        page: pageIndex,
        size: pageSize,
        statuses: selectedStatuses,
      );
    } catch (e) {
      error = e.toString();
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  Future<void> toggleStatusFilter(GrzybobranieStatus status) async {
    final next = Set<GrzybobranieStatus>.of(selectedStatuses);
    if (!next.remove(status)) {
      next.add(status);
    }
    await loadList(page: 0, statuses: next);
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

  Future<Grzybobranie> save(Grzybobranie item, {required bool isNew}) async {
    final saved = isNew ? await _repo.create(item) : await _repo.update(item);
    selected = saved;
    await loadList();
    return saved;
  }

  Future<void> remove(String id) async {
    // Soft-archive via status update (issue #46); no hard delete API.
    // Future (#46): also archive related zadania once they have a status on BE.
    final current = selected?.id == id ? selected : await _repo.getById(id);
    if (current == null) {
      throw StateError('Grzybobranie $id not found');
    }
    if (current.isArchived) {
      throw StateError('Grzybobranie $id is already archived');
    }
    final archived = current.copyWithField(
      'status',
      GrzybobranieStatus.zarchiwizowane.apiValue,
    );
    await _repo.update(archived);
    if (selected?.id == id) {
      selected = null;
    }
    await loadList();
  }

  Future<void> saveZadanie(
    String grzybobranieId,
    Zadanie zadanie, {
    required bool isNew,
  }) async {
    if (isNew) {
      await _repo.createZadanie(grzybobranieId, zadanie);
    } else {
      await _repo.updateZadanie(zadanie);
    }
    await loadDetail(grzybobranieId);
  }

  Future<void> removeZadanie(String grzybobranieId, String zadanieId) async {
    await _repo.deleteZadanie(zadanieId);
    await loadDetail(grzybobranieId);
  }

  Future<void> addMember(String grzybobranieId, Grzybiarz member) async {
    await _repo.addCzlonnek(grzybobranieId, member);
    await loadDetail(grzybobranieId);
  }

  Future<void> removeMember(String grzybobranieId, String memberId) async {
    await _repo.removeCzlonnek(grzybobranieId, memberId);
    await loadDetail(grzybobranieId);
  }
}
