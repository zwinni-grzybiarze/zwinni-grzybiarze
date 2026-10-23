import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:onlyshrooms/core/responsive.dart';

void main() {
  Future<BuildContext> pumpAtWidth(WidgetTester tester, double width) async {
    late BuildContext captured;
    await tester.pumpWidget(
      MediaQuery(
        data: MediaQueryData(size: Size(width, 800)),
        child: MaterialApp(
          home: Builder(
            builder: (context) {
              captured = context;
              return const SizedBox();
            },
          ),
        ),
      ),
    );
    return captured;
  }

  testWidgets('compact below 600', (tester) async {
    final context = await pumpAtWidth(tester, 390);
    expect(context.isCompact, isTrue);
    expect(context.sizeClass, AppSizeClass.compact);
    expect(context.contentMaxWidth, double.infinity);
  });

  testWidgets('medium between 600 and 1024', (tester) async {
    final context = await pumpAtWidth(tester, 800);
    expect(context.isMedium, isTrue);
    expect(context.contentMaxWidth, 720);
  });

  testWidgets('expanded at 1024+', (tester) async {
    final context = await pumpAtWidth(tester, 1280);
    expect(context.isExpanded, isTrue);
    expect(context.contentMaxWidth, 960);
  });
}
