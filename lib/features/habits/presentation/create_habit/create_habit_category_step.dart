import 'dart:io';

import 'package:flutter/material.dart';
import 'package:sunhabit/core/theme/app_colors.dart';
import 'package:sunhabit/core/theme/app_decorations.dart';
import 'package:sunhabit/features/categories/data/category_model.dart';

class CreateHabitCategoryStep extends StatelessWidget {
  final List<Category> categories;
  final String selectedId;
  final ValueChanged<String> onSelected;

  const CreateHabitCategoryStep({
    super.key,
    required this.categories,
    required this.selectedId,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      shrinkWrap: true,
      children: categories.map((category) {
        final selected = category.id == selectedId;
        final color = category.iconColor ?? category.color;
        final hasImage = category.imagePath != null &&
            category.imagePath!.isNotEmpty &&
            File(category.imagePath!).existsSync();
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: GestureDetector(
            onTap: () => onSelected(category.id),
            child: Container(
              decoration: AppDecorations.card,
              child: ListTile(
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                leading: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: hasImage
                        ? color.withValues(alpha: 0.08)
                        : color.withValues(alpha: 0.12),
                    border: Border.all(
                      color: hasImage
                          ? color.withValues(alpha: 0.3)
                          : color.withValues(alpha: 0.4),
                    ),
                    image: hasImage
                        ? DecorationImage(
                            image: FileImage(File(category.imagePath!)),
                            fit: BoxFit.cover,
                          )
                        : null,
                  ),
                  child: hasImage
                      ? null
                      : Icon(
                          category.icon ?? Icons.category_outlined,
                          color: color,
                          size: 24,
                        ),
                ),
                title: Text(
                  category.name,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                trailing: selected
                    ? const Icon(Icons.check_circle, color: AppColors.neonGreen)
                    : const Icon(Icons.radio_button_unchecked,
                        color: AppColors.textMuted),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
