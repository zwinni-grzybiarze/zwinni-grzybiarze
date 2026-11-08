import 'package:onlyshrooms/core/page_response.dart';
import 'package:onlyshrooms/data/grzybobranie/grzybobranie_repository.dart';
import 'package:onlyshrooms/domain/grzybobranie.dart';
import 'package:onlyshrooms/domain/grzybiarz.dart';
import 'package:onlyshrooms/domain/status.dart';
import 'package:onlyshrooms/domain/zadanie.dart';

class MockGrzybobranieRepository implements GrzybobranieRepository {
  MockGrzybobranieRepository() {
    _seed();
  }

  final List<Grzybobranie> _items = [];
  int _nextId = 100;
  int _nextTaskId = 500;

  void _seed() {
    final japie = Grzybiarz(
      id: 'u1',
      imie: 'Jadwiga',
      nazwisko: 'Pieczara',
      email: 'japie@onlyshrooms.app',
    );
    final jagrz = Grzybiarz(
      id: 'u2',
      imie: 'Jan',
      nazwisko: 'Grzyb',
      email: 'jagrz@onlyshrooms.app',
    );

    _items.addAll([
      Grzybobranie(
        id: '1',
        nazwa: 'Borowiki w Tucholi',
        fields: {
          'opis': 'Weekendowy wypad na borowiki szlachetne.',
          'lokalizacja': 'Bory Tucholskie, parking przy jeziorze',
          'status': 'PLANOWANE',
          'dataOd': '2026-10-25',
          'dataDo': '2026-10-26',
        },
        zadania: [
          Zadanie(
            id: 't1',
            grzybobranieId: '1',
            tytul: 'Zabrać kosze i noże',
            opis: 'Po jednym zestawie na osobę',
            kolejnosc: 1,
          ),
          Zadanie(
            id: 't2',
            grzybobranieId: '1',
            tytul: 'Sprawdzić pogodę',
            opis: null,
            kolejnosc: 2,
          ),
        ],
        czlonkowie: [japie, jagrz],
      ),
      Grzybobranie(
        id: '2',
        nazwa: 'Maślaki pod Gdańskiem',
        fields: {
          'opis': 'Krótka sobotnia wyprawa.',
          'lokalizacja': 'Lasy Oliwskie',
          'status': 'W_TOKU',
          'dataOd': '2026-10-18',
          'dataDo': '2026-10-18',
        },
        zadania: const [],
        czlonkowie: [jagrz],
      ),
      Grzybobranie(
        id: '3',
        nazwa: 'Kurki — Beskid',
        fields: {
          'opis': 'Odroczone z powodu deszczu.',
          'lokalizacja': 'Beskid Śląski',
          'status': 'ODROCZONE',
          'dataOd': '2026-11-01',
          'dataDo': '2026-11-02',
        },
        zadania: const [],
        czlonkowie: [japie],
      ),
      Grzybobranie(
        id: '4',
        nazwa: 'Jesienny marathon Podlasie',
        fields: {
          'opis': 'Zakończone — rekord sezonu.',
          'lokalizacja': 'Puszcza Białowieska (obrzeża)',
          'status': 'ZAKONCZONE',
          'dataOd': '2026-09-10',
          'dataDo': '2026-09-12',
        },
        zadania: [
          Zadanie(
            id: 't3',
            grzybobranieId: '4',
            tytul: 'Podsumowanie zbiorów',
            opis: 'Wpisać wagę i gatunki',
            kolejnosc: 1,
          ),
        ],
        czlonkowie: [japie, jagrz],
      ),
    ]);
  }

  @override
  Future<PageResponse<Grzybobranie>> list({
    String? nazwa,
    int page = 0,
    int size = 10,
    String? sort,
    Set<GrzybobranieStatus>? statuses,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 200));
    var filtered = List<Grzybobranie>.from(_items);
    if (nazwa != null && nazwa.trim().isNotEmpty) {
      final q = nazwa.trim().toLowerCase();
      filtered = filtered
          .where((g) => g.nazwa.toLowerCase().contains(q))
          .toList();
    }
    final allowed = statuses ?? GrzybobranieStatus.defaultListFilters;
    filtered = filtered.where((g) {
      final status = g.status;
      return status != null && allowed.contains(status);
    }).toList();
    filtered.sort((a, b) => a.nazwa.compareTo(b.nazwa));
    return PageResponse.fromList(filtered, page: page, size: size);
  }

  @override
  Future<Grzybobranie?> getById(String id) async {
    await Future<void>.delayed(const Duration(milliseconds: 100));
    try {
      return _items.firstWhere((g) => g.id == id);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<Grzybobranie> create(Grzybobranie item) async {
    await Future<void>.delayed(const Duration(milliseconds: 150));
    final created = Grzybobranie(
      id: '${_nextId++}',
      nazwa: item.nazwa,
      fields: item.fields,
      zadania: item.zadania,
      czlonkowie: item.czlonkowie,
    );
    _items.add(created);
    return created;
  }

  @override
  Future<Grzybobranie> update(Grzybobranie item) async {
    await Future<void>.delayed(const Duration(milliseconds: 150));
    final index = _items.indexWhere((g) => g.id == item.id);
    if (index < 0) {
      throw StateError('Grzybobranie ${item.id} not found');
    }
    _items[index] = item;
    return item;
  }

  Grzybobranie _require(String id) {
    return _items.firstWhere(
      (g) => g.id == id,
      orElse: () => throw StateError('Grzybobranie $id not found'),
    );
  }

  @override
  Future<List<Zadanie>> listZadania(String grzybobranieId) async {
    return List.of(_require(grzybobranieId).zadania);
  }

  @override
  Future<Zadanie> createZadanie(String grzybobranieId, Zadanie zadanie) async {
    final g = _require(grzybobranieId);
    final created = Zadanie(
      id: 't${_nextTaskId++}',
      grzybobranieId: grzybobranieId,
      tytul: zadanie.tytul,
      opis: zadanie.opis,
      kolejnosc: zadanie.kolejnosc ?? g.zadania.length + 1,
      fields: zadanie.fields,
    );
    final next = g.copyWith(zadania: [...g.zadania, created]);
    await update(next);
    return created;
  }

  @override
  Future<Zadanie> updateZadanie(Zadanie zadanie) async {
    final g = _require(zadanie.grzybobranieId);
    final tasks = g.zadania.map((t) => t.id == zadanie.id ? zadanie : t).toList();
    await update(g.copyWith(zadania: tasks));
    return zadanie;
  }

  @override
  Future<void> deleteZadanie(String zadanieId) async {
    final index = _items.indexWhere(
      (g) => g.zadania.any((t) => t.id == zadanieId),
    );
    if (index < 0) return;
    final g = _items[index];
    await update(
      g.copyWith(zadania: g.zadania.where((t) => t.id != zadanieId).toList()),
    );
  }

  @override
  Future<List<Grzybiarz>> listCzlonkowie(String grzybobranieId) async {
    return List.of(_require(grzybobranieId).czlonkowie);
  }

  @override
  Future<void> addCzlonnek(String grzybobranieId, Grzybiarz member) async {
    final g = _require(grzybobranieId);
    if (g.czlonkowie.any((c) => c.id == member.id)) return;
    await update(g.copyWith(czlonkowie: [...g.czlonkowie, member]));
  }

  @override
  Future<void> removeCzlonnek(String grzybobranieId, String grzybiarzId) async {
    final g = _require(grzybobranieId);
    await update(
      g.copyWith(
        czlonkowie: g.czlonkowie.where((c) => c.id != grzybiarzId).toList(),
      ),
    );
  }
}
