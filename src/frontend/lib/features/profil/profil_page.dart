import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:onlyshrooms/app_theme.dart';
import 'package:onlyshrooms/features/auth/auth_controller.dart';

class ProfilPage extends ConsumerWidget {
  const ProfilPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authControllerProvider);
    final user = auth.user;
    final cream = OnlyShroomsTheme.cream;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 12),
          child: Column(
            children: [
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (user != null) ...[
                        CircleAvatar(
                          radius: 36,
                          backgroundColor: OnlyShroomsTheme.moss,
                          child: Text(
                            _initials(user.imie, user.nazwisko),
                            style: const TextStyle(
                              color: OnlyShroomsTheme.cream,
                              fontSize: 24,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          user.displayName,
                          style: Theme.of(context).textTheme.headlineSmall
                              ?.copyWith(color: cream),
                          textAlign: TextAlign.center,
                        ),
                        if (user.email != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            user.email!,
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(
                              color: cream.withValues(alpha: 0.9),
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                        const SizedBox(height: 24),
                        OutlinedButton.icon(
                          onPressed: () => context.push('/uzytkownicy'),
                          icon: Icon(Icons.groups_outlined, color: cream),
                          label: Text(
                            'Wszyscy użytkownicy',
                            style: TextStyle(color: cream),
                          ),
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(color: cream.withValues(alpha: 0.6)),
                          ),
                        ),
                        const SizedBox(height: 24),
                      ],
                      FilledButton.icon(
                        onPressed: () async {
                          await ref
                              .read(authControllerProvider.notifier)
                              .signOut();
                          if (context.mounted) context.go('/login');
                        },
                        icon: const Icon(Icons.logout),
                        label: const Text('Wyloguj'),
                      ),
                    ],
                  ),
                ),
              ),
              Text(
                'Mushroom icons created by Magnific - Flaticon',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: cream.withValues(alpha: 0.7),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static String _initials(String imie, String nazwisko) {
    final a = imie.isNotEmpty ? imie[0] : '';
    final b = nazwisko.isNotEmpty ? nazwisko[0] : '';
    final value = '$a$b'.toUpperCase();
    return value.isEmpty ? '?' : value;
  }
}
