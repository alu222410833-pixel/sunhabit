import 'package:flutter/material.dart';
import 'package:sunhabit/core/constants/app_constants.dart';
import 'package:sunhabit/core/theme/app_colors.dart';
import 'package:sunhabit/core/theme/app_decorations.dart';

/// Botón de acción reutilizable con estilo verde neón.
///
/// Si [onTap] es null, el botón se muestra atenuado y no responde a toques
/// (usado en modo solo lectura).
class ActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback? onTap;
  final Color? color;

  const ActionButton({
    super.key,
    required this.label,
    required this.icon,
    required this.onTap,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final disabled = onTap == null;
    final accent = color ?? AppColors.neonGreen;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 52,
        padding: const EdgeInsets.symmetric(horizontal: 24),
        decoration: color != null
            ? BoxDecoration(
                color: disabled ? accent.withValues(alpha: 0.12) : accent,
                borderRadius: BorderRadius.circular(AppConstants.cardRadius),
                border: Border.all(
                  color: disabled ? accent.withValues(alpha: 0.3) : accent,
                ),
                boxShadow: disabled
                    ? null
                    : [
                        BoxShadow(
                          color: accent.withValues(alpha: 0.35),
                          blurRadius: 16,
                          spreadRadius: -2,
                        ),
                      ],
              )
            : AppDecorations.neonButton,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: disabled ? Colors.white38 : Colors.white,
              size: 24,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: disabled ? Colors.white38 : Colors.white,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
