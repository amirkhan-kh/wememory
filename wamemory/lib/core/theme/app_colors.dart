import 'package:flutter/material.dart';

/// WhatsApp-like palette. Light = owner screenshots; dark = current WA dark.
/// Call [AppColors.apply] whenever [Brightness] changes (see ThemeController).
class AppColors {
  AppColors._();

  static bool isLight = false;

  static void apply(Brightness brightness) {
    isLight = brightness == Brightness.light;
  }

  /// Subscribe the calling widget to theme changes so static getters
  /// re-evaluate on light/dark switch. Safe when no [ThemeScope] is present.
  static void bind(BuildContext context) {
    context.dependOnInheritedWidgetOfExactType<ThemeScope>();
  }

  // —— surfaces ——
  static Color get bg =>
      isLight ? const Color(0xFFFFFFFF) : const Color(0xFF0B141A);
  static Color get bgDeep =>
      isLight ? const Color(0xFFFFFFFF) : const Color(0xFF0B141A);
  static Color get surface =>
      isLight ? const Color(0xFFFFFFFF) : const Color(0xFF111B21);
  static Color get appBar =>
      isLight ? const Color(0xFFFFFFFF) : const Color(0xFF1F2C34);
  static Color get panel =>
      isLight ? const Color(0xFFF0F2F5) : const Color(0xFF202C33);
  static Color get searchField =>
      isLight ? const Color(0xFFF0F2F5) : const Color(0xFF202C33);
  static Color get navBar =>
      isLight ? const Color(0xFFFFFFFF) : const Color(0xFF1F2C34);
  static Color get divider =>
      isLight ? const Color(0xFFE9EDEF) : const Color(0xFF222D34);

  // —— brand ——
  static const Color accent = Color(0xFF00A884);
  static const Color accentBright = Color(0xFF25D366);
  static const Color accentSoft = Color(0xFF005C4B);
  static Color get brandTitle =>
      isLight ? const Color(0xFF25D366) : const Color(0xFFE9EDEF);
  static Color get navSelectedPill =>
      isLight ? const Color(0xFFD9FDD3) : const Color(0x3300A884);

  // aliases (unused mist)
  static const Color auroraTeal = Color(0xFF00A884);
  static const Color auroraViolet = Color(0xFF1F2C34);
  static const Color auroraMint = Color(0xFF00A884);
  static Color get glassFill => panel;
  static Color get glassBorder => divider;
  static Color get glassHighlight => panel;

  // —— bubbles ——
  static Color get bubbleOut =>
      isLight ? const Color(0xFFD9FDD3) : const Color(0xFF005C4B);
  static Color get bubbleIn =>
      isLight ? const Color(0xFFFFFFFF) : const Color(0xFF202C33);
  static const Color bubbleDeleted = Color(0xFF3A2A1F);

  // —— text ——
  static Color get textPrimary =>
      isLight ? const Color(0xFF111B21) : const Color(0xFFE9EDEF);
  static Color get textSecondary =>
      isLight ? const Color(0xFF667781) : const Color(0xFF8696A0);
  static const Color textTeal = Color(0xFF00A884);

  static const Color unreadBadge = Color(0xFF25D366);
  static const Color danger = Color(0xFFEA4335);
  static const Color warning = Color(0xFFF0AD4E);

  /// Fallback under doodle wallpaper asset.
  static Color get chatWallpaper =>
      isLight ? const Color(0xFFEFEAE2) : const Color(0xFF0B141A);

  static Color get iconMuted =>
      isLight ? const Color(0xFF54656F) : const Color(0xFFAEBAC1);
}

/// Rebuilds every dependent (via [AppColors.bind]) when the theme
/// controller notifies — fixes "only Settings turned light" bug.
class ThemeScope extends InheritedNotifier<Listenable> {
  const ThemeScope({
    super.key,
    required Listenable controller,
    required super.child,
  }) : super(notifier: controller);
}
