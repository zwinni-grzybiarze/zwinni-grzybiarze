import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:onlyshrooms/app_theme.dart';
import 'package:onlyshrooms/features/auth/auth_controller.dart';

class ConfirmedPage extends ConsumerStatefulWidget {
  const ConfirmedPage({
    super.key,
    this.token,
    this.error = false,
  });

  final String? token;
  final bool error;

  @override
  ConsumerState<ConfirmedPage> createState() => _ConfirmedPageState();
}

class _ConfirmedPageState extends ConsumerState<ConfirmedPage> {
  bool _confirming = false;
  bool _failed = false;
  String? _errorDetail;

  @override
  void initState() {
    super.initState();
    final rawToken = widget.token?.trim() ?? '';
    if (widget.error) {
      _failed = true;
    } else if (rawToken.isNotEmpty) {
      _confirming = true;
      _runConfirm(rawToken);
    }
  }

  Future<void> _runConfirm(String token) async {
    try {
      await ref.read(authControllerProvider.notifier).confirmEmail(token);
      if (!mounted) return;
      setState(() {
        _confirming = false;
        _failed = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _confirming = false;
        _failed = true;
        _errorDetail = e.toString().replaceFirst('Bad state: ', '');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final cream = OnlyShroomsTheme.cream;
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: _confirming
                ? Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const CircularProgressIndicator(
                        color: OnlyShroomsTheme.cream,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Potwierdzanie adresu e-mail…',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: cream.withValues(alpha: 0.9)),
                      ),
                    ],
                  )
                : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _failed
                            ? 'Potwierdzenie nieudane'
                            : 'E-mail potwierdzony',
                        textAlign: TextAlign.center,
                        style: Theme.of(context)
                            .textTheme
                            .headlineMedium
                            ?.copyWith(
                              color: cream,
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        _failed
                            ? (_errorDetail ??
                                'Link jest nieprawidłowy lub wygasł. Zarejestruj się ponownie albo poproś o pomoc.')
                            : 'Możesz się teraz zalogować adresem e-mail i hasłem.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: cream.withValues(alpha: 0.85)),
                      ),
                      const SizedBox(height: 24),
                      FilledButton(
                        onPressed: () => context.go('/login'),
                        style: FilledButton.styleFrom(
                          backgroundColor: OnlyShroomsTheme.moss,
                          foregroundColor: cream,
                        ),
                        child: const Text('Przejdź do logowania'),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}
