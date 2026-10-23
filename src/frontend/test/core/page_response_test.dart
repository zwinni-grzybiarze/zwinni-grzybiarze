import 'package:flutter_test/flutter_test.dart';
import 'package:onlyshrooms/core/page_response.dart';

void main() {
  group('PageResponse.fromList', () {
    test('paginates and reports totals', () {
      final page = PageResponse.fromList(
        List.generate(12, (i) => i),
        page: 1,
        size: 5,
      );

      expect(page.content, [5, 6, 7, 8, 9]);
      expect(page.totalElements, 12);
      expect(page.totalPages, 3);
      expect(page.number, 1);
      expect(page.hasPrevious, isTrue);
      expect(page.hasNext, isTrue);
    });

    test('empty list yields one empty page', () {
      final page = PageResponse.fromList(<int>[], page: 0, size: 10);
      expect(page.content, isEmpty);
      expect(page.totalPages, 1);
      expect(page.hasNext, isFalse);
    });
  });

  group('PageResponse.fromJson', () {
    test('parses Spring page envelope', () {
      final page = PageResponse.fromJson(
        {
          'content': [
            {'id': 1},
            {'id': 2},
          ],
          'totalElements': 2,
          'totalPages': 1,
          'number': 0,
          'size': 10,
        },
        (json) => json['id'] as int,
      );

      expect(page.content, [1, 2]);
      expect(page.totalElements, 2);
      expect(page.size, 10);
    });
  });
}
