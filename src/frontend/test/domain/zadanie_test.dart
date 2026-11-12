import 'package:flutter_test/flutter_test.dart';
import 'package:onlyshrooms/domain/grzybiarz.dart';
import 'package:onlyshrooms/domain/status_zadania.dart';
import 'package:onlyshrooms/domain/zadanie.dart';

void main() {
  test(
    'fromJson reads task fields, linked grzybobranie, members, and extras',
    () {
      final zadanie = Zadanie.fromJson({
        'zadanieId': 12,
        'nazwa': 'Zabrać kosz',
        'opis': 'Duży kosz',
        'grzybobranieId': 34,
        'status': 'OTWARTE',
        'czlonkowie': [
          {'grzybiarzId': 'u1', 'imie': 'Ada', 'nazwisko': 'Las'},
        ],
        'custom': true,
      });

      expect(zadanie.id, '12');
      expect(zadanie.nazwa, 'Zabrać kosz');
      expect(zadanie.opis, 'Duży kosz');
      expect(zadanie.grzybobranieId, '34');
      expect(zadanie.status, ZadanieStatus.otwarte);
      expect(zadanie.czlonkowie.single.displayName, 'Ada Las');
      expect(zadanie.getField<bool>('custom'), isTrue);
    },
  );

  test(
    'fromJson supports legacy and nested parent formats and unlinked tasks',
    () {
      final legacy = Zadanie.fromJson({
        'id': 'legacy',
        'nazwa': 'Stare zadanie',
        'grzybobranie': {'id': 8},
      });
      final unlinked = Zadanie.fromJson({
        'zadanieId': 9,
        'nazwa': 'Bez wyprawy',
        'grzybobranieId': null,
      });

      expect(legacy.nazwa, 'Stare zadanie');
      expect(legacy.grzybobranieId, '8');
      expect(unlinked.grzybobranieId, isNull);
    },
  );

  test(
    'toJson omits absent optional fields and serializes linked IDs as numbers',
    () {
      const unlinked = Zadanie(id: 'new', nazwa: 'Luźne zadanie');
      const linked = Zadanie(
        id: 'new',
        nazwa: 'Połączone zadanie',
        grzybobranieId: '23',
        opis: 'Przygotować sprzęt',
        fields: {'status': 'ZAMKNIĘTE'},
      );

      final unlinkedJson = unlinked.toJson();
      final linkedJson = linked.toJson();

      expect(unlinkedJson.containsKey('grzybobranieId'), isFalse);
      expect(unlinkedJson.containsKey('opis'), isFalse);
      expect(linkedJson['grzybobranieId'], 23);
      expect(linkedJson['status'], 'ZAMKNIĘTE');
      expect(Zadanie.fromJson(linkedJson).grzybobranieId, '23');
    },
  );

  test(
    'copyWith keeps relationship and converts status values to status enum',
    () {
      const zadanie = Zadanie(
        id: '1',
        nazwa: 'Stara nazwa',
        grzybobranieId: '4',
        fields: {'status': 'OTWARTE'},
      );

      final updated = zadanie.copyWith(nazwa: 'Nowa nazwa');

      expect(updated.nazwa, 'Nowa nazwa');
      expect(updated.grzybobranieId, '4');
      expect(updated.status, ZadanieStatus.otwarte);
      expect(updated.getField<int>('missing'), isNull);
    },
  );

  test('toJson serializes members', () {
    const member = Grzybiarz(id: 'u1', imie: 'Jan', nazwisko: 'Las');
    const zadanie = Zadanie(id: '1', nazwa: 'Zadanie', czlonkowie: [member]);

    expect(
      Zadanie.fromJson(zadanie.toJson()).czlonkowie.single.displayName,
      'Jan Las',
    );
  });
}
