import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:onlyshrooms/core/responsive.dart';
import 'package:onlyshrooms/domain/grzybobranie.dart';
import 'package:onlyshrooms/domain/status.dart';
import 'package:onlyshrooms/features/auth/auth_controller.dart';
import 'package:onlyshrooms/features/grzybobrania/grzybobrania_controller.dart';

class GrzybobraniaListPage extends ConsumerStatefulWidget {
  const GrzybobraniaListPage({super.key});

  @override
  ConsumerState<GrzybobraniaListPage> createState() =>
      _GrzybobraniaListPageState();
}

class _GrzybobraniaListPageState extends ConsumerState<GrzybobraniaListPage> {
  final _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(grzybobraniaControllerProvider.notifier).loadList();
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _runSearch() {
    ref
        .read(grzybobraniaControllerProvider.notifier)
        .loadList(page: 0, nazwa: _searchCtrl.text);
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authControllerProvider);
    final ctrl = ref.watch(grzybobraniaControllerProvider);
    final page = ctrl.page;
    final compact = context.isCompact;

    return Scaffold(
      appBar: AppBar(
        title: const Text('OnlyShrooms'),
        actions: [
          if (auth.user != null && !compact)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Center(
                child: Text(
                  auth.user!.displayName,
                  style: const TextStyle(fontSize: 13),
                ),
              ),
            ),
          IconButton(
            tooltip: 'Wyloguj',
            onPressed: () async {
              await ref.read(authControllerProvider.notifier).signOut();
              if (context.mounted) context.go('/login');
            },
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      floatingActionButton: compact
          ? FloatingActionButton(
              onPressed: () => context.go('/grzybobrania/new'),
              tooltip: 'Nowe grzybobranie',
              child: const Icon(Icons.add),
            )
          : FloatingActionButton.extended(
              onPressed: () => context.go('/grzybobrania/new'),
              icon: const Icon(Icons.add),
              label: const Text('Nowe grzybobranie'),
            ),
      body: AdaptivePage(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Grzybobrania',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    fontSize: compact ? 22 : null,
                  ),
            ),
            SizedBox(height: compact ? 10 : 12),
            if (compact) ...[
              TextField(
                controller: _searchCtrl,
                decoration: const InputDecoration(
                  hintText: 'Szukaj po nazwie…',
                  prefixIcon: Icon(Icons.search),
                  isDense: true,
                ),
                textInputAction: TextInputAction.search,
                onSubmitted: (_) => _runSearch(),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _runSearch,
                  child: const Text('Szukaj'),
                ),
              ),
            ] else
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _searchCtrl,
                      decoration: const InputDecoration(
                        hintText: 'Szukaj po nazwie…',
                        prefixIcon: Icon(Icons.search),
                      ),
                      onSubmitted: (_) => _runSearch(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(
                    onPressed: _runSearch,
                    child: const Text('Szukaj'),
                  ),
                ],
              ),
            const SizedBox(height: 8),
            _StatusFilterChips(
              selected: ctrl.selectedStatuses,
              compact: compact,
              onToggle: (status) {
                ref
                    .read(grzybobraniaControllerProvider.notifier)
                    .toggleStatusFilter(status);
              },
            ),
            SizedBox(height: compact ? 12 : 16),
            if (ctrl.loading)
              const Expanded(
                child: Center(child: CircularProgressIndicator()),
              )
            else if (ctrl.error != null)
              Expanded(child: Center(child: Text(ctrl.error!)))
            else if (ctrl.selectedStatuses.isEmpty)
              const Expanded(
                child: Center(child: Text('Wybierz status')),
              )
            else if (page == null || page.content.isEmpty)
              const Expanded(
                child: Center(child: Text('Brak grzybobrań')),
              )
            else ...[
              Expanded(
                child: ListView.separated(
                  itemCount: page.content.length,
                  separatorBuilder: (context, index) =>
                      SizedBox(height: compact ? 6 : 8),
                  itemBuilder: (context, i) {
                    return _GrzybobranieTile(
                      item: page.content[i],
                      compact: compact,
                    );
                  },
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 8,
                runSpacing: 4,
                children: [
                  Text(
                    'Strona ${page.number + 1} / ${page.totalPages} '
                    '(${page.totalElements})',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        onPressed: page.hasPrevious
                            ? () => ref
                                .read(grzybobraniaControllerProvider.notifier)
                                .loadList(page: page.number - 1)
                            : null,
                        icon: const Icon(Icons.chevron_left),
                      ),
                      IconButton(
                        onPressed: page.hasNext
                            ? () => ref
                                .read(grzybobraniaControllerProvider.notifier)
                                .loadList(page: page.number + 1)
                            : null,
                        icon: const Icon(Icons.chevron_right),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _StatusFilterChips extends StatelessWidget {
  const _StatusFilterChips({
    required this.selected,
    required this.compact,
    required this.onToggle,
  });

  final Set<GrzybobranieStatus> selected;
  final bool compact;
  final ValueChanged<GrzybobranieStatus> onToggle;

  @override
  Widget build(BuildContext context) {
    final chips = GrzybobranieStatus.values.map((status) {
      final isOn = selected.contains(status);
      return FilterChip(
        label: Text(
          compact ? _shortStatus(status) : status.label,
          style: TextStyle(fontSize: compact ? 12 : 13),
        ),
        selected: isOn,
        visualDensity: VisualDensity.compact,
        onSelected: (_) => onToggle(status),
      );
    }).toList();

    if (compact) {
      return SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            for (var i = 0; i < chips.length; i++) ...[
              if (i > 0) const SizedBox(width: 6),
              chips[i],
            ],
          ],
        ),
      );
    }

    return Wrap(
      spacing: 8,
      runSpacing: 4,
      children: chips,
    );
  }
}

class _GrzybobranieTile extends StatelessWidget {
  const _GrzybobranieTile({required this.item, required this.compact});

  final Grzybobranie item;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final status = item.status;
    return Card(
      child: ListTile(
        contentPadding: EdgeInsets.symmetric(
          horizontal: compact ? 12 : 16,
          vertical: compact ? 6 : 8,
        ),
        title: Text(
          item.nazwa,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: compact ? 15 : null,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (item.lokalizacja != null) Text(item.lokalizacja!),
            if (item.dataOd != null || item.dataDo != null)
              Text(
                '${item.dataOd ?? '?'} → ${item.dataDo ?? '?'}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
          ],
        ),
        isThreeLine: !compact &&
            item.lokalizacja != null &&
            (item.dataOd != null || item.dataDo != null),
        trailing: status == null
            ? null
            : Chip(
                label: Text(
                  compact ? _shortStatus(status) : status.label,
                  style: const TextStyle(fontSize: 12),
                ),
                visualDensity: VisualDensity.compact,
                padding: compact ? EdgeInsets.zero : null,
                backgroundColor: _statusColor(status).withValues(alpha: 0.15),
              ),
        onTap: () => context.go('/grzybobrania/${item.id}'),
      ),
    );
  }

  Color _statusColor(GrzybobranieStatus status) {
    switch (status) {
      case GrzybobranieStatus.planowane:
        return Colors.blue;
      case GrzybobranieStatus.odroczone:
        return Colors.orange;
      case GrzybobranieStatus.wToku:
        return Colors.green;
      case GrzybobranieStatus.zakonczone:
        return Colors.grey;
      case GrzybobranieStatus.zarchiwizowane:
        return Colors.blueGrey;
    }
  }
}

String _shortStatus(GrzybobranieStatus status) {
  switch (status) {
    case GrzybobranieStatus.planowane:
      return 'Plan.';
    case GrzybobranieStatus.odroczone:
      return 'Odr.';
    case GrzybobranieStatus.wToku:
      return 'W toku';
    case GrzybobranieStatus.zakonczone:
      return 'Koniec';
    case GrzybobranieStatus.zarchiwizowane:
      return 'Arch.';
  }
}
