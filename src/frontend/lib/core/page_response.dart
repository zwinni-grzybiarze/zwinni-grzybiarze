/// Spring Data [Page] JSON shape.
class PageResponse<T> {
  const PageResponse({
    required this.content,
    required this.totalElements,
    required this.totalPages,
    required this.number,
    required this.size,
  });

  final List<T> content;
  final int totalElements;
  final int totalPages;
  final int number;
  final int size;

  bool get hasNext => number + 1 < totalPages;
  bool get hasPrevious => number > 0;

  factory PageResponse.fromJson(
    Map<String, dynamic> json,
    T Function(Map<String, dynamic>) fromJsonT,
  ) {
    final raw = json['content'] as List<dynamic>? ?? const [];
    return PageResponse<T>(
      content: raw
          .map((e) => fromJsonT(Map<String, dynamic>.from(e as Map)))
          .toList(),
      totalElements: (json['totalElements'] as num?)?.toInt() ?? raw.length,
      totalPages: (json['totalPages'] as num?)?.toInt() ?? 1,
      number: (json['number'] as num?)?.toInt() ?? 0,
      size: (json['size'] as num?)?.toInt() ?? raw.length,
    );
  }

  factory PageResponse.fromList(
    List<T> all, {
    required int page,
    required int size,
  }) {
    if (size <= 0) size = 10;
    final total = all.length;
    final totalPages = total == 0 ? 1 : ((total + size - 1) ~/ size);
    final safePage = page.clamp(0, totalPages - 1);
    final start = safePage * size;
    final end = (start + size).clamp(0, total);
    return PageResponse<T>(
      content: all.sublist(start, end),
      totalElements: total,
      totalPages: totalPages,
      number: safePage,
      size: size,
    );
  }
}
