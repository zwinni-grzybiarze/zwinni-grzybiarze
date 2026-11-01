/// Thin user object until BE contract is agreed (#40).
class Grzybiarz {
  const Grzybiarz({
    required this.id,
    required this.imie,
    required this.nazwisko,
    this.email,
    this.fields = const {},
  });

  final String id;
  final String imie;
  final String nazwisko;
  final String? email;
  final Map<String, dynamic> fields;

  String get displayName {
    final name = '$imie $nazwisko'.trim();
    if (name.isNotEmpty) return name;
    if (email != null && email!.isNotEmpty) return email!;
    return 'Grzybiarz';
  }

  factory Grzybiarz.fromJson(Map<String, dynamic> json) {
    final id = (json['grzybiarzId'] ?? json['id']).toString();
    final rest = Map<String, dynamic>.from(json)
      ..remove('grzybiarzId')
      ..remove('id')
      ..remove('imie')
      ..remove('nazwisko')
      ..remove('email');
    return Grzybiarz(
      id: id,
      imie: (json['imie'] as String?) ?? '',
      nazwisko: (json['nazwisko'] as String?) ?? '',
      email: json['email'] as String?,
      fields: rest,
    );
  }

  Map<String, dynamic> toJson() => {
        'grzybiarzId': id,
        'imie': imie,
        'nazwisko': nazwisko,
        if (email != null) 'email': email,
        ...fields,
      };
}
