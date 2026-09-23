import 'package:flutter/material.dart';

/// Centralized CRM palette based on restrained shades of the logo teal.
class AppColors {
  // Sampled directly from assets/logo.png.
  static const teal = Color(0xFF04A69D);
  static const tealDark = Color(0xFF026B66);
  static const tealBright = Color(0xFF71CEC8);
  static const tealSoft = Color(0xFFE3F6F4);
  static const ink = tealDark;

  static const primary = teal;
  static const primaryDark = tealDark;
  static const primaryLight = tealBright;
  static const accent = primaryLight;
  static const gold = primaryLight;
  static const success = primary;
  static const warning = primaryLight;
  static const danger = primaryDark;

  // Legacy semantic names retained for the existing component APIs.
  static const burgundy = primaryDark;
  static const amber = primaryLight;

  static const surfaceCanvas = Color(0xFFFFFFFF);
  static const surfaceCard = Color(0xFFFFFFFF);
  static const surface = Color(0xFFF5FAF9);
  static const surfaceAlt = tealSoft;
  static const surfaceMuted = Color(0xFFEDF6F5);
  static const surfaceSubtle = Color(0xFFFBFDFD);
  static const rowStripe = Color(0xFFF6FAFA);
  static const border = Color(0xFFD5E8E5);
  static const borderStrong = Color(0xFFB8D6D2);
  static const textPrimary = ink;
  static const textSecondary = Color(0xFF52716E);
  static const textMuted = Color(0xFF86A5A1);
  static const textOnPrimary = Color(0xFFFFFFFF);
  static const textOnPrimaryMuted = Color(0xB3FFFFFF);
  static const iconMuted = textMuted;
  static const shadow = Color(0x14014142);
  static const shadowSoft = Color(0x0F014142);
  static const overlayOnPrimary = Color(0x14FFFFFF);
  static const overlayOnDark = Color(0x1AFFFFFF);
  static const borderOnDark = Color(0x2EFFFFFF);
  static const transparent = Color(0x00000000);
  static const shimmerBase = Color(0xFFE4F0EF);
  static const shimmerHighlight = Color(0xFFF4F9F8);
}

ThemeData buildAppTheme() {
  final base = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.teal,
      primary: AppColors.teal,
      secondary: AppColors.primaryDark,
      tertiary: AppColors.primaryLight,
      surface: AppColors.surfaceCard,
      onPrimary: AppColors.textOnPrimary,
      onSurface: AppColors.textPrimary,
      error: AppColors.danger,
    ),
    scaffoldBackgroundColor: AppColors.surface,
    splashFactory: InkRipple.splashFactory,
  );

  return base.copyWith(
    visualDensity: VisualDensity.adaptivePlatformDensity,
    iconTheme: const IconThemeData(color: AppColors.primary, size: 22),
    textTheme: base.textTheme.copyWith(
      headlineSmall: base.textTheme.headlineSmall?.copyWith(
        fontWeight: FontWeight.w800,
        color: AppColors.textPrimary,
        letterSpacing: 0,
      ),
      titleLarge: base.textTheme.titleLarge?.copyWith(
        fontWeight: FontWeight.w700,
        color: AppColors.textPrimary,
        letterSpacing: 0,
      ),
      titleMedium: base.textTheme.titleMedium?.copyWith(
        fontWeight: FontWeight.w700,
        color: AppColors.textPrimary,
      ),
      titleSmall: base.textTheme.titleSmall?.copyWith(
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
      ),
      bodyMedium: base.textTheme.bodyMedium?.copyWith(
        color: AppColors.textPrimary,
        height: 1.4,
      ),
      bodySmall: base.textTheme.bodySmall?.copyWith(
        color: AppColors.textSecondary,
        height: 1.4,
      ),
      labelLarge: base.textTheme.labelLarge?.copyWith(
        fontWeight: FontWeight.w600,
        letterSpacing: 0.1,
      ),
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.surfaceCard,
      foregroundColor: AppColors.textPrimary,
      elevation: 0,
      scrolledUnderElevation: 1,
      surfaceTintColor: AppColors.surfaceCard,
      titleTextStyle: TextStyle(
        color: AppColors.textPrimary,
        fontSize: 18,
        fontWeight: FontWeight.w700,
      ),
    ),
    cardTheme: CardThemeData(
      color: AppColors.surfaceCard,
      elevation: 0,
      margin: EdgeInsets.zero,
      shadowColor: AppColors.shadow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: const BorderSide(color: AppColors.border),
      ),
    ),
    chipTheme: base.chipTheme.copyWith(
      backgroundColor: AppColors.surfaceAlt,
      selectedColor: AppColors.teal.withValues(alpha: 0.16),
      labelStyle: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600),
      side: BorderSide.none,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.surfaceCard,
      prefixIconColor: AppColors.primary,
      suffixIconColor: AppColors.primary,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: AppColors.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: AppColors.border),
      ),
      focusedBorder: const OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(8)),
        borderSide: BorderSide(color: AppColors.teal, width: 1.6),
      ),
      errorBorder: const OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(8)),
        borderSide: BorderSide(color: AppColors.danger),
      ),
      focusedErrorBorder: const OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(8)),
        borderSide: BorderSide(color: AppColors.danger, width: 1.6),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
      labelStyle: const TextStyle(color: AppColors.textSecondary),
      hintStyle: const TextStyle(color: AppColors.textMuted),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style:
          ElevatedButton.styleFrom(
            backgroundColor: AppColors.teal,
            foregroundColor: AppColors.textOnPrimary,
            disabledBackgroundColor: AppColors.teal.withValues(alpha: 0.4),
            disabledForegroundColor: AppColors.textOnPrimaryMuted,
            elevation: 0,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            textStyle: const TextStyle(
              fontWeight: FontWeight.w700,
              letterSpacing: 0.1,
            ),
          ).copyWith(
            overlayColor: WidgetStateProperty.all(AppColors.overlayOnPrimary),
          ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.teal,
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 13),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        side: const BorderSide(color: AppColors.border),
        textStyle: const TextStyle(fontWeight: FontWeight.w600),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(foregroundColor: AppColors.teal),
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: AppColors.teal,
      foregroundColor: AppColors.textOnPrimary,
      elevation: 2,
    ),
    listTileTheme: const ListTileThemeData(
      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      textColor: AppColors.textPrimary,
      iconColor: AppColors.primary,
    ),
    dividerTheme: const DividerThemeData(color: AppColors.border, thickness: 1),
    tabBarTheme: const TabBarThemeData(
      labelColor: AppColors.teal,
      unselectedLabelColor: AppColors.textSecondary,
      indicatorColor: AppColors.teal,
      dividerColor: AppColors.border,
    ),
    segmentedButtonTheme: SegmentedButtonThemeData(
      style: ButtonStyle(
        backgroundColor: WidgetStateProperty.resolveWith((states) {
          return states.contains(WidgetState.selected)
              ? AppColors.primary.withValues(alpha: 0.1)
              : AppColors.surfaceCard;
        }),
        foregroundColor: WidgetStateProperty.resolveWith((states) {
          return states.contains(WidgetState.selected)
              ? AppColors.primary
              : AppColors.textSecondary;
        }),
        side: WidgetStateProperty.resolveWith((states) {
          return BorderSide(
            color: states.contains(WidgetState.selected)
                ? AppColors.primary
                : AppColors.border,
          );
        }),
        shape: WidgetStateProperty.all(
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
    ),
    dataTableTheme: DataTableThemeData(
      headingRowColor: WidgetStateProperty.all(AppColors.surfaceAlt),
      dataRowColor: WidgetStateProperty.resolveWith((states) {
        return states.contains(WidgetState.selected)
            ? AppColors.primary.withValues(alpha: 0.08)
            : AppColors.surfaceCard;
      }),
      headingTextStyle: const TextStyle(
        fontWeight: FontWeight.w700,
        color: AppColors.textPrimary,
        fontSize: 12.5,
      ),
      dividerThickness: 1,
    ),
    drawerTheme: const DrawerThemeData(
      backgroundColor: AppColors.surfaceCard,
      surfaceTintColor: AppColors.surfaceCard,
    ),
    navigationRailTheme: NavigationRailThemeData(
      backgroundColor: AppColors.surfaceCard,
      selectedIconTheme: const IconThemeData(color: AppColors.teal),
      selectedLabelTextStyle: const TextStyle(
        color: AppColors.teal,
        fontWeight: FontWeight.w700,
        fontSize: 12,
      ),
      unselectedIconTheme: const IconThemeData(color: AppColors.primary),
      unselectedLabelTextStyle: const TextStyle(
        color: AppColors.textSecondary,
        fontSize: 12,
      ),
      indicatorColor: AppColors.teal.withValues(alpha: 0.14),
    ),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith(
        (states) =>
            states.contains(WidgetState.selected) ? AppColors.teal : null,
      ),
      trackColor: WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.selected)
            ? AppColors.teal.withValues(alpha: 0.4)
            : null,
      ),
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: AppColors.ink,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: AppColors.surfaceCard,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
    popupMenuTheme: PopupMenuThemeData(
      color: AppColors.surfaceCard,
      surfaceTintColor: AppColors.surfaceCard,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    ),
  );
}

/// Consistent colors for lead/deal/activity statuses across the app.
Color statusColor(String status) {
  switch (status) {
    case 'new':
      return AppColors.textSecondary;
    case 'contacted':
      return AppColors.primary;
    case 'interested':
      return AppColors.gold;
    case 'qualified':
      return AppColors.teal;
    case 'converted':
    case 'won':
    case 'active':
    case 'completed':
      return AppColors.success;
    case 'lost':
    case 'cancelled':
    case 'inactive':
      return AppColors.danger;
    case 'pending':
    case 'prospecting':
      return AppColors.textSecondary;
    case 'proposal':
      return AppColors.amber;
    case 'negotiation':
      return AppColors.burgundy;
    default:
      return AppColors.textSecondary;
  }
}

Color statusForegroundColor(String status) {
  switch (status) {
    case 'interested':
    case 'proposal':
      return AppColors.primaryDark;
    default:
      return AppColors.textOnPrimary;
  }
}

IconData iconForActivityType(String type) {
  switch (type) {
    case 'call':
      return Icons.call_outlined;
    case 'meeting':
      return Icons.groups_2_outlined;
    case 'email':
      return Icons.email_outlined;
    case 'follow_up':
      return Icons.replay_outlined;
    default:
      return Icons.notes_outlined;
  }
}

IconData iconForPriority(String priority) {
  switch (priority) {
    case 'high':
      return Icons.keyboard_double_arrow_up_rounded;
    case 'low':
      return Icons.keyboard_arrow_down_rounded;
    default:
      return Icons.remove_rounded;
  }
}
