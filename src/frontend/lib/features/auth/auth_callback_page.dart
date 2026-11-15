import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:onlyshrooms/app_theme.dart';
import 'package:onlyshrooms/features/auth/auth_controller.dart';

/// Landing page for the OAuth redirect (`/auth/callback`).
///
/// GoRouter passes the `token` and `email` query parameters from the callback
/// URL here. The widget hands them off to [AuthController.completeGoogleLogin]
/// and then navigates to `/`.
class AuthCallbackPage extends ConsumerStatefulWidget {
  const AuthCallbackPage({
    super.key,
    required this.token,
    this.email,
  });

  final String? token;
  final String? email;

  @override
  ConsumerState<AuthCallbackPage> createState() => _AuthCallbackPageState();
}

class _AuthCallbackPageState extends ConsumerState<AuthCallbackPage> {
  String? _error;

  @override
  void initState() {
    super.initState();
    _handleCallback();
  }

  Future<void> _handleCallback() async {
    final token = widget.token;
    if (token == null || token.trim().isEmpty) {
      setState(() => _error = 'Brak tokenu w odpowiedzi serwera.');
      return;
    }

    try {
      await ref
          .read(authControllerProvider.notifier)
          .completeGoogleLogin(token, email: widget.email);

      if (mounted) context.go('/');
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              OnlyShroomsTheme.bark,
              OnlyShroomsTheme.forest,
              OnlyShroomsTheme.moss,
            ],
          ),
        ),
        child: Center(
          child: _error != null
              ? _ErrorView(
                  error: _error!,
                  onRetry: () {
                    setState(() => _error = null);
                    _handleCallback();
                  },
                )
              : const _LoadingView(),
        ),
      ),
    );
  }
}

class _LoadingView extends StatelessWidget {
  const _LoadingView();

  @override
  Widget build(BuildContext context) {
    return const Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        CircularProgressIndicator(color: OnlyShroomsTheme.cream),
        SizedBox(height: 24),
        Text(
          'Logowanie…',
          style: TextStyle(color: OnlyShroomsTheme.cream, fontSize: 16),
        ),
      ],
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.error, required this.onRetry});

  final String error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline, color: OnlyShroomsTheme.cream, size: 48),
          const SizedBox(height: 16),
          Text(
            'Logowanie nie powiodło się',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: OnlyShroomsTheme.cream,
                  fontWeight: FontWeight.w600,
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            error,
            style: const TextStyle(
              color: OnlyShroomsTheme.cream,
              fontSize: 13,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          OutlinedButton.icon(
            onPressed: () => context.go('/login'),
            icon: const Icon(Icons.arrow_back),
            label: const Text('Wróć do logowania'),
            style: OutlinedButton.styleFrom(
              foregroundColor: OnlyShroomsTheme.cream,
              side: const BorderSide(color: OnlyShroomsTheme.cream),
            ),
          ),
        ],
      ),
    );
  }
}
