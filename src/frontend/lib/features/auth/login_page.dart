import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:onlyshrooms/app_theme.dart';
import 'package:onlyshrooms/core/responsive.dart';
import 'package:onlyshrooms/features/auth/auth_controller.dart';
import 'package:onlyshrooms/features/auth/auth_text_field.dart';
import 'package:onlyshrooms/features/auth/password_checklist.dart';
import 'package:onlyshrooms/features/auth/password_rules.dart';

enum AuthPanel { login, register, forgot }

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key, this.initialPanel = AuthPanel.login});

  final AuthPanel initialPanel;

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  late AuthPanel _panel = widget.initialPanel;

  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  final _imie = TextEditingController();
  final _nazwisko = TextEditingController();

  String? _localError;
  String? _localSuccess;

  @override
  void initState() {
    super.initState();
    for (final c in [_email, _password, _confirm, _imie, _nazwisko]) {
      c.addListener(_onFieldChanged);
    }
  }

  @override
  void didUpdateWidget(covariant LoginPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialPanel != oldWidget.initialPanel &&
        widget.initialPanel != _panel) {
      _switchPanel(widget.initialPanel);
    }
  }

  @override
  void dispose() {
    for (final c in [_email, _password, _confirm, _imie, _nazwisko]) {
      c.removeListener(_onFieldChanged);
      c.dispose();
    }
    super.dispose();
  }

  void _onFieldChanged() => setState(() {});

  void _switchPanel(AuthPanel panel) {
    setState(() {
      _panel = panel;
      _localError = null;
      _localSuccess = null;
      _password.clear();
      _confirm.clear();
    });
  }

  Future<void> _loginEmail() async {
    setState(() {
      _localError = null;
      _localSuccess = null;
    });
    try {
      await ref.read(authControllerProvider.notifier).loginWithEmail(
            email: _email.text.trim(),
            password: _password.text,
          );
      if (mounted) context.go('/');
    } catch (e) {
      setState(() {
        _localError = e.toString().replaceFirst('Bad state: ', '');
      });
    }
  }

  Future<void> _register() async {
    setState(() {
      _localError = null;
      _localSuccess = null;
    });
    final localError = PasswordRules.validate(
      _password.text,
      confirm: _confirm.text,
    );
    if (localError != null) {
      setState(() => _localError = localError);
      return;
    }
    try {
      await ref.read(authControllerProvider.notifier).registerWithEmail(
            email: _email.text.trim(),
            password: _password.text,
            imie: _imie.text.trim(),
            nazwisko: _nazwisko.text.trim(),
          );
      setState(() {
        _localSuccess =
            'Konto utworzone. Sprawdź e-mail i kliknij link potwierdzający, a potem zaloguj się.';
        _password.clear();
        _confirm.clear();
      });
    } catch (e) {
      setState(() {
        _localError = e.toString().replaceFirst('Bad state: ', '');
      });
    }
  }

  Future<void> _forgot() async {
    setState(() {
      _localError = null;
      _localSuccess = null;
    });
    try {
      await ref
          .read(authControllerProvider.notifier)
          .requestPasswordReset(_email.text.trim());
      setState(() {
        _localSuccess =
            'Jeśli konto istnieje, wysłaliśmy instrukcję resetu hasła na e-mail.';
      });
    } catch (e) {
      setState(() {
        _localError = e.toString().replaceFirst('Bad state: ', '');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authControllerProvider);
    final compact = context.isCompact;
    final cream = OnlyShroomsTheme.cream;

    // Keep height + fade in sync so the centered column eases instead of jumping.
    const swapDuration = Duration(milliseconds: 360);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(
                horizontal: compact ? 20 : 24,
                vertical: compact ? 16 : 24,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'OnlyShrooms',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.displaySmall?.copyWith(
                          color: cream,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.5,
                          fontSize: compact ? 36 : null,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Grzybobrania z Twoją ekipą',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: cream.withValues(alpha: 0.8),
                        ),
                  ),
                  const SizedBox(height: 28),
                  AnimatedSize(
                    duration: swapDuration,
                    curve: Curves.easeInOutCubic,
                    alignment: Alignment.topCenter,
                    child: AnimatedSwitcher(
                      duration: swapDuration,
                      switchInCurve: Curves.easeOutCubic,
                      switchOutCurve: Curves.easeInCubic,
                      layoutBuilder: (currentChild, previousChildren) {
                        return Stack(
                          alignment: Alignment.topCenter,
                          children: [
                            ...previousChildren,
                            ?currentChild,
                          ],
                        );
                      },
                      transitionBuilder: (child, animation) {
                        final offset = Tween<Offset>(
                          begin: const Offset(0, 0.04),
                          end: Offset.zero,
                        ).animate(animation);
                        return FadeTransition(
                          opacity: animation,
                          child:
                              SlideTransition(position: offset, child: child),
                        );
                      },
                      child: KeyedSubtree(
                        key: ValueKey(_panel),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _buildPanel(auth.busy),
                            if (_panel != AuthPanel.forgot) ...[
                              const SizedBox(height: 24),
                              Row(
                                children: [
                                  Expanded(
                                    child: Divider(
                                      color: cream.withValues(alpha: 0.4),
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                    ),
                                    child: Text(
                                      'lub',
                                      style: TextStyle(
                                        color: cream.withValues(alpha: 0.7),
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    child: Divider(
                                      color: cream.withValues(alpha: 0.4),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 24),
                              FilledButton.icon(
                                onPressed: auth.busy
                                    ? null
                                    : () async {
                                        await ref
                                            .read(
                                              authControllerProvider.notifier,
                                            )
                                            .signInWithGoogle();
                                      },
                                icon: const Icon(
                                  Icons.g_mobiledata_rounded,
                                  size: 28,
                                ),
                                label: const Padding(
                                  padding: EdgeInsets.symmetric(vertical: 14),
                                  child: Text('Zaloguj przez Google'),
                                ),
                                style: FilledButton.styleFrom(
                                  backgroundColor: Colors.white,
                                  foregroundColor: OnlyShroomsTheme.bark,
                                ),
                              ),
                            ],
                            if (auth.busy) ...[
                              const SizedBox(height: 16),
                              const Center(
                                child: CircularProgressIndicator(
                                  color: OnlyShroomsTheme.cream,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
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

  Widget _buildPanel(bool busy) {
    final cream = OnlyShroomsTheme.cream;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          switch (_panel) {
            AuthPanel.login => 'Logowanie',
            AuthPanel.register => 'Rejestracja',
            AuthPanel.forgot => 'Reset hasła',
          },
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: cream,
                fontWeight: FontWeight.w700,
              ),
        ),
        const SizedBox(height: 20),
        if (_panel == AuthPanel.register) ...[
          AuthTextField(controller: _imie, label: 'Imię'),
          const SizedBox(height: 16),
          AuthTextField(controller: _nazwisko, label: 'Nazwisko'),
          const SizedBox(height: 16),
        ],
        AuthTextField(
          controller: _email,
          label: 'E-mail',
          keyboardType: TextInputType.emailAddress,
        ),
        if (_panel != AuthPanel.forgot) ...[
          const SizedBox(height: 16),
          AuthTextField(
            controller: _password,
            label: _panel == AuthPanel.register ? PasswordRules.hint : 'Hasło',
            obscureText: true,
            onSubmitted: _panel == AuthPanel.login ? (_) => _loginEmail() : null,
          ),
        ],
        if (_panel == AuthPanel.register) ...[
          const SizedBox(height: 16),
          AuthTextField(
            controller: _confirm,
            label: 'Powtórz hasło',
            obscureText: true,
          ),
          PasswordChecklist(
            password: _password.text,
            confirm: _confirm.text,
          ),
        ],
        if (_panel == AuthPanel.login)
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: busy ? null : () => _switchPanel(AuthPanel.forgot),
              child: Text(
                'Nie pamiętam hasła',
                style: TextStyle(color: cream.withValues(alpha: 0.85)),
              ),
            ),
          )
        else
          const SizedBox(height: 12),
        if (_panel == AuthPanel.forgot)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Text(
              'Podaj e-mail powiązany z kontem.',
              textAlign: TextAlign.center,
              style: TextStyle(color: cream.withValues(alpha: 0.85)),
            ),
          ),
        if (_localError != null) ...[
          Text(
            _localError!,
            style: TextStyle(color: Colors.orange.shade200),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
        ],
        if (_localSuccess != null) ...[
          Text(
            _localSuccess!,
            style: TextStyle(color: cream),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
        ],
        FilledButton(
          onPressed: busy
              ? null
              : switch (_panel) {
                  AuthPanel.login => _loginEmail,
                  AuthPanel.register => _register,
                  AuthPanel.forgot => _forgot,
                },
          style: FilledButton.styleFrom(
            backgroundColor: OnlyShroomsTheme.moss,
            foregroundColor: cream,
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 14),
            child: Text(
              switch (_panel) {
                AuthPanel.login => 'Zaloguj e-mailem',
                AuthPanel.register => 'Zarejestruj',
                AuthPanel.forgot => 'Wyślij link',
              },
            ),
          ),
        ),
        const SizedBox(height: 8),
        if (_panel == AuthPanel.login)
          OutlinedButton(
            onPressed: busy ? null : () => _switchPanel(AuthPanel.register),
            style: OutlinedButton.styleFrom(
              foregroundColor: cream,
              side: BorderSide(color: cream),
            ),
            child: const Padding(
              padding: EdgeInsets.symmetric(vertical: 14),
              child: Text('Załóż konto e-mail'),
            ),
          )
        else
          TextButton(
            onPressed: busy ? null : () => _switchPanel(AuthPanel.login),
            child: Text(
              'Wróć do logowania',
              style: TextStyle(color: cream.withValues(alpha: 0.85)),
            ),
          ),
      ],
    );
  }
}
