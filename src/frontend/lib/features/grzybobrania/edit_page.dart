import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:onlyshrooms/core/responsive.dart';
import 'package:onlyshrooms/domain/grzybobranie.dart';
import 'package:onlyshrooms/domain/status.dart';
import 'package:onlyshrooms/features/grzybobrania/grzybobrania_controller.dart';

class GrzybobranieEditPage extends ConsumerStatefulWidget {
  const GrzybobranieEditPage({super.key, this.id});

  final String? id;

  bool get isNew => id == null || id == 'new';

  @override
  ConsumerState<GrzybobranieEditPage> createState() =>
      _GrzybobranieEditPageState();
}

class _GrzybobranieEditPageState extends ConsumerState<GrzybobranieEditPage> {
  final _formKey = GlobalKey<FormState>();
  final _nazwa = TextEditingController();
  final _opis = TextEditingController();
  final _lokalizacja = TextEditingController();
  final _dataOd = TextEditingController();
  final _dataDo = TextEditingController();
  GrzybobranieStatus _status = GrzybobranieStatus.planowane;
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
    final ctrl = ref.read(grzybobraniaControllerProvider.notifier);
    await ctrl.loadDetail(widget.id!);
    final g = ctrl.selected;
    if (g != null) {
      _existingId = g.id;
      _nazwa.text = g.nazwa;
      _opis.text = g.opis ?? '';
      _lokalizacja.text = g.lokalizacja ?? '';
      _dataOd.text = g.dataOd ?? '';
      _dataDo.text = g.dataDo ?? '';
      _status = g.status ?? GrzybobranieStatus.planowane;
    }
    if (mounted) setState(() => _loading = false);
  }

  @override
  void dispose() {
    _nazwa.dispose();
    _opis.dispose();
    _lokalizacja.dispose();
    _dataOd.dispose();
    _dataDo.dispose();
    super.dispose();
  }

  Future<void> _pickDate(TextEditingController target) async {
    final now = DateTime.now();
    final initial = DateTime.tryParse(target.text) ?? now;
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(now.year - 2),
      lastDate: DateTime(now.year + 5),
    );
    if (picked != null) {
      target.text =
          '${picked.year.toString().padLeft(4, '0')}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
      setState(() {});
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final od = DateTime.tryParse(_dataOd.text);
    final do_ = DateTime.tryParse(_dataDo.text);
    if (od != null && do_ != null && do_.isBefore(od)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Data zakończenia nie może być przed datą startu'),
        ),
      );
      return;
    }

    setState(() => _saving = true);
    final item = Grzybobranie(
      id: _existingId ?? 'new',
      nazwa: _nazwa.text.trim(),
      fields: {
        'opis': _opis.text.trim(),
        'lokalizacja': _lokalizacja.text.trim(),
        'status': _status.apiValue,
        'dataOd': _dataOd.text.trim(),
        'dataDo': _dataDo.text.trim(),
      },
    );
    try {
      final saved = await ref
          .read(grzybobraniaControllerProvider.notifier)
          .save(item, isNew: widget.isNew);
      if (mounted) context.go('/grzybobrania/${saved.id}');
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
        title: Text(widget.isNew ? 'Nowe grzybobranie' : 'Edycja grzybobrania'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (widget.isNew) {
              context.go('/');
            } else {
              context.go('/grzybobrania/${widget.id}');
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
                          controller: _lokalizacja,
                          decoration:
                              const InputDecoration(labelText: 'Lokalizacja'),
                          validator: (v) => (v == null || v.trim().isEmpty)
                              ? 'Wymagane'
                              : null,
                        ),
                        const SizedBox(height: 12),
                        DropdownButtonFormField<GrzybobranieStatus>(
                          // ignore: deprecated_member_use
                          value: _status,
                          decoration:
                              const InputDecoration(labelText: 'Status'),
                          items: GrzybobranieStatus.values
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
                        TextFormField(
                          controller: _dataOd,
                          readOnly: true,
                          decoration: InputDecoration(
                            labelText: 'Data od',
                            suffixIcon: IconButton(
                              icon: const Icon(Icons.calendar_today),
                              onPressed: () => _pickDate(_dataOd),
                            ),
                          ),
                          validator: (v) =>
                              (v == null || v.isEmpty) ? 'Wymagane' : null,
                          onTap: () => _pickDate(_dataOd),
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _dataDo,
                          readOnly: true,
                          decoration: InputDecoration(
                            labelText: 'Data do',
                            suffixIcon: IconButton(
                              icon: const Icon(Icons.calendar_today),
                              onPressed: () => _pickDate(_dataDo),
                            ),
                          ),
                          validator: (v) =>
                              (v == null || v.isEmpty) ? 'Wymagane' : null,
                          onTap: () => _pickDate(_dataDo),
                        ),
                        const SizedBox(height: 24),
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
