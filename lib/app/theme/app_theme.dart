import 'package:flutter/material.dart';

class AppSpacing {
  static const xs = 4.0;
  static const sm = 8.0;
  static const md = 16.0;
  static const lg = 24.0;
  static const xl = 32.0;
}

class AppRadii {
  static const sm = 8.0;
  static const md = 12.0;
}

ThemeData buildLocalVaultTheme(Brightness brightness) {
  final scheme = _localVaultColorScheme(brightness);
  final base = ThemeData(
    useMaterial3: true,
    brightness: brightness,
    colorScheme: scheme,
  );
  final textTheme = base.textTheme.copyWith(
    headlineSmall: base.textTheme.headlineSmall?.copyWith(
      fontWeight: FontWeight.w700,
      color: scheme.onSurface,
    ),
    titleLarge: base.textTheme.titleLarge?.copyWith(
      fontWeight: FontWeight.w700,
      color: scheme.onSurface,
    ),
    titleMedium: base.textTheme.titleMedium?.copyWith(
      fontWeight: FontWeight.w700,
      color: scheme.onSurface,
    ),
    bodySmall: base.textTheme.bodySmall?.copyWith(
      color: scheme.onSurfaceVariant,
    ),
  );

  return base.copyWith(
    scaffoldBackgroundColor: brightness == Brightness.light
        ? const Color(0xFFF6F8F5)
        : const Color(0xFF0F1512),
    textTheme: textTheme,
    visualDensity: VisualDensity.standard,
    appBarTheme: AppBarTheme(
      centerTitle: false,
      elevation: 0,
      scrolledUnderElevation: 0,
      backgroundColor: Colors.transparent,
      foregroundColor: scheme.onSurface,
      titleTextStyle: textTheme.titleLarge,
    ),
    cardTheme: CardThemeData(
      elevation: 0,
      color: scheme.surfaceContainerLow,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadii.sm),
        side: BorderSide(color: scheme.outlineVariant),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: scheme.surfaceContainerLow,
      border: _inputBorder(scheme.outlineVariant),
      enabledBorder: _inputBorder(scheme.outlineVariant),
      focusedBorder: _inputBorder(scheme.primary, 1.5),
      errorBorder: _inputBorder(scheme.error),
      focusedErrorBorder: _inputBorder(scheme.error, 1.5),
      floatingLabelStyle: TextStyle(color: scheme.primary),
    ),
    listTileTheme: ListTileThemeData(
      iconColor: scheme.onSurfaceVariant,
      textColor: scheme.onSurface,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadii.sm),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size(64, 48),
        backgroundColor: scheme.primary,
        foregroundColor: scheme.onPrimary,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.sm),
        ),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(64, 48),
        foregroundColor: scheme.primary,
        side: BorderSide(color: scheme.outline),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.sm),
        ),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(foregroundColor: scheme.primary),
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: scheme.tertiaryContainer,
      foregroundColor: scheme.onTertiaryContainer,
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadii.md),
      ),
    ),
    navigationBarTheme: NavigationBarThemeData(
      height: 72,
      backgroundColor: Colors.transparent,
      indicatorColor: scheme.primaryContainer,
      labelTextStyle: WidgetStateProperty.resolveWith((states) {
        final selected = states.contains(WidgetState.selected);
        return textTheme.labelMedium?.copyWith(
          color: selected ? scheme.primary : scheme.onSurfaceVariant,
          fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
        );
      }),
      iconTheme: WidgetStateProperty.resolveWith((states) {
        final selected = states.contains(WidgetState.selected);
        return IconThemeData(
          color: selected ? scheme.primary : scheme.onSurfaceVariant,
        );
      }),
    ),
    navigationRailTheme: NavigationRailThemeData(
      backgroundColor: Colors.transparent,
      indicatorColor: scheme.primaryContainer,
      selectedIconTheme: IconThemeData(color: scheme.primary),
      unselectedIconTheme: IconThemeData(color: scheme.onSurfaceVariant),
      selectedLabelTextStyle: textTheme.labelMedium?.copyWith(
        color: scheme.primary,
        fontWeight: FontWeight.w700,
      ),
      unselectedLabelTextStyle: textTheme.labelMedium?.copyWith(
        color: scheme.onSurfaceVariant,
        fontWeight: FontWeight.w600,
      ),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: scheme.surfaceContainerLow,
      selectedColor: scheme.secondaryContainer,
      checkmarkColor: scheme.onSecondaryContainer,
      side: BorderSide(color: scheme.outlineVariant),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadii.sm),
      ),
      labelStyle: TextStyle(color: scheme.onSurface),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: scheme.surface,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadii.md),
      ),
    ),
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: scheme.surface,
      surfaceTintColor: Colors.transparent,
      modalBackgroundColor: scheme.surface,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: scheme.inverseSurface,
      contentTextStyle: TextStyle(color: scheme.onInverseSurface),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadii.sm),
      ),
    ),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return scheme.primary;
        }
        return scheme.outline;
      }),
      trackColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return scheme.primaryContainer;
        }
        return scheme.surfaceContainerHighest;
      }),
    ),
    checkboxTheme: CheckboxThemeData(
      fillColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return scheme.primary;
        }
        return Colors.transparent;
      }),
      checkColor: WidgetStateProperty.all(scheme.onPrimary),
      side: BorderSide(color: scheme.outline),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.xs),
      ),
    ),
  );
}

ColorScheme _localVaultColorScheme(Brightness brightness) {
  final seed = ColorScheme.fromSeed(
    seedColor: const Color(0xFF245D4E),
    brightness: brightness,
  );
  if (brightness == Brightness.dark) {
    return seed.copyWith(
      primary: const Color(0xFF96D3C0),
      onPrimary: const Color(0xFF00382E),
      primaryContainer: const Color(0xFF154D41),
      onPrimaryContainer: const Color(0xFFD5EAE2),
      secondary: const Color(0xFFD7C79E),
      onSecondary: const Color(0xFF3B3018),
      secondaryContainer: const Color(0xFF55482F),
      onSecondaryContainer: const Color(0xFFEEE1C6),
      tertiary: const Color(0xFFE7A18A),
      onTertiary: const Color(0xFF4E1E12),
      tertiaryContainer: const Color(0xFF6B3525),
      onTertiaryContainer: const Color(0xFFFFDACE),
      surface: const Color(0xFF151C18),
      onSurface: const Color(0xFFE7EFE9),
      onSurfaceVariant: const Color(0xFFBDC9C1),
      surfaceContainerLow: const Color(0xFF1A221E),
      surfaceContainer: const Color(0xFF202A25),
      surfaceContainerHighest: const Color(0xFF2A352F),
      outline: const Color(0xFF8A978F),
      outlineVariant: const Color(0xFF3F4B44),
      error: const Color(0xFFFFB4AB),
      onError: const Color(0xFF690005),
      errorContainer: const Color(0xFF93000A),
      onErrorContainer: const Color(0xFFFFDAD6),
    );
  }
  return seed.copyWith(
    primary: const Color(0xFF245D4E),
    onPrimary: const Color(0xFFFFFFFF),
    primaryContainer: const Color(0xFFD5EAE2),
    onPrimaryContainer: const Color(0xFF07251E),
    secondary: const Color(0xFF6D6045),
    onSecondary: const Color(0xFFFFFFFF),
    secondaryContainer: const Color(0xFFEEE1C6),
    onSecondaryContainer: const Color(0xFF27200F),
    tertiary: const Color(0xFF8A4F3C),
    onTertiary: const Color(0xFFFFFFFF),
    tertiaryContainer: const Color(0xFFFFDACE),
    onTertiaryContainer: const Color(0xFF351105),
    surface: const Color(0xFFFFFFFF),
    onSurface: const Color(0xFF17201B),
    onSurfaceVariant: const Color(0xFF4E5A53),
    surfaceContainerLow: const Color(0xFFF1F4F0),
    surfaceContainer: const Color(0xFFEBEFEB),
    surfaceContainerHighest: const Color(0xFFE0E6E1),
    outline: const Color(0xFF718078),
    outlineVariant: const Color(0xFFC9D3CC),
    error: const Color(0xFFB3261E),
    onError: const Color(0xFFFFFFFF),
    errorContainer: const Color(0xFFFFDAD6),
    onErrorContainer: const Color(0xFF410002),
  );
}

OutlineInputBorder _inputBorder(Color color, [double width = 1]) {
  return OutlineInputBorder(
    borderRadius: BorderRadius.circular(AppRadii.sm),
    borderSide: BorderSide(color: color, width: width),
  );
}
