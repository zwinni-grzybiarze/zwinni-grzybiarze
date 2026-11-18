import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Root navigator key for GoRouter.
final rootNavigatorKey = GlobalKey<NavigatorState>();

/// Instant route change — no slide/fade.
NoTransitionPage<void> noTransitionPage({
  required GoRouterState state,
  required Widget child,
}) {
  return NoTransitionPage<void>(
    key: state.pageKey,
    child: child,
  );
}

/// Soft fade + slight vertical drift for auth screens (login ↔ register, etc.).
CustomTransitionPage<void> authTransitionPage({
  required GoRouterState state,
  required Widget child,
}) {
  return CustomTransitionPage<void>(
    key: state.pageKey,
    child: child,
    transitionDuration: const Duration(milliseconds: 320),
    reverseTransitionDuration: const Duration(milliseconds: 280),
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      final curved = CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutCubic,
        reverseCurve: Curves.easeInCubic,
      );
      final fadeOut = CurvedAnimation(
        parent: secondaryAnimation,
        curve: Curves.easeInCubic,
      );

      return FadeTransition(
        opacity: Tween<double>(begin: 0, end: 1).animate(curved),
        child: FadeTransition(
          opacity: Tween<double>(begin: 1, end: 0.72).animate(fadeOut),
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 0.04),
              end: Offset.zero,
            ).animate(curved),
            child: child,
          ),
        ),
      );
    },
  );
}

/// Prefer popping the stack; fall back to [go] for deep links / refresh.
void popOrGo(BuildContext context, String fallback) {
  if (context.canPop()) {
    context.pop();
  } else {
    context.go(fallback);
  }
}
