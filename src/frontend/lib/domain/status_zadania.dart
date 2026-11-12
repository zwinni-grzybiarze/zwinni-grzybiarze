enum ZadanieStatus {
  otwarte('OTWARTE', 'Otwarte'),
  zamkniete('ZAMKNIĘTE', 'Zamknięte'),
  zarchiwizowane('ZARCHIWIZOWANE', 'Zarchiwizowane');

  const ZadanieStatus(this.apiValue, this.label);

  final String apiValue;
  final String label;

  static ZadanieStatus? tryParse(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    final normalized = raw.trim().toUpperCase();
    for (final s in ZadanieStatus.values) {
      if (s.apiValue == normalized || s.name.toUpperCase() == normalized) {
        return s;
      }
    }
    return null;
  }
}
