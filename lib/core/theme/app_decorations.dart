import 'package:flutter/material.dart';
import 'package:sunhabit/core/constants/app_constants.dart';
import 'package:sunhabit/core/theme/app_colors.dart';

class AppDecorations {
  static const RadialGradient pageGradient = RadialGradient(
    center: Alignment(0.35, -0.15),
    radius: 1.15,
    colors: [Color(0xFF0A1007), Color(0xFF030503), AppColors.backgroundDark],
    stops: [0, 0.5, 1],
  );

  static const LinearGradient neonGradient = LinearGradient(
    colors: [
      AppColors.neonGreenBright,
      AppColors.neonGreen,
      AppColors.neonGreenDark,
    ],
    stops: [0, 0.42, 1],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static const LinearGradient darkCardGradient = LinearGradient(
    colors: [Color(0xFF171B17), Color(0xFF090B09), Color(0xFF0E140A)],
    stops: [0, 0.62, 1],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const RadialGradient summaryGradient = RadialGradient(
    center: Alignment(0.72, -0.08),
    radius: 1.15,
    colors: [Color(0xFF17220E), Color(0xFF111411), Color(0xFF080A08)],
    stops: [0, 0.52, 1],
  );

  static const List<BoxShadow> cardShadow = [
    BoxShadow(
      color: AppColors.blackShadow,
      blurRadius: 12,
      offset: Offset(0, 5),
    ),
  ];

  static const List<BoxShadow> neonGlow = [
    BoxShadow(color: Color(0x555EFF00), blurRadius: 11),
    BoxShadow(color: Color(0x1F5EFF00), blurRadius: 20, spreadRadius: 1),
  ];

  static const List<BoxShadow> neonGlowSoft = [
    BoxShadow(color: Color(0x285EFF00), blurRadius: 7),
  ];

  static const List<BoxShadow> controlGlow = [
    BoxShadow(color: Color(0x305EFF00), blurRadius: 6),
  ];

  static BoxDecoration get pageBackground => const BoxDecoration(
    color: AppColors.backgroundDark,
    gradient: pageGradient,
  );

  static BoxDecoration get card => BoxDecoration(
    gradient: darkCardGradient,
    borderRadius: BorderRadius.circular(AppConstants.cardRadius),
    border: Border.all(color: AppColors.borderDark),
    boxShadow: cardShadow,
  );

  static BoxDecoration get habitCard => BoxDecoration(
    gradient: darkCardGradient,
    borderRadius: BorderRadius.circular(AppConstants.cardRadius),
    border: Border.all(color: AppColors.borderDark.withValues(alpha: 0.9)),
    boxShadow: const [
      ...cardShadow,
      BoxShadow(
        color: Color(0x125EFF00),
        blurRadius: 12,
        offset: Offset(10, 0),
      ),
    ],
  );

  static BoxDecoration get summaryCard => BoxDecoration(
    gradient: summaryGradient,
    borderRadius: BorderRadius.circular(AppConstants.largeRadius),
    border: Border.all(color: AppColors.borderDark),
    boxShadow: const [
      ...cardShadow,
      BoxShadow(
        color: Color(0x1F5EFF00),
        blurRadius: 22,
        offset: Offset(18, 0),
      ),
    ],
  );

  static BoxDecoration get neonButton => BoxDecoration(
    gradient: neonGradient,
    borderRadius: BorderRadius.circular(AppConstants.cardRadius),
    border: Border.all(color: AppColors.neonGreenBright),
    boxShadow: neonGlow,
  );

  static BoxDecoration get bottomNavigation => const BoxDecoration(
    color: AppColors.surfaceDark,
    border: Border(top: BorderSide(color: Color(0xFF1D2618))),
    boxShadow: [
      BoxShadow(
        color: Color(0x1F5EFF00),
        blurRadius: 18,
        offset: Offset(0, -4),
      ),
    ],
  );

  static BoxDecoration get centerAction => const BoxDecoration(
    shape: BoxShape.circle,
    gradient: RadialGradient(
      colors: [Color(0xFF1A2116), Color(0xFF090B09)],
      stops: [0, 1],
    ),
    border: Border.fromBorderSide(BorderSide(color: AppColors.borderDark)),
    boxShadow: [
      BoxShadow(color: Color(0x355EFF00), blurRadius: 13),
      BoxShadow(
        color: AppColors.blackShadow,
        blurRadius: 10,
        offset: Offset(0, 5),
      ),
    ],
  );

  static BoxDecoration get neonCircle => const BoxDecoration(
    shape: BoxShape.circle,
    gradient: neonGradient,
    boxShadow: controlGlow,
  );

  static BoxDecoration iconOnlyGlow(Color color) => BoxDecoration(
    shape: BoxShape.circle,
    boxShadow: [BoxShadow(color: color.withValues(alpha: 0.14), blurRadius: 6)],
  );

  static BoxDecoration iconGlow(Color color) => BoxDecoration(
    shape: BoxShape.circle,
    color: color.withValues(alpha: 0.06),
    border: Border.all(color: color.withValues(alpha: 0.3)),
    boxShadow: [BoxShadow(color: color.withValues(alpha: 0.1), blurRadius: 5)],
  );
}
