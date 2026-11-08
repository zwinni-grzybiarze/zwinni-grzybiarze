import 'package:onlyshrooms/domain/grzybiarz.dart';
import 'package:onlyshrooms/domain/status.dart';
import 'package:onlyshrooms/domain/zadanie.dart';

/// Flexible grzybobranie until BE field contract is agreed.
///
/// Known issue #43 keys are exposed as convenience getters; everything else
/// lives in [fields] and round-trips through JSON without FE churn.
class Grzybobranie {
  Grzybobranie({
    required this.id,
    required this.nazwa,
    Map<String, dynamic>? fields,
    List<Zadanie>? zadania,
    List<Grzybiarz>? czlonkowie,
  })  : fields = Map<String, dynamic>.from(fields ?? const {}),
        zadania = List<Zadanie>.from(zadania ?? const []),
        czlonkowie = List<Grzybiarz>.from(czlonkowie ?? const []);

  final String id;
  final String nazwa;
  final Map<String, dynamic> fields;
  final List<Zadanie> zadania;
  final List<Grzybiarz> czlonkowie;

  String? get opis => getField<String>('opis');
  String? get lokalizacja => getField<String>('lokalizacja');
  String? get dataOd => getField<String>('dataOd');
  String? get dataDo => getField<String>('dataDo');

  GrzybobranieStatus? get status =>
      GrzybobranieStatus.tryParse(getField<String>('status'));

  bool get isArchived => status?.isArchived == true;

  T? getField<T>(String key) {
    final value = fields[key];
    if (value == null) return null;
    if (value is T) return value;
    if (T == String) return value.toString() as T;
    return null;
  }

  Grzybobranie copyWith({
    String? nazwa,
    Map<String, dynamic>? fields,
    List<Zadanie>? zadania,
    List<Grzybiarz>? czlonkowie,
  }) {
    return Grzybobranie(
      id: id,
      nazwa: nazwa ?? this.nazwa,
      fields: fields ?? this.fields,
      zadania: zadania ?? this.zadania,
      czlonkowie: czlonkowie ?? this.czlonkowie,
    );
  }

  Grzybobranie copyWithField(String key, Object? value) {
    final next = Map<String, dynamic>.from(fields);
    if (value == null) {
      next.remove(key);
    } else {
      next[key] = value;
    }
    return copyWith(fields: next);
  }

  factory Grzybobranie.fromJson(Map<String, dynamic> json) {
    final id = (json['grzybobranieId'] ?? json['id']).toString();
    final nazwa = (json['nazwa'] as String?) ?? '';

    final zadaniaRaw = json['zadania'] as List<dynamic>? ?? const [];
    final membersRaw = json['czlonkowie'] as List<dynamic>? ?? const [];

    final rest = Map<String, dynamic>.from(json)
      ..remove('grzybobranieId')
      ..remove('id')
      ..remove('nazwa')
      ..remove('zadania')
      ..remove('czlonkowie');

    return Grzybobranie(
      id: id,
      nazwa: nazwa,
      fields: rest,
      zadania: zadaniaRaw
          .map((e) => Zadanie.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList(),
      czlonkowie: membersRaw
          .map((e) => Grzybiarz.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() => {
        'grzybobranieId': id,
        'nazwa': nazwa,
        ...fields,
        'zadania': zadania.map((z) => z.toJson()).toList(),
        'czlonkowie': czlonkowie.map((c) => c.toJson()).toList(),
      };
}
