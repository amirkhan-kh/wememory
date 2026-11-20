import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Material themes. Widget surfaces also use [AppColors] getters synced by ThemeController.
class AppTheme {
  static ThemeData get dark => _build(Brightness.dark);
  static ThemeData get light => _build(Brightness.light);

  static ThemeData _build(Brightness brightness) {
    final isLight = brightness == Brightness.light;
    final bg = isLight ? const Color(0xFFFFFFFF) : const Color(0xFF0B141A);
    final surface = isLight ? const Color(0xFFFFFFFF) : const Color(0xFF111B21);
    final appBar = isLight ? const Color(0xFFFFFFFF) : const Color(0xFF1F2C34);
    final panel = isLight ? const Color(0xFFF0F2F5) : const Color(0xFF202C33);
    final text = isLight ? const Color(0xFF111B21) : const Color(0xFFE9EDEF);
    final secondary =
        isLight ? const Color(0xFF667781) : const Color(0xFF8696A0);
    final divider =
        isLight ? const Color(0xFFE9EDEF) : const Color(0xFF222D34);
    final navPill =
        isLight ? const Color(0xFFD9FDD3) : const Color(0x3300A884);
    const accent = Color(0xFF00A884);
    const accentBright = Color(0xFF25D366);

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      scaffoldBackgroundColor: bg,
      colorScheme: ColorScheme(
        brightness: brightness,
        primary: accent,
        onPrimary: Colors.white,
        secondary: accentBright,
        onSecondary: Colors.white,
        surface: surface,
        onSurface: text,
        error: const Color(0xFFEA4335),
        onError: Colors.white,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: appBar,
        foregroundColor: text,
        elevation: 0,
        scrolledUnderElevation: 0.4,
        centerTitle: false,
        systemOverlayStyle:
            isLight ? SystemUiOverlayStyle.dark : SystemUiOverlayStyle.light,
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: accentBright,
        foregroundColor: Colors.white,
        elevation: 3,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(16)),
        ),
      ),
      dividerColor: divider,
      listTileTheme: ListTileThemeData(
        iconColor: secondary,
        textColor: text,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: appBar,
        indicatorColor: navPill,
        elevation: 0,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return TextStyle(
            fontSize: 12,
            fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
            color: selected ? text : secondary,
          );
        }),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: panel,
        hintStyle: TextStyle(color: secondary),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(24),
          borderSide: BorderSide.none,
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      ),
    );
  }
}
