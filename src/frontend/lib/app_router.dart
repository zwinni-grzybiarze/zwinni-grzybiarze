import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:onlyshrooms/features/auth/auth_callback_page.dart';
import 'package:onlyshrooms/features/auth/auth_controller.dart';
import 'package:onlyshrooms/features/auth/login_page.dart';
import 'package:onlyshrooms/features/grzybobrania/detail_page.dart';
import 'package:onlyshrooms/features/grzybobrania/edit_page.dart';
import 'package:onlyshrooms/features/grzybobrania/list_page.dart';

/// Created once; auth changes refresh redirects via [refreshListenable].
final goRouterProvider = Provider<GoRouter>((ref) {
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
          : uri.path.isEmpty ? '/' : uri.path;
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
      GoRoute(
        path: '/auth/callback',
        builder: (context, state) => AuthCallbackPage(
          token: state.uri.queryParameters['token'],
          email: state.uri.queryParameters['email'],
        ),
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