import 'package:flutter_test/flutter_test.dart';
import 'package:onlyshrooms/data/grzybobranie/mock_grzybobranie_repository.dart';
import 'package:onlyshrooms/domain/grzybobranie.dart';
import 'package:onlyshrooms/domain/grzybiarz.dart';
import 'package:onlyshrooms/domain/zadanie.dart';

void main() {
  late MockGrzybobranieRepository repo;

  setUp(() {
    repo = MockGrzybobranieRepository();
  });

  test('list returns seeded page and supports search', () async {
    final all = await repo.list(page: 0, size: 10);
    expect(all.totalElements, greaterThanOrEqualTo(4));

    final filtered = await repo.list(nazwa: 'borowiki', page: 0, size: 10);
    expect(filtered.content, isNotEmpty);
    expect(
      filtered.content.every(
        (g) => g.nazwa.toLowerCase().contains('borowiki'),
      ),
      isTrue,
    );
  });

  test('create and update grzybobranie', () async {
    final created = await repo.create(
      Grzybobranie(
        id: 'tmp',
        nazwa: 'Nowe',
        fields: {
          'opis': 'o',
          'lokalizacja': 'L',
          'status': 'PLANOWANE',
          'dataOd': '2026-11-01',
          'dataDo': '2026-11-02',
        },
      ),
    );
    expect(created.id, isNot('tmp'));
    expect(created.nazwa, 'Nowe');

    final updated = await repo.update(
      created.copyWith(nazwa: 'Zmienione'),
    );
    expect(updated.nazwa, 'Zmienione');
    expect((await repo.getById(created.id))?.nazwa, 'Zmienione');
  });

  test('zadania and czlonkowie CRUD on parent', () async {
    const parentId = '1';

    final task = await repo.createZadanie(
      parentId,
      const Zadanie(
        id: 'new',
        grzybobranieId: parentId,
        tytul: 'Test task',
        opis: 'desc',
      ),
    );
    expect(task.id, isNot('new'));
    expect(task.tytul, 'Test task');

    final renamed = await repo.updateZadanie(
      task.copyWith(tytul: 'Renamed'),
    );
    expect(renamed.tytul, 'Renamed');

    final member = Grzybiarz(
      id: 'u-test',
      imie: 'Ewa',
      nazwisko: 'Test',
      email: 'e@t.pl',
    );
    await repo.addCzlonnek(parentId, member);
    var members = await repo.listCzlonkowie(parentId);
    expect(members.any((m) => m.id == 'u-test'), isTrue);

    await repo.removeCzlonnek(parentId, 'u-test');
    members = await repo.listCzlonkowie(parentId);
    expect(members.any((m) => m.id == 'u-test'), isFalse);

    await repo.deleteZadanie(task.id);
    final tasks = await repo.listZadania(parentId);
    expect(tasks.any((t) => t.id == task.id), isFalse);
  });
}
