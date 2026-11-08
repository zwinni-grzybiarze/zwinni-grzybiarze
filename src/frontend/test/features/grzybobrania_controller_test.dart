import 'package:flutter_test/flutter_test.dart';
import 'package:onlyshrooms/data/grzybobranie/mock_grzybobranie_repository.dart';
import 'package:onlyshrooms/domain/grzybobranie.dart';
import 'package:onlyshrooms/domain/status.dart';
import 'package:onlyshrooms/features/grzybobrania/grzybobrania_controller.dart';

void main() {
  late MockGrzybobranieRepository repo;
  late GrzybobraniaController controller;

  setUp(() {
    repo = MockGrzybobranieRepository();
    controller = GrzybobraniaController(repo);
  });

  tearDown(() {
    controller.dispose();
  });

  test('loadList populates page and clears loading', () async {
    expect(controller.loading, isFalse);
    final future = controller.loadList(page: 0);
    expect(controller.loading, isTrue);
    await future;

    expect(controller.loading, isFalse);
    expect(controller.error, isNull);
    expect(controller.page, isNotNull);
    expect(controller.page!.content, isNotEmpty);
  });

  test('loadDetail sets selected', () async {
    await controller.loadDetail('1');
    expect(controller.selected?.id, '1');
    expect(controller.detailLoading, isFalse);
  });

  test('save create', () async {
    final created = await controller.save(
      Grzybobranie(
        id: 'x',
        nazwa: 'Controller create',
        fields: {
          'lokalizacja': 'X',
          'status': 'PLANOWANE',
          'dataOd': '2026-12-01',
          'dataDo': '2026-12-01',
        },
      ),
      isNew: true,
    );

    await controller.loadList(nazwa: 'Controller create', page: 0);
    expect(
      controller.page!.content.any((g) => g.id == created.id),
      isTrue,
    );
  });

  test('remove soft-archives and hides from default list', () async {
    await controller.loadDetail('1');
    await controller.remove('1');

    expect(controller.selected, isNull);
    expect(
      controller.selectedStatuses.contains(GrzybobranieStatus.zarchiwizowane),
      isFalse,
    );
    expect(controller.page!.content.any((g) => g.id == '1'), isFalse);

    final archived = await repo.getById('1');
    expect(archived, isNotNull);
    expect(archived!.status, GrzybobranieStatus.zarchiwizowane);

    await controller.toggleStatusFilter(GrzybobranieStatus.zarchiwizowane);
    expect(controller.page!.content.any((g) => g.id == '1'), isTrue);
  });

  test('toggleStatusFilter narrows results', () async {
    await controller.loadList(page: 0);
    await controller.loadList(
      page: 0,
      statuses: {GrzybobranieStatus.wToku},
    );
    expect(controller.selectedStatuses, {GrzybobranieStatus.wToku});
    expect(
      controller.page!.content.every((g) => g.status == GrzybobranieStatus.wToku),
      isTrue,
    );
  });

  test('remove rejects already archived item', () async {
    await controller.loadDetail('1');
    await controller.remove('1');
    await controller.loadDetail('1');

    await expectLater(
      controller.remove('1'),
      throwsA(isA<StateError>()),
    );
  });
}
