import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:onlyshrooms/core/responsive.dart';
import 'package:onlyshrooms/features/auth/auth_controller.dart';
import 'package:onlyshrooms/features/auth/login_page.dart';
import 'package:onlyshrooms/features/grzybobrania/detail_page.dart';
import 'package:onlyshrooms/features/grzybobrania/edit_page.dart';
import 'package:onlyshrooms/features/grzybobrania/list_page.dart';
import 'package:onlyshrooms/features/zadania/detail_page.dart';
import 'package:onlyshrooms/features/zadania/edit_page.dart';
import 'package:onlyshrooms/features/zadania/list_page.dart';

/// Created once; auth changes refresh redirects via [refreshListenable].
final goRouterProvider = Provider<GoRouter>((ref) {
  // Prefer [read] so notifyListeners does not rebuild a new GoRouter.
  final auth = ref.read(authControllerProvider);

  return GoRouter(
    initialLocation: '/login',
    refreshListenable: auth,
    redirect: (context, state) {
      final current = ref.read(authControllerProvider);
      if (!current.ready) return null;
      final loggingIn = state.matchedLocation == '/login';
      if (!current.isSignedIn && !loggingIn) return '/login';
      if (current.isSignedIn && loggingIn) return '/';
      return null;
    },
    routes: [
      GoRoute(path: '/login', builder: (context, state) => const LoginPage()),
      ShellRoute(
        builder: (context, state, child) => _AuthenticatedShell(child: child),
        routes: [
          GoRoute(
            path: '/',
            builder: (context, state) => const GrzybobraniaListPage(),
          ),
          GoRoute(
            path: '/grzybobrania/new',
            builder: (context, state) => const GrzybobranieEditPage(),
          ),
          GoRoute(
            path: '/grzybobrania/:id',
            builder: (context, state) => GrzybobranieDetailPage(
              id: state.pathParameters['id']!,
              initialTab: state.uri.queryParameters['tab'] == 'zadania' ? 1 : 0,
            ),
          ),
          GoRoute(
            path: '/grzybobrania/:id/edit',
            builder: (context, state) =>
                GrzybobranieEditPage(id: state.pathParameters['id']),
          ),
          GoRoute(
            path: '/zadania',
            builder: (context, state) => const ZadaniaListPage(),
          ),
          GoRoute(
            path: '/zadania/new',
            builder: (context, state) => ZadanieEditPage(
              initialGrzybobranieId:
                  state.uri.queryParameters['grzybobranieId'],
              returnToGrzybobranieId:
                  state.uri.queryParameters['returnToGrzybobranieId'],
              returnToPath: state.uri.queryParameters['returnTo'],
            ),
          ),
          GoRoute(
            path: '/zadania/:id',
            builder: (context, state) => ZadanieDetailPage(
              id: state.pathParameters['id']!,
              returnToPath: state.uri.queryParameters['returnTo'],
            ),
          ),
          GoRoute(
            path: '/zadania/:id/edit',
            builder: (context, state) => ZadanieEditPage(
              id: state.pathParameters['id'],
              returnToPath: state.uri.queryParameters['returnTo'],
            ),
          ),
        ],
      ),
    ],
    errorBuilder: (context, state) =>
        Scaffold(body: Center(child: Text('Nie znaleziono: ${state.error}'))),
  );
});

class _AuthenticatedShell extends ConsumerWidget {
  const _AuthenticatedShell({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authControllerProvider);
    final compact = context.isCompact;

    return Scaffold(
      appBar: AppBar(
        title: Semantics(
          button: true,
          label: 'Strona główna',
          child: InkWell(
            borderRadius: BorderRadius.circular(4),
            onTap: () => context.go('/'),
            child: const Padding(
              padding: EdgeInsets.symmetric(vertical: 4),
              child: Text('OnlyShrooms'),
            ),
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Zadania',
            onPressed: () => context.go('/zadania'),
            icon: const Icon(Icons.checklist),
          ),
          if (auth.user != null && !compact)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Center(
                child: Text(
                  auth.user!.displayName,
                  style: const TextStyle(fontSize: 13),
                ),
              ),
            ),
          IconButton(
            tooltip: 'Wyloguj',
            onPressed: () async {
              await ref.read(authControllerProvider.notifier).signOut();
              if (context.mounted) context.go('/login');
            },
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: child,
    );
  }
}
