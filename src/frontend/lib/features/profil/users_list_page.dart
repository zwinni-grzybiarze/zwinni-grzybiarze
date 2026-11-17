import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:onlyshrooms/app_theme.dart';
import 'package:onlyshrooms/core/navigation.dart';
import 'package:onlyshrooms/data/grzybiarz/grzybiarz_repository.dart';
import 'package:onlyshrooms/domain/grzybiarz.dart';

final _usersProvider = FutureProvider.autoDispose<List<Grzybiarz>>((ref) {
  return ref.watch(grzybiarzRepositoryProvider).list();
});

class UsersListPage extends ConsumerWidget {
  const UsersListPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(_usersProvider);
    final cream = OnlyShroomsTheme.cream;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: OnlyShroomsTheme.forest,
        foregroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        shadowColor: Colors.transparent,
        leading: BackButton(onPressed: () => popOrGo(context, '/profil')),
        title: const Text('Użytkownicy'),
      ),
      body: async.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: OnlyShroomsTheme.cream),
        ),
        error: (e, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              'Nie udało się wczytać listy: $e',
              style: TextStyle(color: cream),
              textAlign: TextAlign.center,
            ),
          ),
        ),
        data: (users) {
          if (users.isEmpty) {
            return Center(
              child: Text(
                'Brak użytkowników.',
                style: TextStyle(color: cream.withValues(alpha: 0.85)),
              ),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            itemCount: users.length,
            separatorBuilder: (_, _) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final user = users[index];
              return Material(
                color: Colors.white.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(8),
                child: ListTile(
                  title: Text(
                    user.displayName,
                    style: TextStyle(color: cream),
                  ),
                  trailing: Icon(
                    Icons.chevron_right,
                    color: cream.withValues(alpha: 0.7),
                  ),
                  onTap: () => context.push('/uzytkownicy/${user.id}'),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
