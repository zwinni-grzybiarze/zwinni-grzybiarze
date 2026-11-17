import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:onlyshrooms/app_theme.dart';
import 'package:onlyshrooms/core/navigation.dart';
import 'package:onlyshrooms/data/grzybiarz/grzybiarz_repository.dart';
import 'package:onlyshrooms/domain/grzybiarz.dart';
import 'package:onlyshrooms/features/auth/auth_controller.dart';

final _userProfileProvider =
    FutureProvider.autoDispose.family<Grzybiarz, String>((ref, id) {
  return ref.watch(grzybiarzRepositoryProvider).getById(id);
});

class UserProfilePage extends ConsumerWidget {
  const UserProfilePage({super.key, required this.userId});

  final String userId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(_userProfileProvider(userId));
    final me = ref.watch(authControllerProvider).user;
    final cream = OnlyShroomsTheme.cream;
    final isSelf = me?.id == userId;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: OnlyShroomsTheme.forest,
        foregroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        shadowColor: Colors.transparent,
        leading: BackButton(
          onPressed: () => popOrGo(context, '/uzytkownicy'),
        ),
        title: const Text('Profil'),
      ),
      body: async.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: OnlyShroomsTheme.cream),
        ),
        error: (e, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              'Nie udało się wczytać profilu: $e',
              style: TextStyle(color: cream),
              textAlign: TextAlign.center,
            ),
          ),
        ),
        data: (user) {
          final email = isSelf ? (me?.email ?? user.email) : null;
          return Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircleAvatar(
                    radius: 48,
                    backgroundColor: OnlyShroomsTheme.moss,
                    child: Text(
                      _initials(user),
                      style: const TextStyle(
                        color: OnlyShroomsTheme.cream,
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    user.displayName,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          color: cream,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  if (email != null && email.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      email,
                      textAlign: TextAlign.center,
                      style: TextStyle(color: cream.withValues(alpha: 0.85)),
                    ),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  static String _initials(Grzybiarz user) {
    final a = user.imie.isNotEmpty ? user.imie[0] : '';
    final b = user.nazwisko.isNotEmpty ? user.nazwisko[0] : '';
    final value = '$a$b'.toUpperCase();
    return value.isEmpty ? '?' : value;
  }
}
