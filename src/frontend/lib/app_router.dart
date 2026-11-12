import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:onlyshrooms/features/auth/auth_controller.dart';
import 'package:onlyshrooms/features/auth/login_page.dart';
import 'package:onlyshrooms/features/chat/chat_page.dart';
import 'package:onlyshrooms/features/grzybobrania/detail_page.dart';
import 'package:onlyshrooms/features/grzybobrania/edit_page.dart';
import 'package:onlyshrooms/features/grzybobrania/list_page.dart';
import 'package:onlyshrooms/features/profil/profil_page.dart';
import 'package:onlyshrooms/features/shell/main_shell.dart';
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
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginPage(),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            MainShell(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/',
                builder: (context, state) => const GrzybobraniaListPage(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/zadania',
                builder: (context, state) => const ZadaniaListPage(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/chat',
                builder: (context, state) => const ChatPage(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/profil',
                builder: (context, state) => const ProfilPage(),
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: '/grzybobrania/new',
        builder: (context, state) => const GrzybobranieEditPage(),
      ),
      GoRoute(
        path: '/grzybobrania/:id',
        builder: (context, state) =>
            GrzybobranieDetailPage(id: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/grzybobrania/:id/edit',
        builder: (context, state) =>
            GrzybobranieEditPage(id: state.pathParameters['id']),
      ),
      GoRoute(
        path: '/zadania/new',
        builder: (context, state) => const ZadanieEditPage(),
      ),
      GoRoute(
        path: '/zadania/:id',
        builder: (context, state) =>
            ZadanieDetailPage(id: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/zadania/:id/edit',
        builder: (context, state) =>
            ZadanieEditPage(id: state.pathParameters['id']),
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(child: Text('Nie znaleziono: ${state.error}')),
    ),
  );
});
