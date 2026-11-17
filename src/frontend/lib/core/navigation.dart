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

/// Prefer popping the stack; fall back to [go] for deep links / refresh.
void popOrGo(BuildContext context, String fallback) {
  if (context.canPop()) {
    context.pop();
  } else {
    context.go(fallback);
  }
}
