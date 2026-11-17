import 'package:flutter/material.dart';
import 'package:onlyshrooms/app_theme.dart';

/// Auth field with hint inside; dark typed text on the light Material fill.
class AuthTextField extends StatelessWidget {
  const AuthTextField({
    super.key,
    required this.controller,
    required this.label,
    this.obscureText = false,
    this.keyboardType,
    this.onSubmitted,
  });

  final TextEditingController controller;
  final String label;
  final bool obscureText;
  final TextInputType? keyboardType;
  final ValueChanged<String>? onSubmitted;

  @override
  Widget build(BuildContext context) {
    final cream = OnlyShroomsTheme.cream;
    final bark = OnlyShroomsTheme.bark;

    return TextField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      autocorrect: false,
      style: TextStyle(
        color: bark,
        fontWeight: FontWeight.w500,
        fontSize: 16,
      ),
      cursorColor: OnlyShroomsTheme.moss,
      onSubmitted: onSubmitted,
      decoration: InputDecoration(
        hintText: label,
        hintStyle: TextStyle(
          color: bark.withValues(alpha: 0.45),
          fontWeight: FontWeight.w400,
        ),
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.94),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: cream.withValues(alpha: 0.35),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
            color: OnlyShroomsTheme.moss,
            width: 1.5,
          ),
        ),
      ),
    );
  }
}
