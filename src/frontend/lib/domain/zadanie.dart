/// Thin task until BE contract is agreed (#42: tytul, opis).
class Zadanie {
  const Zadanie({
    required this.id,
    required this.grzybobranieId,
    required this.tytul,
    this.opis,
    this.kolejnosc,
    this.fields = const {},
  });

  final String id;
  final String grzybobranieId;
  final String tytul;
  final String? opis;
  final int? kolejnosc;
  final Map<String, dynamic> fields;

  factory Zadanie.fromJson(Map<String, dynamic> json) {
    final id = (json['zadanieId'] ?? json['id']).toString();
    final parent = json['grzybobranieId'] ??
        (json['grzybobranie'] is Map
            ? (json['grzybobranie'] as Map)['grzybobranieId'] ??
                (json['grzybobranie'] as Map)['id']
            : null);
    final rest = Map<String, dynamic>.from(json)
      ..remove('zadanieId')
      ..remove('id')
      ..remove('grzybobranieId')
      ..remove('grzybobranie')
      ..remove('tytul')
      ..remove('opis')
      ..remove('kolejnosc');
    return Zadanie(
      id: id,
      grzybobranieId: parent?.toString() ?? '',
      tytul: (json['tytul'] as String?) ?? '',
      opis: json['opis'] as String?,
      kolejnosc: (json['kolejnosc'] as num?)?.toInt(),
      fields: rest,
    );
  }

  Map<String, dynamic> toJson() => {
        'zadanieId': id,
        'grzybobranieId': grzybobranieId,
        'tytul': tytul,
        if (opis != null) 'opis': opis,
        if (kolejnosc != null) 'kolejnosc': kolejnosc,
        ...fields,
      };

  Zadanie copyWith({
    String? tytul,
    String? opis,
    int? kolejnosc,
    Map<String, dynamic>? fields,
  }) {
    return Zadanie(
      id: id,
      grzybobranieId: grzybobranieId,
      tytul: tytul ?? this.tytul,
      opis: opis ?? this.opis,
      kolejnosc: kolejnosc ?? this.kolejnosc,
      fields: fields ?? this.fields,
    );
  }
}
