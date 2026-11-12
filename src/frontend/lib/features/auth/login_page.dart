import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:onlyshrooms/app_theme.dart';
import 'package:onlyshrooms/core/responsive.dart';
import 'package:onlyshrooms/features/auth/auth_controller.dart';

class LoginPage extends ConsumerWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authControllerProvider);
    final compact = context.isCompact;

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
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(
                  horizontal: compact ? 20 : 24,
                  vertical: compact ? 16 : 24,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'OnlyShrooms',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.displaySmall?.copyWith(
                            color: OnlyShroomsTheme.cream,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.5,
                            fontSize: compact ? 36 : null,
                          ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Grzybobrania z Twoją ekipą',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: OnlyShroomsTheme.cream.withValues(alpha: 0.8),
                          ),
                    ),
                    const SizedBox(height: 48),
                    FilledButton.icon(
                      onPressed: auth.busy
                          ? null
                          : () async {
                              await ref
                                  .read(authControllerProvider.notifier)
                                  .signInWithGoogle();
                            },
                      icon: const Icon(Icons.g_mobiledata_rounded, size: 28),
                      label: const Padding(
                        padding: EdgeInsets.symmetric(vertical: 14),
                        child: Text('Zaloguj przez Google'),
                      ),
                      style: FilledButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: OnlyShroomsTheme.bark,
                      ),
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      onPressed: auth.busy
                          ? null
                          : () async {
                              await ref
                                  .read(authControllerProvider.notifier)
                                  .signInWithGoogle(register: true);
                              if (context.mounted) context.go('/');
                            },
                      icon: const Icon(Icons.person_add_alt_1),
                      label: const Padding(
                        padding: EdgeInsets.symmetric(vertical: 14),
                        child: Text('Zarejestruj przez Google'),
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: OnlyShroomsTheme.cream,
                        side: const BorderSide(color: OnlyShroomsTheme.cream),
                      ),
                    ),
                    
                    if (auth.busy) ...[
                      const SizedBox(height: 16),
                      const Center(
                        child: CircularProgressIndicator(
                          color: OnlyShroomsTheme.cream,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
