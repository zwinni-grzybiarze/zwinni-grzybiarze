import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:onlyshrooms/core/responsive.dart';
import 'package:onlyshrooms/domain/zadanie.dart';
import 'package:onlyshrooms/domain/status_zadania.dart';
import 'package:onlyshrooms/features/zadania/zadania_controller.dart';

class ZadanieEditPage extends ConsumerStatefulWidget {
  const ZadanieEditPage({super.key, this.id});

  final String? id;

  bool get isNew => id == null || id == 'new';

  @override
  ConsumerState<ZadanieEditPage> createState() =>
      _ZadanieEditPageState();
}

class _ZadanieEditPageState extends ConsumerState<ZadanieEditPage> {
  final _formKey = GlobalKey<FormState>();
  final _nazwa = TextEditingController();
  final _opis = TextEditingController();
  final _grzybobranie = TextEditingController();
  ZadanieStatus _status = ZadanieStatus.otwarte;
  bool _loading = true;
  bool _saving = false;
  String? _existingId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _bootstrap());
  }

  Future<void> _bootstrap() async {
    if (widget.isNew) {
      setState(() => _loading = false);
      return;
    }
    final ctrl = ref.read(zadaniaControllerProvider.notifier);
    await ctrl.loadDetail(widget.id!);
    final z = ctrl.selected;
    if (z != null) {
      _existingId = z.id;
      _nazwa.text = z.nazwa;
      _opis.text = z.opis ?? '';
      _grzybobranie.text = z.grzybobranieId;
      _status = z.status ?? ZadanieStatus.otwarte;
    }
    if (mounted) setState(() => _loading = false);
  }

  @override
  void dispose() {
    _nazwa.dispose();
    _opis.dispose();
    _grzybobranie.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    final item = Zadanie(
      id: _existingId ?? 'new',
      nazwa: _nazwa.text.trim(),
      grzybobranieId: _grzybobranie.text,
      fields: {
        'opis': _opis.text.trim(),
        'status': _status.apiValue,
      },
    );
    try {
      final saved = await ref
          .read(zadaniaControllerProvider.notifier)
          .save(item, isNew: widget.isNew);
      if (mounted) context.go('/zadania/${saved.id}');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Błąd zapisu: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isNew ? 'Nowe zadanie' : 'Edycja zadania'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (widget.isNew) {
              context.go('/zadania');
            } else {
              context.go('/zadania/${widget.id}');
            }
          },
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : AdaptivePage(
              maxWidth: context.formMaxWidth,
              child: SingleChildScrollView(
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                        TextFormField(
                          controller: _nazwa,
                          decoration: const InputDecoration(labelText: 'Nazwa'),
                          validator: (v) => (v == null || v.trim().isEmpty)
                              ? 'Wymagane'
                              : null,
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _opis,
                          decoration: const InputDecoration(labelText: 'Opis'),
                          maxLines: 4,
                        ),                        
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _grzybobranie,
                          decoration: const InputDecoration(labelText: 'Grzybobranie'),
                          ),
                        const SizedBox(height: 12),
                        DropdownButtonFormField<ZadanieStatus>(
                          // ignore: deprecated_member_use
                          value: _status,
                          decoration:
                              const InputDecoration(labelText: 'Status'),
                          items: ZadanieStatus.values
                              .map(
                                (s) => DropdownMenuItem(
                                  value: s,
                                  child: Text(s.label),
                                ),
                              )
                              .toList(),
                          onChanged: (v) {
                            if (v != null) setState(() => _status = v);
                          },
                        ),
                        const SizedBox(height: 12),
                        FilledButton(
                          onPressed: _saving ? null : _save,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            child: Text(_saving ? 'Zapisywanie…' : 'Zapisz'),
                          ),
                        ),
                        // Extra space so FAB / keyboard don't cover the button.
                        SizedBox(height: context.isCompact ? 24 : 8),
                      ],
                    ),
                  ),
                ),
              ),
    );
  }
}
