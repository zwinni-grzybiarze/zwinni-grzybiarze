import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:onlyshrooms/app_router.dart';
import 'package:onlyshrooms/app_theme.dart';

class OnlyShroomsApp extends ConsumerWidget {
  const OnlyShroomsApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(goRouterProvider);

    return MaterialApp.router(
      title: 'OnlyShrooms',
      theme: OnlyShroomsTheme.light(),
      routerConfig: router,
      debugShowCheckedModeBanner: false,
      builder: (context, child) => Stack(
        fit: StackFit.expand,
        children: [
          Image.asset('assets/images/app_background.png', fit: BoxFit.cover),
          const ColoredBox(color: Color(0x66000000)),
          ?child,
        ],
      ),
    );
  }
}
