import 'package:flutter/material.dart';
import 'package:sunhabit/core/constants/app_constants.dart';
import 'package:sunhabit/core/theme/app_colors.dart';
import 'package:sunhabit/core/theme/app_text_styles.dart';

class AppTheme {
  static ThemeData get _base => ThemeData(useMaterial3: true);

  static TextTheme _textTheme(Brightness brightness) {
    final onSurface = brightness == Brightness.dark
        ? AppColors.textPrimary
        : const Color(0xFF151914);
    final onSurfaceVariant = brightness == Brightness.dark
        ? AppColors.textSecondary
        : const Color(0xFF596356);
    final muted = brightness == Brightness.dark
        ? AppColors.textMuted
        : const Color(0xFF768073);

    return TextTheme(
      displayLarge: AppTextStyles.display.copyWith(color: onSurface),
      displayMedium: AppTextStyles.percentage.copyWith(color: onSurface),
      displaySmall: AppTextStyles.statNumber.copyWith(color: onSurface),
      headlineSmall: AppTextStyles.greeting.copyWith(color: onSurface),
      titleLarge: AppTextStyles.sectionTitle.copyWith(color: onSurface),
      titleMedium: AppTextStyles.cardTitle.copyWith(color: onSurface),
      titleSmall: AppTextStyles.cardSubtitle.copyWith(color: onSurfaceVariant),
      bodyLarge: AppTextStyles.subtitle.copyWith(color: onSurfaceVariant),
      bodyMedium: AppTextStyles.cardSubtitle.copyWith(color: onSurfaceVariant),
      bodySmall: AppTextStyles.statLabel.copyWith(color: muted),
      labelLarge: AppTextStyles.button.copyWith(color: onSurface),
      labelMedium: AppTextStyles.statLabel.copyWith(color: onSurfaceVariant),
      labelSmall: AppTextStyles.label.copyWith(color: muted),
    );
  }

  static ThemeData get lightTheme {
    const scheme = ColorScheme.light(
      primary: AppColors.neonGreenDark,
      onPrimary: Colors.white,
      secondary: AppColors.purple,
      onSecondary: Colors.white,
      tertiary: AppColors.gold,
      onTertiary: Colors.black,
      surface: AppColors.surfaceLight,
      onSurface: Color(0xFF151914),
      outline: AppColors.borderLight,
      error: AppColors.danger,
    );

    return _base.copyWith(
      brightness: Brightness.light,
      colorScheme: scheme,
      scaffoldBackgroundColor: AppColors.backgroundLight,
      canvasColor: AppColors.backgroundLight,
      textTheme: _textTheme(Brightness.light),
      dividerColor: AppColors.borderLight,
      cardTheme: CardThemeData(
        color: AppColors.surfaceLight,
        elevation: 2,
        shadowColor: Colors.black.withValues(alpha: 0.12),
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppConstants.cardRadius),
          side: const BorderSide(color: AppColors.borderLight),
        ),
      ),
      appBarTheme: const AppBarTheme(
        elevation: 0,
        centerTitle: false,
        backgroundColor: AppColors.backgroundLight,
        foregroundColor: Color(0xFF151914),
        surfaceTintColor: Colors.transparent,
      ),
      bottomAppBarTheme: const BottomAppBarThemeData(
        color: AppColors.surfaceLight,
        elevation: 12,
        surfaceTintColor: Colors.transparent,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AppColors.surfaceLight,
        indicatorColor: AppColors.neonGreenSoft.withValues(alpha: 0.18),
        iconTheme: const WidgetStatePropertyAll(
          IconThemeData(color: Color(0xFF596356)),
        ),
        labelTextStyle: WidgetStatePropertyAll(
          AppTextStyles.label.copyWith(color: const Color(0xFF596356)),
        ),
      ),
      iconTheme: const IconThemeData(color: Color(0xFF596356)),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppColors.neonGreenDark,
        foregroundColor: Colors.white,
        elevation: 8,
        shape: CircleBorder(),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          minimumSize: const Size(0, AppConstants.controlHeight),
          backgroundColor: AppColors.neonGreenDark,
          foregroundColor: Colors.white,
          elevation: 5,
          shadowColor: AppColors.neonGlowMedium,
          textStyle: AppTextStyles.button,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppConstants.cardRadius),
          ),
        ),
      ),
      inputDecorationTheme: _inputTheme(
        fillColor: AppColors.surfaceLight,
        borderColor: AppColors.borderLight,
        textColor: const Color(0xFF596356),
      ),
      listTileTheme: const ListTileThemeData(
        iconColor: Color(0xFF596356),
        textColor: Color(0xFF151914),
        contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.neonGreenDark,
        linearTrackColor: AppColors.borderLight,
        circularTrackColor: AppColors.borderLight,
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.borderLight,
        thickness: 1,
        space: 1,
      ),
      snackBarTheme: const SnackBarThemeData(
        backgroundColor: Color(0xFF151914),
        contentTextStyle: TextStyle(color: Colors.white),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  static ThemeData get darkTheme {
    const scheme = ColorScheme.dark(
      primary: AppColors.neonGreen,
      onPrimary: Color(0xFF101600),
      secondary: AppColors.purple,
      onSecondary: Colors.white,
      tertiary: AppColors.gold,
      onTertiary: Colors.black,
      surface: AppColors.surfaceDark,
      onSurface: AppColors.textPrimary,
      onSurfaceVariant: AppColors.textSecondary,
      outline: AppColors.borderDark,
      error: AppColors.danger,
    );

    return _base.copyWith(
      brightness: Brightness.dark,
      colorScheme: scheme,
      scaffoldBackgroundColor: AppColors.backgroundDark,
      canvasColor: AppColors.backgroundDark,
      textTheme: _textTheme(Brightness.dark),
      dividerColor: AppColors.borderDark,
      splashColor: AppColors.neonGlowSoft,
      highlightColor: AppColors.neonGlowSoft,
      cardTheme: CardThemeData(
        color: AppColors.surfaceElevated,
        elevation: 8,
        shadowColor: AppColors.blackShadow,
        margin: EdgeInsets.zero,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppConstants.cardRadius),
          side: const BorderSide(color: AppColors.borderDark),
        ),
      ),
      appBarTheme: const AppBarTheme(
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        backgroundColor: AppColors.backgroundDark,
        foregroundColor: AppColors.textPrimary,
        surfaceTintColor: Colors.transparent,
        iconTheme: IconThemeData(color: AppColors.textPrimary),
      ),
      bottomAppBarTheme: const BottomAppBarThemeData(
        color: AppColors.surfaceDark,
        elevation: 18,
        shadowColor: AppColors.neonGlowSoft,
        surfaceTintColor: Colors.transparent,
        padding: EdgeInsets.zero,
      ),
      navigationBarTheme: NavigationBarThemeData(
        height: 68,
        backgroundColor: AppColors.surfaceDark,
        indicatorColor: AppColors.neonGlowSoft,
        surfaceTintColor: Colors.transparent,
        shadowColor: AppColors.neonGlowSoft,
        elevation: 16,
        iconTheme: WidgetStateProperty.resolveWith((states) {
          return IconThemeData(
            color: states.contains(WidgetState.selected)
                ? AppColors.neonGreen
                : AppColors.textSecondary,
          );
        }),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          return AppTextStyles.label.copyWith(
            color: states.contains(WidgetState.selected)
                ? AppColors.neonGreen
                : AppColors.textSecondary,
          );
        }),
      ),
      iconTheme: const IconThemeData(color: AppColors.textSecondary),
      iconButtonTheme: IconButtonThemeData(
        style: ButtonStyle(
          foregroundColor: const WidgetStatePropertyAll(AppColors.textPrimary),
          overlayColor: const WidgetStatePropertyAll(AppColors.neonGlowSoft),
          shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppConstants.cardRadius),
            ),
          ),
        ),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppColors.neonGreen,
        foregroundColor: Color(0xFF101600),
        elevation: 12,
        focusElevation: 16,
        hoverElevation: 16,
        shape: CircleBorder(),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          minimumSize: const Size(0, AppConstants.controlHeight),
          backgroundColor: AppColors.neonGreen,
          foregroundColor: const Color(0xFF101600),
          disabledBackgroundColor: AppColors.surfaceHighest,
          disabledForegroundColor: AppColors.textMuted,
          elevation: 10,
          shadowColor: AppColors.neonGlowStrong,
          textStyle: AppTextStyles.button,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppConstants.cardRadius),
            side: const BorderSide(color: AppColors.neonGreenBright),
          ),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(0, AppConstants.controlHeight),
          backgroundColor: AppColors.neonGreen,
          foregroundColor: const Color(0xFF101600),
          textStyle: AppTextStyles.button,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppConstants.cardRadius),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(0, AppConstants.controlHeight),
          foregroundColor: AppColors.neonGreen,
          side: const BorderSide(color: AppColors.neonGreen),
          textStyle: AppTextStyles.button,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppConstants.cardRadius),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.neonGreen,
          textStyle: AppTextStyles.button,
        ),
      ),
      inputDecorationTheme: _inputTheme(
        fillColor: AppColors.surfaceElevated,
        borderColor: AppColors.borderDark,
        textColor: AppColors.textSecondary,
      ),
      listTileTheme: const ListTileThemeData(
        iconColor: AppColors.neonGreen,
        textColor: AppColors.textPrimary,
        contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 4),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(
            Radius.circular(AppConstants.cardRadius),
          ),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.surfaceElevated,
        selectedColor: AppColors.neonGlowSoft,
        disabledColor: AppColors.surfaceDark,
        labelStyle: AppTextStyles.statLabel.copyWith(
          color: AppColors.textSecondary,
        ),
        secondaryLabelStyle: AppTextStyles.statLabel.copyWith(
          color: AppColors.neonGreen,
        ),
        side: const BorderSide(color: AppColors.borderDark),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppConstants.cardRadius),
        ),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.neonGreen,
        linearTrackColor: AppColors.surfaceHighest,
        circularTrackColor: AppColors.surfaceHighest,
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.borderDark,
        thickness: 1,
        space: 1,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.surfaceElevated,
        surfaceTintColor: Colors.transparent,
        elevation: 20,
        shadowColor: AppColors.neonGlowSoft,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppConstants.largeRadius),
          side: const BorderSide(color: AppColors.borderDark),
        ),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppColors.surfaceElevated,
        modalBackgroundColor: AppColors.surfaceElevated,
        surfaceTintColor: Colors.transparent,
        showDragHandle: true,
        dragHandleColor: AppColors.neonGreen,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppConstants.largeRadius),
          ),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.surfaceHighest,
        contentTextStyle: AppTextStyles.cardSubtitle.copyWith(
          color: AppColors.textPrimary,
        ),
        actionTextColor: AppColors.neonGreen,
        behavior: SnackBarBehavior.floating,
        elevation: 12,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppConstants.cardRadius),
          side: const BorderSide(color: AppColors.borderDark),
        ),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          return states.contains(WidgetState.selected)
              ? AppColors.neonGreen
              : AppColors.textMuted;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          return states.contains(WidgetState.selected)
              ? AppColors.neonGlowMedium
              : AppColors.surfaceHighest;
        }),
      ),
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          return states.contains(WidgetState.selected)
              ? AppColors.neonGreen
              : Colors.transparent;
        }),
        checkColor: const WidgetStatePropertyAll(Color(0xFF101600)),
        side: const BorderSide(color: AppColors.textMuted, width: 1.5),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
      ),
    );
  }

  static InputDecorationThemeData _inputTheme({
    required Color fillColor,
    required Color borderColor,
    required Color textColor,
  }) {
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppConstants.cardRadius),
      borderSide: BorderSide(color: borderColor),
    );

    return InputDecorationThemeData(
      filled: true,
      fillColor: fillColor,
      hintStyle: AppTextStyles.cardSubtitle.copyWith(color: textColor),
      labelStyle: AppTextStyles.cardSubtitle.copyWith(color: textColor),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: border,
      enabledBorder: border,
      focusedBorder: border.copyWith(
        borderSide: const BorderSide(color: AppColors.neonGreen, width: 1.5),
      ),
      errorBorder: border.copyWith(
        borderSide: const BorderSide(color: AppColors.danger),
      ),
      focusedErrorBorder: border.copyWith(
        borderSide: const BorderSide(color: AppColors.danger, width: 1.5),
      ),
    );
  }
}
