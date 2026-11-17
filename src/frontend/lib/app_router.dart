import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:onlyshrooms/core/navigation.dart';
import 'package:onlyshrooms/features/auth/auth_callback_page.dart';
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
    navigatorKey: rootNavigatorKey,
    initialLocation: '/login',
    refreshListenable: auth,
    redirect: (context, state) {
      final current = ref.read(authControllerProvider);
      if (!current.ready) return null;

      final matched = state.matchedLocation;
      final isLogin = matched == '/login';
      final isAuthCallback = matched == '/auth/callback';

      if (isAuthCallback) return null;
      if (!current.isSignedIn && !isLogin) return '/login';
      if (current.isSignedIn && isLogin) return '/';
      return null;
    },
    routes: [
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginPage(),
      ),
      GoRoute(
        path: '/auth/callback',
        builder: (context, state) => AuthCallbackPage(
          token: state.uri.queryParameters['token'],
          email: state.uri.queryParameters['email'],
        ),
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
        pageBuilder: (context, state) => noTransitionPage(
          state: state,
          child: const GrzybobranieEditPage(),
        ),
      ),
      GoRoute(
        path: '/grzybobrania/:id',
        pageBuilder: (context, state) => noTransitionPage(
          state: state,
          child: GrzybobranieDetailPage(
            id: state.pathParameters['id']!,
            initialTab: state.uri.queryParameters['tab'] == 'zadania' ? 1 : 0,
          ),
        ),
      ),
      GoRoute(
        path: '/grzybobrania/:id/edit',
        pageBuilder: (context, state) => noTransitionPage(
          state: state,
          child: GrzybobranieEditPage(id: state.pathParameters['id']),
        ),
      ),
      GoRoute(
        path: '/zadania/new',
        pageBuilder: (context, state) => noTransitionPage(
          state: state,
          child: ZadanieEditPage(
            initialGrzybobranieId: state.uri.queryParameters['grzybobranieId'],
            returnToGrzybobranieId:
                state.uri.queryParameters['returnToGrzybobranieId'],
            returnToPath: state.uri.queryParameters['returnTo'],
          ),
        ),
      ),
      GoRoute(
        path: '/zadania/:id',
        pageBuilder: (context, state) => noTransitionPage(
          state: state,
          child: ZadanieDetailPage(
            id: state.pathParameters['id']!,
            returnToPath: state.uri.queryParameters['returnTo'],
          ),
        ),
      ),
      GoRoute(
        path: '/zadania/:id/edit',
        pageBuilder: (context, state) => noTransitionPage(
          state: state,
          child: ZadanieEditPage(
            id: state.pathParameters['id'],
            returnToPath: state.uri.queryParameters['returnTo'],
          ),
        ),
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(child: Text('Nie znaleziono: ${state.error}')),
    ),
  );
});
