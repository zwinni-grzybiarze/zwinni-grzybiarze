import 'package:onlyshrooms/domain/status_zadania.dart';
import 'package:onlyshrooms/domain/grzybiarz.dart';

/// Task model.
class Zadanie {
  const Zadanie({
    required this.id,
    this.grzybobranieId,
    required this.nazwa,
    this.opis,
    this.kolejnosc,
    this.fields = const {},
    this.czlonkowie = const [],
  });

  final String id;
  final String? grzybobranieId;
  final String nazwa;
  final String? opis;
  final int? kolejnosc;
  final List<Grzybiarz> czlonkowie;
  final Map<String, dynamic> fields;

  factory Zadanie.fromJson(Map<String, dynamic> json) {
    final id = (json['zadanieId'] ?? json['id']).toString();

    final parent =
        json['grzybobranieId'] ??
        (json['grzybobranie'] is Map
            ? (json['grzybobranie'] as Map)['grzybobranieId'] ??
                  (json['grzybobranie'] as Map)['id']
            : null);

    final rest = Map<String, dynamic>.from(json)
      ..remove('zadanieId')
      ..remove('id')
      ..remove('grzybobranieId')
      ..remove('grzybobranie')
      ..remove('nazwa')
      ..remove('tytul')
      ..remove('opis')
      ..remove('kolejnosc')
      ..remove('czlonkowie');

    return Zadanie(
      id: id,
      grzybobranieId: parent == null || parent.toString().isEmpty
          ? null
          : parent.toString(),
      nazwa: (json['nazwa'] as String?) ?? (json['tytul'] as String?) ?? '',
      opis: json['opis'] as String?,
      kolejnosc: (json['kolejnosc'] as num?)?.toInt(),
      czlonkowie:
          (json['czlonkowie'] as List?)
              ?.map(
                (e) => Grzybiarz.fromJson(Map<String, dynamic>.from(e as Map)),
              )
              .toList() ??
          const [],
      fields: rest,
    );
  }

  Map<String, dynamic> toJson() => {
    'zadanieId': id,
    if (grzybobranieId != null && grzybobranieId!.isNotEmpty)
      'grzybobranieId': int.tryParse(grzybobranieId!) ?? grzybobranieId,
    'nazwa': nazwa,
    if (opis != null) 'opis': opis,
    if (kolejnosc != null) 'kolejnosc': kolejnosc,
    if (czlonkowie.isNotEmpty)
      'czlonkowie': czlonkowie.map((e) => e.toJson()).toList(),
    ...fields,
  };

  ZadanieStatus? get status =>
      ZadanieStatus.tryParse(getField<String>('status'));

  T? getField<T>(String key) {
    final value = fields[key];
    if (value == null) return null;
    if (value is T) return value;
    if (T == String) return value.toString() as T;
    return null;
  }

  Zadanie copyWith({
    String? nazwa,
    String? opis,
    int? kolejnosc,
    List<Grzybiarz>? czlonkowie,
    Map<String, dynamic>? fields,
  }) {
    return Zadanie(
      id: id,
      grzybobranieId: grzybobranieId,
      nazwa: nazwa ?? this.nazwa,
      opis: opis ?? this.opis,
      kolejnosc: kolejnosc ?? this.kolejnosc,
      czlonkowie: czlonkowie ?? this.czlonkowie,
      fields: fields ?? this.fields,
    );
  }
}
