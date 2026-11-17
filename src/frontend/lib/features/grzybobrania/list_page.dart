import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:onlyshrooms/app_theme.dart';
import 'package:onlyshrooms/core/responsive.dart';
import 'package:onlyshrooms/domain/grzybobranie.dart';
import 'package:onlyshrooms/domain/status.dart';
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

  Future<void> _openStatusSheet() async {
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: OnlyShroomsTheme.cream,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (sheetContext) {
        return Consumer(
          builder: (context, ref, _) {
            final selected =
                ref.watch(grzybobraniaControllerProvider).selectedStatuses;
            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(8, 12, 8, 16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Center(
                      child: Container(
                        width: 36,
                        height: 4,
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: OnlyShroomsTheme.bark.withValues(alpha: 0.25),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
                      child: Text(
                        'Filtruj statusy',
                        style: Theme.of(sheetContext)
                            .textTheme
                            .titleMedium
                            ?.copyWith(
                              color: OnlyShroomsTheme.bark,
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                    ),
                    for (final status in GrzybobranieStatus.values)
                      CheckboxListTile(
                        value: selected.contains(status),
                        title: Text(
                          status.label,
                          style: const TextStyle(
                            color: OnlyShroomsTheme.bark,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        activeColor: OnlyShroomsTheme.moss,
                        controlAffinity: ListTileControlAffinity.leading,
                        onChanged: (_) {
                          ref
                              .read(grzybobraniaControllerProvider.notifier)
                              .toggleStatusFilter(status);
                        },
                      ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
                      child: FilledButton(
                        onPressed: () => Navigator.of(sheetContext).pop(),
                        style: FilledButton.styleFrom(
                          backgroundColor: OnlyShroomsTheme.moss,
                          foregroundColor: OnlyShroomsTheme.cream,
                        ),
                        child: const Text('Gotowe'),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final ctrl = ref.watch(grzybobraniaControllerProvider);
    final page = ctrl.page;
    final compact = context.isCompact;

    return Scaffold(
      floatingActionButton: compact
          ? FloatingActionButton(
              onPressed: () => context.push('/grzybobrania/new'),
              tooltip: 'Nowe grzybobranie',
              child: const Icon(Icons.add),
            )
          : FloatingActionButton.extended(
              onPressed: () => context.push('/grzybobrania/new'),
              icon: const Icon(Icons.add),
              label: const Text('Nowe grzybobranie'),
            ),
      body: AdaptivePage(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchCtrl,
                    decoration: InputDecoration(
                      hintText: 'Szukaj po nazwie…',
                      prefixIcon: const Icon(Icons.search),
                      isDense: compact,
                    ),
                    textInputAction: TextInputAction.search,
                    onSubmitted: (_) => _runSearch(),
                  ),
                ),
                const SizedBox(width: 8),
                if (compact)
                  FilledButton(
                    onPressed: _runSearch,
                    style: FilledButton.styleFrom(
                      minimumSize: const Size(48, 48),
                      padding: EdgeInsets.zero,
                    ),
                    child: const Icon(Icons.search),
                  )
                else
                  FilledButton(
                    onPressed: _runSearch,
                    child: const Text('Szukaj'),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            if (compact)
              _StatusFilterButton(
                selected: ctrl.selectedStatuses,
                onPressed: _openStatusSheet,
              )
            else
              _StatusFilterChips(
                selected: ctrl.selectedStatuses,
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
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: OnlyShroomsTheme.cream,
                    ),
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        style: IconButton.styleFrom(
                          foregroundColor: OnlyShroomsTheme.cream,
                          disabledForegroundColor: OnlyShroomsTheme.cream
                              .withValues(alpha: 0.5),
                        ),
                        onPressed: page.hasPrevious
                            ? () => ref
                                  .read(grzybobraniaControllerProvider.notifier)
                                  .loadList(page: page.number - 1)
                            : null,
                        icon: const Icon(Icons.chevron_left),
                      ),
                      IconButton(
                        style: IconButton.styleFrom(
                          foregroundColor: OnlyShroomsTheme.cream,
                          disabledForegroundColor: OnlyShroomsTheme.cream
                              .withValues(alpha: 0.5),
                        ),
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

class _StatusFilterButton extends StatelessWidget {
  const _StatusFilterButton({
    required this.selected,
    required this.onPressed,
  });

  final Set<GrzybobranieStatus> selected;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final cream = OnlyShroomsTheme.cream;
    final label = selected.isEmpty
        ? 'Statusy: brak'
        : selected.length == GrzybobranieStatus.values.length
            ? 'Statusy: wszystkie'
            : 'Statusy: ${selected.length} wybrane';

    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: Icon(Icons.filter_list, color: cream, size: 20),
      label: Text(label, style: TextStyle(color: cream)),
      style: OutlinedButton.styleFrom(
        foregroundColor: cream,
        side: BorderSide(color: cream.withValues(alpha: 0.55)),
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      ),
    );
  }
}

class _StatusFilterChips extends StatelessWidget {
  const _StatusFilterChips({
    required this.selected,
    required this.onToggle,
  });

  final Set<GrzybobranieStatus> selected;
  final ValueChanged<GrzybobranieStatus> onToggle;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 4,
      children: [
        for (final status in GrzybobranieStatus.values)
          FilterChip(
            label: Text(status.label),
            selected: selected.contains(status),
            visualDensity: VisualDensity.compact,
            backgroundColor: OnlyShroomsTheme.inactiveFilterBackground,
            onSelected: (_) => onToggle(status),
          ),
      ],
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
        onTap: () => context.push('/grzybobrania/${item.id}'),
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
