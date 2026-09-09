import 'package:flutter/material.dart';
import 'package:sunhabit/core/theme/app_colors.dart';
import 'package:sunhabit/core/theme/app_decorations.dart';

class EditHabitTextFieldTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String hint;
  final TextEditingController controller;

  const EditHabitTextFieldTile({
    super.key,
    required this.icon,
    required this.label,
    required this.hint,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: AppDecorations.card,
      child: Row(
        children: [
          Icon(icon, color: AppColors.neonGreen, size: 22),
          const SizedBox(width: 16),
          Expanded(
            child: TextField(
              controller: controller,
              decoration: InputDecoration(
                hintText: hint,
                labelText: label,
                border: InputBorder.none,
                hintStyle: textTheme.bodyMedium?.copyWith(color: AppColors.textMuted),
                labelStyle: textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
              ),
              style: textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }
}
