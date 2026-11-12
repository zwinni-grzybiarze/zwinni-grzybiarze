import 'package:flutter_test/flutter_test.dart';
import 'package:onlyshrooms/domain/grzybiarz.dart';
import 'package:onlyshrooms/domain/zadanie.dart';

void main() {
  test('Zadanie can be saved with or without a grzybobranie', () {
    const unlinked = Zadanie(id: 'new', nazwa: 'Nowe zadanie');
    expect(unlinked.grzybobranieId, isNull);
    expect(unlinked.toJson().containsKey('grzybobranieId'), isFalse);

    const linked = Zadanie(
      id: 'new',
      grzybobranieId: '12',
      nazwa: 'Połączone zadanie',
    );
    final json = linked.toJson();
    expect(json['grzybobranieId'], 12);
    expect(Zadanie.fromJson(json).grzybobranieId, '12');
  });

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

    expect(byTytul.nazwa, 'A');
    expect(byTytul.grzybobranieId, '2');
    expect(nested.nazwa, 'B');
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
