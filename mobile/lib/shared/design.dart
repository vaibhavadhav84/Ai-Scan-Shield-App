import 'package:flutter/material.dart';

/// Layout and semantic colors used by every feature. Risk colors are never
/// sufficient on their own: the label and icon always accompany them.
abstract final class ShieldSpace {
  static const double xs = 4, sm = 8, md = 12, lg = 16, xl = 20;
  static const double xxl = 24, section = 32, spacious = 40;
}

abstract final class ShieldShape {
  static const double control = 12, panel = 20, hero = 28;
}

abstract final class ShieldPalette {
  static const brand = Color(0xff245fd6);
  static const hero = Color(0xff142e4b);
  static const heroText = Color(0xfff2f6ff);
  static const heroMuted = Color(0xffc4d4e8);
  static const canvas = Color(0xfff5f7fa);
  static const darkCanvas = Color(0xff0c1725);
  static const ink = Color(0xff142b40);
}

class RiskTone {
  const RiskTone(this.foreground, this.container, this.icon);
  final Color foreground, container;
  final IconData icon;

  static RiskTone forLevel(String level, Brightness brightness) {
    final dark = brightness == Brightness.dark;
    return switch (level) {
      'High Risk' => RiskTone(
        dark ? const Color(0xffffb2bc) : const Color(0xffaf273d),
        dark ? const Color(0xff3f202b) : const Color(0xffffedf0),
        Icons.warning_amber_rounded,
      ),
      'Suspicious' => RiskTone(
        dark ? const Color(0xffffd080) : const Color(0xff865000),
        dark ? const Color(0xff382c19) : const Color(0xfffff3dd),
        Icons.help_outline_rounded,
      ),
      _ => RiskTone(
        dark ? const Color(0xff80dfc1) : const Color(0xff006b57),
        dark ? const Color(0xff16362f) : const Color(0xffe5f5ee),
        Icons.check_circle_outline_rounded,
      ),
    };
  }

  static RiskTone of(BuildContext context, String level) =>
      forLevel(level, Theme.of(context).brightness);
}

String channelLabel(String channel) => switch (channel) {
  'sms' => 'Text message',
  'email' => 'Email',
  'url' => 'Website link',
  'voice' => 'Voice',
  'call' => 'Call details',
  _ => 'Scan',
};

IconData channelIcon(String channel) => switch (channel) {
  'sms' => Icons.chat_bubble_outline_rounded,
  'email' => Icons.mail_outline_rounded,
  'url' => Icons.link_rounded,
  'voice' => Icons.mic_none_rounded,
  'call' => Icons.call_outlined,
  _ => Icons.shield_outlined,
};

Duration motionDuration(BuildContext context) =>
    MediaQuery.disableAnimationsOf(context)
    ? Duration.zero
    : const Duration(milliseconds: 180);

ThemeData shieldTheme(Brightness brightness) {
  final dark = brightness == Brightness.dark;
  final foreground = dark ? const Color(0xffeaf1fa) : ShieldPalette.ink;
  final supporting = dark ? const Color(0xffafbed0) : const Color(0xff526477);
  final canvas = dark ? ShieldPalette.darkCanvas : ShieldPalette.canvas;
  final surface = dark ? const Color(0xff142337) : Colors.white;
  final primary = dark ? const Color(0xffabc6ff) : ShieldPalette.brand;
  final outline = dark ? const Color(0xff34465b) : const Color(0xffd8e0ea);
  final scheme =
      ColorScheme.fromSeed(
        seedColor: ShieldPalette.brand,
        brightness: brightness,
      ).copyWith(
        primary: primary,
        onPrimary: dark ? const Color(0xff09285e) : Colors.white,
        primaryContainer: dark
            ? const Color(0xff20395f)
            : const Color(0xffeaf0ff),
        onPrimaryContainer: dark
            ? const Color(0xffd6e3ff)
            : const Color(0xff174caa),
        secondary: dark ? const Color(0xff79daca) : const Color(0xff08796d),
        surface: surface,
        onSurface: foreground,
        onSurfaceVariant: supporting,
        surfaceContainerLowest: canvas,
        surfaceContainerLow: dark
            ? const Color(0xff192b40)
            : const Color(0xffedf1f7),
        surfaceContainer: dark
            ? const Color(0xff1c2e43)
            : const Color(0xffeef2f8),
        surfaceContainerHigh: dark
            ? const Color(0xff23364b)
            : const Color(0xffe8eef5),
        surfaceContainerHighest: dark
            ? const Color(0xff2c4057)
            : const Color(0xffe0e8f1),
        outline: dark ? const Color(0xff7f93ad) : const Color(0xff728397),
        outlineVariant: outline,
        error: RiskTone.forLevel('High Risk', brightness).foreground,
        errorContainer: RiskTone.forLevel('High Risk', brightness).container,
        onErrorContainer: RiskTone.forLevel('High Risk', brightness).foreground,
      );
  final base = ThemeData(useMaterial3: true, colorScheme: scheme);
  final text = base.textTheme.copyWith(
    displayMedium: TextStyle(
      fontSize: 44,
      height: 1.1,
      fontWeight: FontWeight.w700,
      letterSpacing: -1.5,
      color: foreground,
    ),
    headlineLarge: TextStyle(
      fontSize: 32,
      height: 1.18,
      fontWeight: FontWeight.w700,
      letterSpacing: -.8,
      color: foreground,
    ),
    headlineMedium: TextStyle(
      fontSize: 28,
      height: 1.22,
      fontWeight: FontWeight.w700,
      letterSpacing: -.6,
      color: foreground,
    ),
    headlineSmall: TextStyle(
      fontSize: 24,
      height: 1.25,
      fontWeight: FontWeight.w700,
      letterSpacing: -.4,
      color: foreground,
    ),
    titleLarge: TextStyle(
      fontSize: 20,
      height: 1.3,
      fontWeight: FontWeight.w700,
      letterSpacing: -.3,
      color: foreground,
    ),
    titleMedium: TextStyle(
      fontSize: 17,
      height: 1.3,
      fontWeight: FontWeight.w600,
      color: foreground,
    ),
    titleSmall: TextStyle(
      fontSize: 15,
      height: 1.35,
      fontWeight: FontWeight.w600,
      color: foreground,
    ),
    bodyLarge: TextStyle(fontSize: 16, height: 1.5, color: foreground),
    bodyMedium: TextStyle(fontSize: 14, height: 1.5, color: supporting),
    bodySmall: TextStyle(fontSize: 13, height: 1.4, color: supporting),
    labelLarge: TextStyle(
      fontSize: 15,
      height: 1.3,
      fontWeight: FontWeight.w600,
      color: foreground,
    ),
    labelMedium: TextStyle(
      fontSize: 13,
      height: 1.35,
      fontWeight: FontWeight.w600,
      color: supporting,
    ),
    labelSmall: TextStyle(
      fontSize: 12,
      height: 1.3,
      fontWeight: FontWeight.w600,
      color: supporting,
    ),
  );
  final shape = RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(ShieldShape.control),
  );
  return base.copyWith(
    scaffoldBackgroundColor: canvas,
    textTheme: text,
    appBarTheme: AppBarTheme(
      backgroundColor: canvas,
      foregroundColor: foreground,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      titleTextStyle: text.titleLarge,
      centerTitle: false,
    ),
    dividerTheme: DividerThemeData(color: outline, thickness: 1, space: 1),
    cardTheme: CardThemeData(
      color: surface,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(ShieldShape.panel),
        side: BorderSide(color: outline),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: surface,
      alignLabelWithHint: true,
      contentPadding: const EdgeInsets.all(ShieldSpace.lg),
      labelStyle: text.bodyLarge?.copyWith(color: supporting),
      hintStyle: text.bodyLarge?.copyWith(color: supporting),
      helperMaxLines: 4,
      errorMaxLines: 4,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(ShieldShape.control),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(ShieldShape.control),
        borderSide: BorderSide(color: outline),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(ShieldShape.control),
        borderSide: BorderSide(color: primary, width: 2),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size(48, 52),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
        shape: shape,
        textStyle: text.labelLarge,
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(48, 48),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
        shape: shape,
        side: BorderSide(color: outline),
        textStyle: text.labelLarge,
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        minimumSize: const Size(48, 48),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        shape: shape,
        textStyle: text.labelLarge,
      ),
    ),
    iconButtonTheme: IconButtonThemeData(
      style: IconButton.styleFrom(
        minimumSize: const Size(48, 48),
        foregroundColor: foreground,
      ),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: surface,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      indicatorColor: scheme.primaryContainer,
      labelTextStyle: WidgetStateProperty.resolveWith(
        (states) => text.labelSmall!.copyWith(
          color: states.contains(WidgetState.selected) ? primary : supporting,
        ),
      ),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: surface,
      selectedColor: scheme.primaryContainer,
      side: BorderSide(color: outline),
      labelStyle: text.labelMedium,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
    listTileTheme: ListTileThemeData(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      iconColor: primary,
      titleTextStyle: text.titleSmall,
      subtitleTextStyle: text.bodyMedium,
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
    ),
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: surface,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: dark ? const Color(0xffdce8f5) : ShieldPalette.ink,
      contentTextStyle: TextStyle(
        color: dark ? ShieldPalette.ink : Colors.white,
      ),
    ),
    progressIndicatorTheme: ProgressIndicatorThemeData(
      color: primary,
      linearTrackColor: scheme.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(20),
    ),
    expansionTileTheme: ExpansionTileThemeData(
      tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      shape: const Border(),
      collapsedShape: const Border(),
      textColor: foreground,
      collapsedTextColor: foreground,
    ),
  );
}
