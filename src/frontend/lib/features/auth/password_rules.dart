class PasswordRuleCheck {
  const PasswordRuleCheck({required this.label, required this.ok});

  final String label;
  final bool ok;
}

class PasswordRules {
  static const minLength = 10;
  static const maxLength = 128;

  static const requirementsMessage =
      'Hasło musi mieć od 10 do 128 znaków, jedną wielką literę, jedną małą literę, cyfrę i znak specjalny.';

  static const hint = 'Hasło';

  static bool meetsLength(String password) =>
      password.length >= minLength && password.length <= maxLength;
  static bool hasUppercase(String password) => RegExp(r'[A-Z]').hasMatch(password);
  static bool hasLowercase(String password) => RegExp(r'[a-z]').hasMatch(password);
  static bool hasDigit(String password) => RegExp(r'[0-9]').hasMatch(password);
  static bool hasSpecial(String password) =>
      RegExp(r'[^A-Za-z0-9]').hasMatch(password);
  static bool matchesConfirm(String password, String confirm) =>
      confirm.isNotEmpty && password == confirm;

  static bool isStrong(String password) =>
      meetsLength(password) &&
      hasUppercase(password) &&
      hasLowercase(password) &&
      hasDigit(password) &&
      hasSpecial(password);

  static List<PasswordRuleCheck> checklist(
    String password, {
    String? confirm,
  }) {
    final items = <PasswordRuleCheck>[
      PasswordRuleCheck(
        label: password.length > maxLength
            ? 'Maksymalnie $maxLength znaków'
            : 'Co najmniej $minLength znaków',
        ok: meetsLength(password),
      ),
      PasswordRuleCheck(
        label: 'Wielka litera (A–Z)',
        ok: hasUppercase(password),
      ),
      PasswordRuleCheck(
        label: 'Mała litera (a–z)',
        ok: hasLowercase(password),
      ),
      PasswordRuleCheck(
        label: 'Cyfra (0–9)',
        ok: hasDigit(password),
      ),
      PasswordRuleCheck(
        label: 'Znak specjalny (!@#…)',
        ok: hasSpecial(password),
      ),
    ];
    if (confirm != null) {
      items.add(
        PasswordRuleCheck(
          label: 'Hasła są takie same',
          ok: matchesConfirm(password, confirm),
        ),
      );
    }
    return items;
  }

  /// Returns an error message, or `null` if the password is valid.
  static String? validate(String password, {String? confirm}) {
    if (!isStrong(password)) return requirementsMessage;
    if (confirm != null && password != confirm) {
      return 'Hasła nie są takie same.';
    }
    return null;
  }
}
