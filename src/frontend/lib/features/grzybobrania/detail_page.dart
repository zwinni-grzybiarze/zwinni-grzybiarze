import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:onlyshrooms/app_theme.dart';
import 'package:onlyshrooms/core/responsive.dart';
import 'package:onlyshrooms/domain/grzybiarz.dart';
import 'package:onlyshrooms/domain/zadanie.dart';
import 'package:onlyshrooms/features/grzybobrania/grzybobrania_controller.dart';

class GrzybobranieDetailPage extends ConsumerStatefulWidget {
  const GrzybobranieDetailPage({super.key, required this.id});

  final String id;

  @override
  ConsumerState<GrzybobranieDetailPage> createState() =>
      _GrzybobranieDetailPageState();
}

class _GrzybobranieDetailPageState
    extends ConsumerState<GrzybobranieDetailPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 3, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref
          .read(grzybobraniaControllerProvider.notifier)
          .loadDetail(widget.id);
    });
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ctrl = ref.watch(grzybobraniaControllerProvider);
    final g = ctrl.selected;
    final compact = context.isCompact;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          g?.nazwa ?? 'Grzybobranie',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/'),
        ),
        actions: [
          if (g != null)
            IconButton(
              tooltip: 'Edytuj',
              onPressed: () => context.go('/grzybobrania/${g.id}/edit'),
              icon: const Icon(Icons.edit),
            ),
        ],
        bottom: TabBar(
          controller: _tabs,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: OnlyShroomsTheme.cream,
          indicatorWeight: 3,
          labelStyle: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: compact ? 12 : 14,
          ),
          unselectedLabelStyle: TextStyle(fontSize: compact ? 12 : 14),
          tabs: compact
              ? const [
                  Tab(icon: Icon(Icons.info_outline, size: 20), text: 'Info'),
                  Tab(icon: Icon(Icons.checklist, size: 20), text: 'Zadania'),
                  Tab(icon: Icon(Icons.group, size: 20), text: 'Ekipa'),
                ]
              : const [
                  Tab(text: 'Szczegóły'),
                  Tab(text: 'Zadania'),
                  Tab(text: 'Członkowie'),
                ],
        ),
      ),
      body: ctrl.detailLoading
          ? const Center(child: CircularProgressIndicator())
          : g == null
              ? const Center(child: Text('Nie znaleziono'))
              : TabBarView(
                  controller: _tabs,
                  children: [
                    _OverviewTab(itemId: g.id),
                    _TasksTab(grzybobranieId: g.id),
                    _MembersTab(grzybobranieId: g.id),
                  ],
                ),
    );
  }
}

class _OverviewTab extends ConsumerWidget {
  const _OverviewTab({required this.itemId});

  final String itemId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final g = ref.watch(grzybobraniaControllerProvider).selected;
    if (g == null || g.id != itemId) {
      return const SizedBox.shrink();
    }
    final compact = context.isCompact;

    return AdaptivePage(
      child: ListView(
        children: [
          if (compact) ...[
            _stackRow('Status', g.status?.label ?? '—'),
            _stackRow('Lokalizacja', g.lokalizacja ?? '—'),
            _stackRow('Okres', '${g.dataOd ?? '?'} → ${g.dataDo ?? '?'}'),
          ] else ...[
            _row('Status', g.status?.label ?? '—'),
            _row('Lokalizacja', g.lokalizacja ?? '—'),
            _row('Okres', '${g.dataOd ?? '?'} → ${g.dataDo ?? '?'}'),
          ],
          const SizedBox(height: 12),
          Text('Opis', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 4),
          Text(g.opis?.isNotEmpty == true ? g.opis! : 'Brak opisu'),
        ],
      ),
    );
  }

  Widget _row(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  Widget _stackRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 2),
          Text(value),
        ],
      ),
    );
  }
}

class _TasksTab extends ConsumerWidget {
  const _TasksTab({required this.grzybobranieId});

  final String grzybobranieId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ctrl = ref.watch(grzybobraniaControllerProvider);
    final tasks = ctrl.selected?.zadania ?? const [];
    final compact = context.isCompact;

    return AdaptivePage(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          Padding(
            padding: context.pagePadding.copyWith(bottom: 8),
            child: Align(
              alignment: Alignment.centerRight,
              child: compact
                  ? IconButton.filled(
                      onPressed: () => _openTaskDialog(context, ref),
                      tooltip: 'Dodaj zadanie',
                      icon: const Icon(Icons.add),
                    )
                  : FilledButton.icon(
                      onPressed: () => _openTaskDialog(context, ref),
                      icon: const Icon(Icons.add),
                      label: const Text('Dodaj zadanie'),
                    ),
            ),
          ),
          Expanded(
            child: tasks.isEmpty
                ? const Center(child: Text('Brak zadań'))
                : ListView.separated(
                    padding: context.pagePadding.copyWith(top: 0),
                    itemCount: tasks.length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: 6),
                    itemBuilder: (context, i) {
                      final t = tasks[i];
                      return Card(
                        child: ListTile(
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: compact ? 12 : 16,
                            vertical: 4,
                          ),
                          title: Text(t.tytul),
                          subtitle: t.opis == null || t.opis!.isEmpty
                              ? null
                              : Text(t.opis!),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit_outlined),
                                onPressed: () => _openTaskDialog(
                                  context,
                                  ref,
                                  existing: t,
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete_outline),
                                onPressed: () => ref
                                    .read(
                                      grzybobraniaControllerProvider.notifier,
                                    )
                                    .removeZadanie(grzybobranieId, t.id),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Future<void> _openTaskDialog(
    BuildContext context,
    WidgetRef ref, {
    Zadanie? existing,
  }) async {
    final tytul = TextEditingController(text: existing?.tytul ?? '');
    final opis = TextEditingController(text: existing?.opis ?? '');
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(existing == null ? 'Nowe zadanie' : 'Edycja zadania'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: tytul,
                decoration: const InputDecoration(labelText: 'Tytuł'),
              ),
              TextField(
                controller: opis,
                decoration: const InputDecoration(labelText: 'Opis'),
                maxLines: 3,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Anuluj'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Zapisz'),
          ),
        ],
      ),
    );
    if (ok != true || !context.mounted) return;
    if (tytul.text.trim().isEmpty) return;
    final zadanie = Zadanie(
      id: existing?.id ?? 'new',
      grzybobranieId: grzybobranieId,
      tytul: tytul.text.trim(),
      opis: opis.text.trim().isEmpty ? null : opis.text.trim(),
      kolejnosc: existing?.kolejnosc,
    );
    await ref.read(grzybobraniaControllerProvider.notifier).saveZadanie(
          grzybobranieId,
          zadanie,
          isNew: existing == null,
        );
  }
}

class _MembersTab extends ConsumerWidget {
  const _MembersTab({required this.grzybobranieId});

  final String grzybobranieId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ctrl = ref.watch(grzybobraniaControllerProvider);
    final members = ctrl.selected?.czlonkowie ?? const [];
    final compact = context.isCompact;

    return AdaptivePage(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          Padding(
            padding: context.pagePadding.copyWith(bottom: 8),
            child: Align(
              alignment: Alignment.centerRight,
              child: compact
                  ? IconButton.filled(
                      onPressed: () => _addMember(context, ref),
                      tooltip: 'Dodaj członka',
                      icon: const Icon(Icons.person_add),
                    )
                  : FilledButton.icon(
                      onPressed: () => _addMember(context, ref),
                      icon: const Icon(Icons.person_add),
                      label: const Text('Dodaj członka'),
                    ),
            ),
          ),
          Expanded(
            child: members.isEmpty
                ? const Center(child: Text('Brak członków'))
                : ListView.separated(
                    padding: context.pagePadding.copyWith(top: 0),
                    itemCount: members.length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: 6),
                    itemBuilder: (context, i) {
                      final m = members[i];
                      return Card(
                        child: ListTile(
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: compact ? 12 : 16,
                            vertical: 4,
                          ),
                          leading: CircleAvatar(
                            child: Text(
                              m.imie.isNotEmpty ? m.imie[0] : '?',
                            ),
                          ),
                          title: Text(m.displayName),
                          subtitle: Text(m.email ?? 'id: ${m.id}'),
                          trailing: IconButton(
                            icon: const Icon(Icons.person_remove_outlined),
                            onPressed: () => ref
                                .read(grzybobraniaControllerProvider.notifier)
                                .removeMember(grzybobranieId, m.id),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Future<void> _addMember(BuildContext context, WidgetRef ref) async {
    final imie = TextEditingController();
    final nazwisko = TextEditingController();
    final email = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Dodaj członka'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: imie,
                decoration: const InputDecoration(labelText: 'Imię'),
              ),
              TextField(
                controller: nazwisko,
                decoration: const InputDecoration(labelText: 'Nazwisko'),
              ),
              TextField(
                controller: email,
                decoration: const InputDecoration(labelText: 'E-mail'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Anuluj'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Dodaj'),
          ),
        ],
      ),
    );
    if (ok != true || !context.mounted) return;
    if (imie.text.trim().isEmpty || nazwisko.text.trim().isEmpty) return;
    final member = Grzybiarz(
      id: 'local-${DateTime.now().millisecondsSinceEpoch}',
      imie: imie.text.trim(),
      nazwisko: nazwisko.text.trim(),
      email: email.text.trim().isEmpty ? null : email.text.trim(),
    );
    await ref
        .read(grzybobraniaControllerProvider.notifier)
        .addMember(grzybobranieId, member);
  }
}
