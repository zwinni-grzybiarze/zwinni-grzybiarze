import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:onlyshrooms/core/responsive.dart';
import 'package:onlyshrooms/domain/zadanie.dart';
import 'package:onlyshrooms/domain/status_zadania.dart';
import 'package:onlyshrooms/features/zadania/zadania_controller.dart';

class ZadaniaListPage extends ConsumerStatefulWidget {
  const ZadaniaListPage({super.key});

  @override
  ConsumerState<ZadaniaListPage> createState() =>
      _ZadaniaListPageState();
}

class _ZadaniaListPageState extends ConsumerState<ZadaniaListPage> {
  final _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(zadaniaControllerProvider.notifier).loadList();
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _runSearch() {
    ref
        .read(zadaniaControllerProvider.notifier)
        .loadList(page: 0, nazwa: _searchCtrl.text);
  }

  @override
  Widget build(BuildContext context) {
    final ctrl = ref.watch(zadaniaControllerProvider);
    final page = ctrl.page;
    final compact = context.isCompact;

    return Scaffold(
      appBar: AppBar(
        title: const Text('OnlyShrooms - zadania'),
      ),
      floatingActionButton: compact
          ? FloatingActionButton(
              onPressed: () => context.go('/zadania/new'),
              tooltip: 'Nowe zadanie',
              child: const Icon(Icons.add),
            )
          : FloatingActionButton.extended(
              onPressed: () => context.go('/zadania/new'),
              icon: const Icon(Icons.add),
              label: const Text('Nowe zadanie'),
            ),
      body: AdaptivePage(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Zadania',
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
            SizedBox(height: compact ? 12 : 16),
            if (ctrl.loading)
              const Expanded(
                child: Center(child: CircularProgressIndicator()),
              )
            else if (ctrl.error != null)
              Expanded(child: Center(child: Text(ctrl.error!)))
            else if (page == null || page.content.isEmpty)
              const Expanded(
                child: Center(child: Text('Brak zadań')),
              )
            else ...[
              Expanded(
                child: ListView.separated(
                  itemCount: page.content.length,
                  separatorBuilder: (context, index) =>
                      SizedBox(height: compact ? 6 : 8),
                  itemBuilder: (context, i) {
                    return _ZadanieTile(
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
                                .read(zadaniaControllerProvider.notifier)
                                .loadList(page: page.number - 1)
                            : null,
                        icon: const Icon(Icons.chevron_left),
                      ),
                      IconButton(
                        onPressed: page.hasNext
                            ? () => ref
                                .read(zadaniaControllerProvider.notifier)
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

class _ZadanieTile extends StatelessWidget {
  const _ZadanieTile({required this.item, required this.compact});

  final Zadanie item;
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
            if (item.opis != null) Text(item.opis!),
          ],
        ),
        isThreeLine: !compact &&
            item.opis != null,
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
        onTap: () => context.go('/zadania/${item.id}'),
      ),
    );
  }

  String _shortStatus(ZadanieStatus status) {
    switch (status) {
      case ZadanieStatus.otwarte:
        return 'Otw.';
      case ZadanieStatus.zamkniete:
        return 'Zamk.';
      case ZadanieStatus.zarchiwizowane:
        return 'Zarch.';
    }
  }

  Color _statusColor(ZadanieStatus status) {
    switch (status) {
      case ZadanieStatus.otwarte:
        return Colors.green;
      case ZadanieStatus.zamkniete:
        return Colors.orange;
      case ZadanieStatus.zarchiwizowane:
        return Colors.grey;
    }
  }
}
