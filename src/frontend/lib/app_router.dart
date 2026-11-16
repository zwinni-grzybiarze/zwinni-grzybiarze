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

      final uri = state.uri;
      final decodedFragment = uri.fragment.isEmpty
          ? ''
          : Uri.decodeFull(uri.fragment);
      final currentUrl = uri.toString();
      final currentLocation = decodedFragment.isNotEmpty
          ? decodedFragment
          : uri.path.isEmpty
              ? '/'
              : uri.path;
      final isAuthCallback = currentLocation.contains('/auth/callback') ||
          currentUrl.contains('/auth/callback') ||
          currentUrl.contains('auth/callback');
      final isLogin = currentLocation.contains('/login') ||
          currentUrl.contains('/login') ||
          currentUrl.contains('login');

      if (isAuthCallback) return null;
      if (!current.isSignedIn && !isLogin) return '/login';
      if (current.isSignedIn && isLogin && !isAuthCallback) return '/';
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
        path: '/zadania/new',
        builder: (context, state) => ZadanieEditPage(
          initialGrzybobranieId: state.uri.queryParameters['grzybobranieId'],
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
    errorBuilder: (context, state) => Scaffold(
      body: Center(child: Text('Nie znaleziono: ${state.error}')),
    ),
  );
});
