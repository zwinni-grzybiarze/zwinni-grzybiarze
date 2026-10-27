import 'package:flutter_test/flutter_test.dart';
import 'package:onlyshrooms/data/grzybobranie/mock_grzybobranie_repository.dart';
import 'package:onlyshrooms/domain/grzybobranie.dart';
import 'package:onlyshrooms/features/grzybobrania/grzybobrania_controller.dart';

void main() {
  late GrzybobraniaController controller;

  setUp(() {
    controller = GrzybobraniaController(MockGrzybobranieRepository());
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

  test('save create then remove', () async {
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

    await controller.remove(created.id);
    await controller.loadList(nazwa: 'Controller create', page: 0);
    expect(
      controller.page!.content.any((g) => g.id == created.id),
      isFalse,
    );
  });
}
