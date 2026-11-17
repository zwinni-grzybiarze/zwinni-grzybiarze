import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:onlyshrooms/app_theme.dart';
import 'package:onlyshrooms/features/auth/auth_controller.dart';
import 'package:onlyshrooms/features/auth/auth_text_field.dart';
import 'package:onlyshrooms/features/auth/password_checklist.dart';
import 'package:onlyshrooms/features/auth/password_rules.dart';

class ResetPasswordPage extends ConsumerStatefulWidget {
  const ResetPasswordPage({super.key, required this.token});

  final String? token;

  @override
  ConsumerState<ResetPasswordPage> createState() => _ResetPasswordPageState();
}

class _ResetPasswordPageState extends ConsumerState<ResetPasswordPage> {
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  String? _error;
  String? _success;

  @override
  void initState() {
    super.initState();
    _password.addListener(_onChanged);
    _confirm.addListener(_onChanged);
  }

  @override
  void dispose() {
    _password.removeListener(_onChanged);
    _confirm.removeListener(_onChanged);
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  void _onChanged() => setState(() {});

  Future<void> _submit() async {
    setState(() {
      _error = null;
      _success = null;
    });
    final token = widget.token?.trim() ?? '';
    if (token.isEmpty) {
      setState(() => _error = 'Brak tokenu resetu w linku.');
      return;
    }
    final localError = PasswordRules.validate(
      _password.text,
      confirm: _confirm.text,
    );
    if (localError != null) {
      setState(() => _error = localError);
      return;
    }

    try {
      await ref.read(authControllerProvider.notifier).resetPassword(
            token: token,
            newPassword: _password.text,
          );
      setState(() {
        _success = 'Hasło zmienione. Możesz się zalogować.';
      });
    } catch (e) {
      setState(() {
        _error = e.toString().replaceFirst('Bad state: ', '');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authControllerProvider);
    final cream = OnlyShroomsTheme.cream;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Nowe hasło',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          color: cream,
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  const SizedBox(height: 24),
                  AuthTextField(
                    controller: _password,
                    label: PasswordRules.hint,
                    obscureText: true,
                  ),
                  const SizedBox(height: 16),
                  AuthTextField(
                    controller: _confirm,
                    label: 'Powtórz hasło',
                    obscureText: true,
                    onSubmitted: (_) => _submit(),
                  ),
                  PasswordChecklist(
                    password: _password.text,
                    confirm: _confirm.text,
                  ),
                  const SizedBox(height: 16),
                  if (_error != null)
                    Text(
                      _error!,
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.orange.shade200),
                    ),
                  if (_success != null)
                    Text(
                      _success!,
                      textAlign: TextAlign.center,
                      style: TextStyle(color: cream),
                    ),
                  const SizedBox(height: 12),
                  FilledButton(
                    onPressed: auth.busy || _success != null ? null : _submit,
                    style: FilledButton.styleFrom(
                      backgroundColor: OnlyShroomsTheme.moss,
                      foregroundColor: cream,
                    ),
                    child: const Padding(
                      padding: EdgeInsets.symmetric(vertical: 14),
                      child: Text('Zapisz hasło'),
                    ),
                  ),
                  TextButton(
                    onPressed: () => context.go('/login'),
                    child: Text(
                      'Wróć do logowania',
                      style: TextStyle(color: cream.withValues(alpha: 0.85)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
