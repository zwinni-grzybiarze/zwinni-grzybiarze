import 'package:flutter_test/flutter_test.dart';
import 'package:onlyshrooms/domain/grzybobranie.dart';
import 'package:onlyshrooms/domain/status.dart';

void main() {
  group('Grzybobranie', () {
    test('fromJson keeps known fields accessible and extras in map', () {
      final g = Grzybobranie.fromJson({
        'grzybobranieId': 7,
        'nazwa': 'Test',
        'opis': 'Opis',
        'lokalizacja': 'Las',
        'status': 'W_TOKU',
        'dataOd': '2026-10-01',
        'dataDo': '2026-10-02',
        'futureField': 'keep-me',
        'zadania': [
          {
            'zadanieId': 1,
            'tytul': 'Kosze',
            'opis': 'x',
            'grzybobranieId': 7,
          },
        ],
        'czlonkowie': [
          {'grzybiarzId': 'u1', 'imie': 'A', 'nazwisko': 'B'},
        ],
      });

      expect(g.id, '7');
      expect(g.nazwa, 'Test');
      expect(g.opis, 'Opis');
      expect(g.lokalizacja, 'Las');
      expect(g.status, GrzybobranieStatus.wToku);
      expect(g.getField<String>('futureField'), 'keep-me');
      expect(g.zadania, hasLength(1));
      expect(g.zadania.first.nazwa, 'Kosze');
      expect(g.czlonkowie.first.displayName, 'A B');
    });

    test('toJson round-trips flexible fields', () {
      final original = Grzybobranie(
        id: '9',
        nazwa: 'Round',
        fields: {
          'opis': 'o',
          'status': 'PLANOWANE',
          'custom': 42,
        },
      );

      final restored = Grzybobranie.fromJson(original.toJson());
      expect(restored.id, '9');
      expect(restored.nazwa, 'Round');
      expect(restored.getField<int>('custom'), 42);
      expect(restored.status, GrzybobranieStatus.planowane);
    });

    test('copyWithField updates map without dropping other keys', () {
      final g = Grzybobranie(
        id: '1',
        nazwa: 'N',
        fields: {'opis': 'a', 'status': 'PLANOWANE'},
      ).copyWithField('opis', 'b');

      expect(g.opis, 'b');
      expect(g.status, GrzybobranieStatus.planowane);
    });

    test('isArchived follows zarchiwizowane status', () {
      final active = Grzybobranie(
        id: '1',
        nazwa: 'N',
        fields: {'status': 'PLANOWANE'},
      );
      final archived = active.copyWithField(
        'status',
        GrzybobranieStatus.zarchiwizowane.apiValue,
      );
      expect(active.isArchived, isFalse);
      expect(archived.isArchived, isTrue);
    });
  });

  group('GrzybobranieStatus', () {
    test('tryParse accepts api values', () {
      expect(
        GrzybobranieStatus.tryParse('ODROCZONE'),
        GrzybobranieStatus.odroczone,
      );
      expect(
        GrzybobranieStatus.tryParse('ZARCHIWIZOWANE'),
        GrzybobranieStatus.zarchiwizowane,
      );
      expect(GrzybobranieStatus.tryParse('nope'), isNull);
    });
  });
}
