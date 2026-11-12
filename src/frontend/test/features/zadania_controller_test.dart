import 'package:flutter_test/flutter_test.dart';
import 'package:onlyshrooms/core/page_response.dart';
import 'package:onlyshrooms/data/zadanie/zadanie_repository.dart';
import 'package:onlyshrooms/domain/grzybiarz.dart';
import 'package:onlyshrooms/domain/zadanie.dart';
import 'package:onlyshrooms/features/zadania/zadania_controller.dart';

void main() {
  late _FakeZadanieRepository repository;
  late ZadaniaController controller;

  setUp(() {
    repository = _FakeZadanieRepository();
    controller = ZadaniaController(repository);
  });

  tearDown(() {
    controller.dispose();
  });

  test('loadList applies search and clears loading', () async {
    await controller.loadList(page: 0, nazwa: 'kosz');

    expect(controller.loading, isFalse);
    expect(controller.error, isNull);
    expect(controller.search, 'kosz');
    expect(controller.pageIndex, 0);
    expect(repository.lastQuery, 'kosz');
    expect(repository.lastPage, 0);
    expect(repository.lastSize, controller.pageSize);
    expect(controller.page!.content.single.nazwa, 'Przygotować kosz');
    expect(controller.page!.totalElements, 1);

    await controller.loadList(page: 1, nazwa: '');

    expect(controller.search, isEmpty);
    expect(repository.lastQuery, isNull);
    expect(controller.page!.number, 1);
    expect(controller.page!.content.single.id, '6');
  });

  test('loadDetail stores a task and handles missing tasks', () async {
    await controller.loadDetail('1');
    expect(controller.selected?.id, '1');
    expect(controller.detailLoading, isFalse);
    expect(controller.error, isNull);

    await controller.loadDetail('missing');
    expect(controller.selected, isNull);
    expect(controller.detailLoading, isFalse);
    expect(controller.error, isNull);
  });

  test('loadDetail reports repository failures', () async {
    repository.failGetById = true;

    await controller.loadDetail('1');

    expect(controller.selected, isNull);
    expect(controller.detailLoading, isFalse);
    expect(controller.error, contains('detail failed'));
  });

  test('save creates and updates tasks, selecting saved value', () async {
    final created = await controller.save(
      const Zadanie(id: 'new', nazwa: 'Nowe', grzybobranieId: '5'),
      isNew: true,
    );

    expect(created.id, '2');
    expect(created.grzybobranieId, '5');
    expect(controller.selected, same(created));
    expect(repository.createCalls, 1);

    final updated = await controller.save(
      created.copyWith(nazwa: 'Zmienione'),
      isNew: false,
    );

    expect(updated.id, '2');
    expect(updated.nazwa, 'Zmienione');
    expect(controller.selected, same(updated));
    expect(repository.updateCalls, 1);
  });

  test('member changes refresh selected task', () async {
    const member = Grzybiarz(id: 'u1', imie: 'Ada', nazwisko: 'Las');
    await controller.addMember('1', member);

    expect(repository.addedMembers, [member]);
    expect(controller.selected?.czlonkowie, [member]);

    await controller.removeMember('1', member.id);

    expect(repository.removedMembers, ['u1']);
    expect(controller.selected?.czlonkowie, isEmpty);
  });
}

class _FakeZadanieRepository implements ZadanieRepository {
  final List<Zadanie> _zadania = [
    const Zadanie(id: '1', nazwa: 'Przygotować kosz'),
    const Zadanie(id: '2', nazwa: 'Sprawdzić pogodę'),
    const Zadanie(id: '3', nazwa: 'Spakować mapę'),
    const Zadanie(id: '4', nazwa: 'Zatankować auto'),
    const Zadanie(id: '5', nazwa: 'Ustalić godzinę'),
    const Zadanie(id: '6', nazwa: 'Zabrać termos'),
  ];
  final Map<String, List<Grzybiarz>> _members = {};

  String? lastQuery;
  int? lastPage;
  int? lastSize;
  int createCalls = 0;
  int updateCalls = 0;
  bool failGetById = false;
  final List<Grzybiarz> addedMembers = [];
  final List<String> removedMembers = [];

  @override
  Future<PageResponse<Zadanie>> list({
    String? nazwa,
    int page = 0,
    int size = 10,
    String? sort,
  }) async {
    lastQuery = nazwa;
    lastPage = page;
    lastSize = size;
    final filtered = _zadania
        .where(
          (zadanie) =>
              nazwa == null ||
              zadanie.nazwa.toLowerCase().contains(nazwa.toLowerCase()),
        )
        .toList();
    return PageResponse.fromList(filtered, page: page, size: size);
  }

  @override
  Future<Zadanie?> getById(String id) async {
    if (failGetById) throw StateError('detail failed');
    for (final zadanie in _zadania) {
      if (zadanie.id == id) return zadanie;
    }
    return null;
  }

  @override
  Future<Zadanie> create(Zadanie item) async {
    createCalls++;
    final created = Zadanie(
      id: '2',
      grzybobranieId: item.grzybobranieId,
      nazwa: item.nazwa,
      opis: item.opis,
      fields: item.fields,
    );
    _zadania.add(created);
    return created;
  }

  @override
  Future<Zadanie> update(Zadanie item) async {
    updateCalls++;
    final index = _zadania.indexWhere((zadanie) => zadanie.id == item.id);
    if (index < 0) throw StateError('zadanie not found');
    _zadania[index] = item;
    return item;
  }

  @override
  Future<List<Grzybiarz>> listCzlonkowie(String zadanieId) async =>
      List.of(_members[zadanieId] ?? const []);

  @override
  Future<void> addCzlonnek(String zadanieId, Grzybiarz member) async {
    addedMembers.add(member);
    _members.putIfAbsent(zadanieId, () => []).add(member);
    _replaceMembersOnTask(zadanieId, _members[zadanieId]!);
  }

  @override
  Future<void> removeCzlonnek(String zadanieId, String grzybiarzId) async {
    removedMembers.add(grzybiarzId);
    _members[zadanieId]?.removeWhere((member) => member.id == grzybiarzId);
    _replaceMembersOnTask(zadanieId, _members[zadanieId] ?? const []);
  }

  void _replaceMembersOnTask(String id, List<Grzybiarz> members) {
    final index = _zadania.indexWhere((zadanie) => zadanie.id == id);
    if (index >= 0) {
      final current = _zadania[index];
      _zadania[index] = Zadanie(
        id: current.id,
        grzybobranieId: current.grzybobranieId,
        nazwa: current.nazwa,
        opis: current.opis,
        kolejnosc: current.kolejnosc,
        fields: current.fields,
        czlonkowie: List.of(members),
      );
    }
  }
}
