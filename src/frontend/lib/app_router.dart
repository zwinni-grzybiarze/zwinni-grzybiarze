import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:onlyshrooms/features/auth/auth_controller.dart';
import 'package:onlyshrooms/features/auth/login_page.dart';
import 'package:onlyshrooms/features/grzybobrania/detail_page.dart';
import 'package:onlyshrooms/features/grzybobrania/edit_page.dart';
import 'package:onlyshrooms/features/grzybobrania/list_page.dart';

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
        builder: (context, state) =>
            GrzybobranieDetailPage(id: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/grzybobrania/:id/edit',
        builder: (context, state) =>
            GrzybobranieEditPage(id: state.pathParameters['id']),
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(child: Text('Nie znaleziono: ${state.error}')),
    ),
  );
});
