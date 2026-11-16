import 'package:flutter/material.dart';

class OnlyShroomsTheme {
  static const forest = Color(0xFF1B4332);
  static const moss = Color(0xFF2D6A4F);
  static const leaf = Color(0xFF40916C);
  static const cream = Color(0xFFF0EAD2);
  static const bark = Color(0xFF081C15);
  static const inactiveFilterBackground = Color(0xFFF4D8B8);
  static const detailBarBackground = Color(0x662D6A4F);
  static const detailPanelBackground = Color(0xEBFFFFFF);

  static ThemeData light() {
    final base = ColorScheme.fromSeed(
      seedColor: moss,
      brightness: Brightness.light,
      primary: moss,
      secondary: leaf,
      surface: cream,
    );
    return ThemeData(
      colorScheme: base,
      useMaterial3: true,
      scaffoldBackgroundColor: Colors.transparent,
      appBarTheme: const AppBarTheme(
        backgroundColor: forest,
        foregroundColor: Colors.white,
        centerTitle: false,
        iconTheme: IconThemeData(color: Colors.white),
        actionsIconTheme: IconThemeData(color: Colors.white),
      ),
      tabBarTheme: const TabBarThemeData(
        labelColor: Colors.white,
        unselectedLabelColor: Color(0xCCFFFFFF),
        indicatorColor: cream,
        indicatorSize: TabBarIndicatorSize.tab,
        dividerColor: Colors.transparent,
        overlayColor: WidgetStatePropertyAll(Color(0x22FFFFFF)),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: moss,
        foregroundColor: Colors.white,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: forest,
        indicatorColor: moss,
        overlayColor: const WidgetStatePropertyAll(Color(0x22FFFFFF)),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return TextStyle(
            color: selected ? cream : cream.withValues(alpha: 0.75),
            fontSize: 12,
            fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return IconThemeData(
            color: selected ? cream : cream.withValues(alpha: 0.75),
          );
        }),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.92),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        labelStyle: const TextStyle(
          color: bark,
          fontWeight: FontWeight.w600,
        ),
        floatingLabelStyle: TextStyle(
          color: moss.withValues(alpha: 0.95),
          fontWeight: FontWeight.w600,
        ),
      ),
      cardTheme: CardThemeData(
        color: Colors.white.withValues(alpha: 0.92),
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: moss.withValues(alpha: 0.15)),
        ),
      ),
    );
  }
}
