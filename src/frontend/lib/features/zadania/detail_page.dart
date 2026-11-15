import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:onlyshrooms/app_theme.dart';
import 'package:onlyshrooms/core/responsive.dart';
import 'package:onlyshrooms/domain/grzybiarz.dart';
import 'package:onlyshrooms/features/grzybobrania/grzybobrania_controller.dart';
import 'package:onlyshrooms/features/zadania/zadania_controller.dart';

class ZadanieDetailPage extends ConsumerStatefulWidget {
  const ZadanieDetailPage({super.key, required this.id, this.returnToPath});

  final String id;
  final String? returnToPath;

  @override
  ConsumerState<ZadanieDetailPage> createState() => _ZadanieDetailPageState();
}

class _ZadanieDetailPageState extends ConsumerState<ZadanieDetailPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;
  String? _grzybobranieName;
  bool _grzybobranieLoading = false;
  Object? _grzybobranieError;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadDetail();
    });
  }

  Future<void> _loadDetail() async {
    await ref.read(zadaniaControllerProvider.notifier).loadDetail(widget.id);
    if (!mounted) return;
    final zadanie = ref.read(zadaniaControllerProvider).selected;
    final grzybobranieId = zadanie?.grzybobranieId;
    if (zadanie?.id != widget.id || grzybobranieId == null) return;

    setState(() {
      _grzybobranieLoading = true;
      _grzybobranieError = null;
    });
    try {
      final grzybobranie = await ref
          .read(grzybobranieRepositoryProvider)
          .getById(grzybobranieId);
      if (!mounted) return;
      setState(() {
        _grzybobranieName = grzybobranie?.nazwa;
        _grzybobranieLoading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _grzybobranieError = error;
        _grzybobranieLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ctrl = ref.watch(zadaniaControllerProvider);
    final z = ctrl.selected;
    final compact = context.isCompact;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: OnlyShroomsTheme.detailBarBackground,
        toolbarHeight: 48,
        title: Text(
          z?.nazwa ?? 'Zadanie',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(fontSize: compact ? 16 : 18),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go(widget.returnToPath ?? '/zadania'),
        ),
        actions: [
          if (z != null)
            IconButton(
              tooltip: 'Edytuj',
              onPressed: () {
                final location = Uri(
                  path: '/zadania/${z.id}/edit',
                  queryParameters: {
                    if (widget.returnToPath != null)
                      'returnTo': widget.returnToPath!,
                  },
                );
                context.go(location.toString());
              },
              icon: const Icon(Icons.edit),
            ),
        ],
        bottom: TabBar(
          controller: _tabs,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: OnlyShroomsTheme.cream,
          indicatorWeight: 2,
          labelStyle: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: compact ? 12 : 14,
          ),
          unselectedLabelStyle: TextStyle(fontSize: compact ? 12 : 14),
          tabs: compact
              ? const [
                  Tab(
                    height: 44,
                    icon: Icon(Icons.info_outline, size: 20),
                    text: 'Info',
                  ),
                  Tab(
                    height: 44,
                    icon: Icon(Icons.group, size: 20),
                    text: 'Ekipa',
                  ),
                ]
              : const [
                  Tab(height: 44, text: 'Szczegóły'),
                  Tab(height: 44, text: 'Członkowie'),
                ],
        ),
      ),
      body: ctrl.detailLoading
          ? const Center(child: CircularProgressIndicator())
          : z == null
          ? const Center(child: Text('Nie znaleziono'))
          : TabBarView(
              controller: _tabs,
              children: [
                _OverviewTab(
                  itemId: z.id,
                  grzybobranieName: _grzybobranieName,
                  grzybobranieLoading: _grzybobranieLoading,
                  grzybobranieError: _grzybobranieError,
                ),
                _MembersTab(zadanieId: z.id),
              ],
            ),
    );
  }
}

class _OverviewTab extends ConsumerWidget {
  const _OverviewTab({
    required this.itemId,
    required this.grzybobranieName,
    required this.grzybobranieLoading,
    required this.grzybobranieError,
  });

  final String itemId;
  final String? grzybobranieName;
  final bool grzybobranieLoading;
  final Object? grzybobranieError;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final z = ref.watch(zadaniaControllerProvider).selected;
    if (z == null || z.id != itemId) {
      return const SizedBox.shrink();
    }
    final compact = context.isCompact;
    final grzybobranieId = z.grzybobranieId;
    final grzybobranie = grzybobranieId == null
        ? '—'
        : grzybobranieLoading
        ? 'Wczytywanie…'
        : grzybobranieError != null
        ? 'Nie udało się wczytać nazwy — id: $grzybobranieId'
        : '${grzybobranieName ?? 'Grzybobranie'} ($grzybobranieId)';

    return AdaptivePage(
      child: SingleChildScrollView(
        child: Container(
          padding: context.pagePadding,
          decoration: BoxDecoration(
            color: OnlyShroomsTheme.detailPanelBackground,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (compact) ...[
                _stackRow('Status', z.status?.label ?? '—'),
                _stackRow('Grzybobranie', grzybobranie),
              ] else ...[
                _row('Status', z.status?.label ?? '—'),
                _row('Grzybobranie', grzybobranie),
              ],
              const SizedBox(height: 12),
              Text('Opis', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 4),
              Text(z.opis?.isNotEmpty == true ? z.opis! : 'Brak opisu'),
            ],
          ),
        ),
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

class _MembersTab extends ConsumerWidget {
  const _MembersTab({required this.zadanieId});

  final String zadanieId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ctrl = ref.watch(zadaniaControllerProvider);
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
                ? const Center(child: Text('Brak członków',style: TextStyle(color: OnlyShroomsTheme.cream)))
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
                            child: Text(m.imie.isNotEmpty ? m.imie[0] : '?'),
                          ),
                          title: Text(m.displayName),
                          subtitle: Text(m.email ?? 'id: ${m.id}'),
                          trailing: IconButton(
                            icon: const Icon(Icons.person_remove_outlined),
                            onPressed: () => ref
                                .read(zadaniaControllerProvider.notifier)
                                .removeMember(zadanieId, m.id),
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
        .read(zadaniaControllerProvider.notifier)
        .addMember(zadanieId, member);
  }
}
