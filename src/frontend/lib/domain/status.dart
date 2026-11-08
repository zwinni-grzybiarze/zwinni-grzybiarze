/// Provisional statuses from issue #43 — not a frozen BE contract.
enum GrzybobranieStatus {
  planowane('PLANOWANE', 'Planowane'),
  odroczone('ODROCZONE', 'Odroczone'),
  wToku('W_TOKU', 'W toku'),
  zakonczone('ZAKONCZONE', 'Zakończone'),
  zarchiwizowane('ZARCHIWIZOWANE', 'Zarchiwizowane');

  const GrzybobranieStatus(this.apiValue, this.label);

  final String apiValue;
  final String label;

  bool get isArchived => this == GrzybobranieStatus.zarchiwizowane;

  /// Default list filters: every status except archived.
  static Set<GrzybobranieStatus> get defaultListFilters => {
        for (final s in GrzybobranieStatus.values)
          if (!s.isArchived) s,
      };

  static GrzybobranieStatus? tryParse(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    final normalized = raw.trim().toUpperCase().replaceAll(' ', '_');
    for (final s in GrzybobranieStatus.values) {
      if (s.apiValue == normalized || s.name.toUpperCase() == normalized) {
        return s;
      }
    }
    return null;
  }
}
