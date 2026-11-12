import 'package:flutter/material.dart';

/// Colours shared by the PDF and EPUB views, resolved once from the theme
/// mode so both readers look the same.
@immutable
class ViewerStyle {
  const ViewerStyle({required this.isDark, Color? accentColor})
      : _accentColor = accentColor;

  /// Resolves the style from [themeMode], falling back to the ambient
  /// [Theme] brightness when [themeMode] is null or [ThemeMode.system].
  factory ViewerStyle.of(
    BuildContext context, {
    ThemeMode? themeMode,
    Color? accentColor,
  }) {
    final isDark = switch (themeMode) {
      ThemeMode.dark => true,
      ThemeMode.light => false,
      _ => Theme.of(context).brightness == Brightness.dark,
    };
    return ViewerStyle(isDark: isDark, accentColor: accentColor);
  }

  final bool isDark;
  final Color? _accentColor;

  Color get backgroundColor => isDark ? Colors.grey[900]! : Colors.white;
  Color get surfaceColor => isDark ? Colors.grey[850]! : Colors.grey[100]!;
  Color get borderColor => isDark ? Colors.grey[800]! : Colors.grey[300]!;
  Color get textColor => isDark ? Colors.grey[100]! : Colors.grey[900]!;
  Color get secondaryTextColor =>
      isDark ? Colors.grey[400]! : Colors.grey[600]!;
  Color get accentColor =>
      _accentColor ??
      (isDark ? const Color(0xFF0A84FF) : const Color(0xFF007AFF));

  /// The canvas behind the pages, darker than the page so page edges read.
  Color get canvasColor => isDark ? Colors.black : const Color(0xFFE5E5EA);

  /// The colour of a page (PDF thumbnail background, EPUB reading surface).
  Color get pageColor => isDark ? const Color(0xFF1C1C1E) : Colors.white;
}
