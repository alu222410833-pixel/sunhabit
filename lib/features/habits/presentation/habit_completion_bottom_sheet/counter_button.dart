import 'package:flutter/material.dart';
import 'package:sunhabit/core/theme/app_colors.dart';
import 'package:sunhabit/core/theme/app_decorations.dart';

/// Botón circular pequeño para sumar o restar cantidades.
///
/// Si [onTap] es null, se muestra atenuado y no responde (modo solo lectura).
class CounterButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;

  const CounterButton({super.key, required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final disabled = onTap == null;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: AppDecorations.iconGlow(AppColors.neonGreen),
        alignment: Alignment.center,
        child: Icon(
          icon,
          color: disabled
              ? AppColors.neonGreen.withValues(alpha: 0.4)
              : AppColors.neonGreen,
          size: 24,
        ),
      ),
    );
  }
}
