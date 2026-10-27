import 'package:flutter_test/flutter_test.dart';
import 'package:onlyshrooms/domain/grzybiarz.dart';
import 'package:onlyshrooms/domain/zadanie.dart';

void main() {
  test('Zadanie.fromJson reads tytul and grzybobranieId', () {
    final byTytul = Zadanie.fromJson({
      'zadanieId': 1,
      'tytul': 'A',
      'grzybobranieId': 2,
    });
    final nested = Zadanie.fromJson({
      'id': 'x',
      'tytul': 'B',
      'grzybobranie': {'grzybobranieId': 3},
    });

    expect(byTytul.tytul, 'A');
    expect(byTytul.grzybobranieId, '2');
    expect(nested.tytul, 'B');
    expect(nested.grzybobranieId, '3');
  });

  test('Grzybiarz displayName and json', () {
    final g = Grzybiarz.fromJson({
      'grzybiarzId': '1',
      'imie': 'Jan',
      'nazwisko': 'Kowalski',
      'email': 'j@x.pl',
      'extra': true,
    });

    expect(g.displayName, 'Jan Kowalski');
    expect(g.toJson()['email'], 'j@x.pl');
    expect(g.fields['extra'], isTrue);
  });
}
