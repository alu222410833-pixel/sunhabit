import 'package:flutter/material.dart';
import 'package:sunhabit/core/theme/app_colors.dart';
import 'package:sunhabit/core/theme/app_decorations.dart';

class EditHabitTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final Widget? child;
  final String? value;
  final VoidCallback onTap;

  const EditHabitTile({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
    this.child,
    this.value,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: AppDecorations.card,
        child: Row(
          children: [
            Icon(icon, color: AppColors.neonGreen, size: 22),
            const SizedBox(width: 16),
            Expanded(
              child: Text(label, style: textTheme.bodyMedium),
            ),
            // ignore: use_null_aware_elements
            if (child case final c?) c,
            if (value case final v?)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.surfaceDark,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(v, style: textTheme.bodyMedium),
              ),
            const SizedBox(width: 8),
            const Icon(Icons.chevron_right, color: AppColors.textSecondary, size: 20),
          ],
        ),
      ),
    );
  }
}
