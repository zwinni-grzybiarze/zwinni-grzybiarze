import 'package:flutter/material.dart';
import 'package:onlyshrooms/app_theme.dart';
import 'package:onlyshrooms/features/auth/password_rules.dart';

class PasswordChecklist extends StatelessWidget {
  const PasswordChecklist({
    super.key,
    required this.password,
    this.confirm,
  });

  final String password;
  final String? confirm;

  @override
  Widget build(BuildContext context) {
    if (password.isEmpty && (confirm == null || confirm!.isEmpty)) {
      return const SizedBox.shrink();
    }

    final cream = OnlyShroomsTheme.cream;
    final checks = PasswordRules.checklist(password, confirm: confirm);

    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final check in checks)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                children: [
                  Icon(
                    check.ok ? Icons.check_circle : Icons.cancel_outlined,
                    size: 16,
                    color: check.ok
                        ? const Color(0xFF95D5B2)
                        : Colors.orange.shade200,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      check.label,
                      style: TextStyle(
                        color: cream.withValues(alpha: check.ok ? 0.85 : 0.95),
                        fontSize: 13,
                        fontWeight:
                            check.ok ? FontWeight.w400 : FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
