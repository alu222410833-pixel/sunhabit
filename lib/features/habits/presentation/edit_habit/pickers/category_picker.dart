import 'dart:io';
import 'package:flutter/material.dart';
import 'package:sunhabit/core/theme/app_colors.dart';
import 'package:sunhabit/features/categories/data/category_model.dart';

Future<String?> showCategoryPicker(
  BuildContext context, {
  required List<Category> categories,
  required String selectedCategoryId,
}) {
  return showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.surfaceElevated,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (context) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.7,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Categoría', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 16),
              Expanded(
                child: ListView(
                  shrinkWrap: true,
                  children: categories.map((c) {
                    final hasImage = c.imagePath != null &&
                        c.imagePath!.isNotEmpty &&
                        File(c.imagePath!).existsSync();
                    final color = c.iconColor ?? c.color;
                    return ListTile(
                      leading: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: hasImage
                              ? color.withValues(alpha: 0.08)
                              : color.withValues(alpha: 0.12),
                          border: Border.all(
                            color: hasImage
                                ? color.withValues(alpha: 0.3)
                                : color.withValues(alpha: 0.5),
                          ),
                          image: hasImage
                              ? DecorationImage(
                                  image: FileImage(File(c.imagePath!)),
                                  fit: BoxFit.cover,
                                )
                              : null,
                        ),
                        child: hasImage
                            ? null
                            : Icon(c.icon ?? Icons.help_outline,
                                color: color, size: 22),
                      ),
                      title: Text(c.name),
                      trailing: selectedCategoryId == c.id
                          ? const Icon(Icons.check, color: AppColors.neonGreen)
                          : null,
                      onTap: () => Navigator.pop(context, c.id),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
