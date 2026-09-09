import 'dart:io';

import 'package:flutter/material.dart';
import 'package:sunhabit/core/theme/app_colors.dart';
import 'package:sunhabit/core/theme/app_decorations.dart';
import 'package:sunhabit/features/categories/data/category_model.dart';
import 'package:sunhabit/features/categories/presentation/create_category_dialog.dart';
import 'package:sunhabit/features/habits/data/habit_model.dart';
import 'package:sunhabit/features/habits/data/habits_repository.dart';

class CategoriesMenuScreen extends StatefulWidget {
  final HabitsRepository repository;

  const CategoriesMenuScreen({super.key, required this.repository});

  @override
  State<CategoriesMenuScreen> createState() => _CategoriesMenuScreenState();
}

class _CategoriesMenuScreenState extends State<CategoriesMenuScreen> {
  List<Category> get _categories => widget.repository.getCategories();
  List<Habit> get _habits => widget.repository.getHabits();

  int _habitCountFor(Category category) {
    return _habits.where((h) => h.categoryId == category.id).length;
  }

  Future<void> _createCategory() async {
    final category = await showDialog<Category>(
      context: context,
      builder: (_) => const CreateCategoryDialog(),
    );
    if (category == null) return;
    widget.repository.addCategory(category);
    if (mounted) setState(() {});
  }

  Future<void> _editCategory(Category category) async {
    final updated = await showDialog<Category>(
      context: context,
      builder: (_) => CreateCategoryDialog(initialCategory: category),
    );
    if (updated == null) return;
    widget.repository.updateCategory(updated);
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: DecoratedBox(
        decoration: AppDecorations.pageBackground,
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(22, 18, 22, 110),
            children: [
              Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.surfaceHighest,
                        border: Border.all(color: AppColors.borderDark),
                      ),
                      child: const Icon(
                        Icons.arrow_back_rounded,
                        color: AppColors.textSecondary,
                        size: 22,
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      'Mis categorías',
                      style: textTheme.displaySmall,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                '${_categories.length} categorías · ${_habits.length} hábitos',
                style: textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 24),
              ..._categories.map((category) {
                final count = _habitCountFor(category);
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _CategoryListTile(
                    category: category,
                    habitCount: count,
                    onTap: () => _editCategory(category),
                  ),
                );
              }),
            ],
          ),
        ),
      ),
      floatingActionButton: Container(
        decoration: AppDecorations.neonCircle,
        child: FloatingActionButton(
          heroTag: 'create-category',
          onPressed: _createCategory,
          backgroundColor: Colors.transparent,
          elevation: 0,
          child: const Icon(Icons.add_rounded, size: 34),
        ),
      ),
    );
  }
}

class _CategoryListTile extends StatelessWidget {
  final Category category;
  final int habitCount;
  final VoidCallback? onTap;

  const _CategoryListTile({
    required this.category,
    required this.habitCount,
    this.onTap,
  });

  Future<void> _showEnlargedPreview(BuildContext context) {
    return showDialog(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) {
        final color = category.iconColor ?? category.color;
        final imagePath = category.imagePath;
        final hasImage = imagePath != null &&
            imagePath.isNotEmpty &&
            File(imagePath).existsSync();
        return GestureDetector(
          onTap: () => Navigator.of(dialogContext).pop(),
          child: Dialog(
            backgroundColor: Colors.transparent,
            insetPadding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 260,
                  height: 260,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: hasImage
                        ? color.withValues(alpha: 0.08)
                        : color.withValues(alpha: 0.12),
                    border: Border.all(
                      color: hasImage
                          ? color.withValues(alpha: 0.3)
                          : color.withValues(alpha: 0.5),
                      width: 2,
                    ),
                    image: hasImage
                        ? DecorationImage(
                            image: FileImage(File(imagePath)),
                            fit: BoxFit.cover,
                          )
                        : null,
                    boxShadow: AppDecorations.cardShadow,
                  ),
                  child: hasImage
                      ? null
                      : Icon(
                          category.icon ?? Icons.category_outlined,
                          color: color,
                          size: 140,
                        ),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 10),
                  decoration: AppDecorations.card,
                  child: Text(
                    category.name,
                    style: Theme.of(dialogContext).textTheme.titleLarge,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Toca para cerrar',
                  style: Theme.of(dialogContext).textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final color = category.iconColor ?? category.color;
    final imagePath = category.imagePath;
    final hasImage = imagePath != null &&
        imagePath.isNotEmpty &&
        File(imagePath).existsSync();

    return Container(
      decoration: AppDecorations.card,
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        leading: GestureDetector(
          onTap: () => _showEnlargedPreview(context),
          child: Container(
            width: 48,
            height: 48,
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
                      image: FileImage(File(imagePath)),
                      fit: BoxFit.cover,
                    )
                  : null,
            ),
            child: hasImage
                ? null
                : Icon(
                    category.icon ?? Icons.category_outlined,
                    color: color,
                    size: 26,
                  ),
          ),
        ),
        title: Text(
          category.name,
          style: textTheme.titleMedium,
        ),
        subtitle: Text(
          '$habitCount ${habitCount == 1 ? 'hábito' : 'hábitos'}',
          style: textTheme.bodyMedium?.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        trailing: const Icon(
          Icons.chevron_right_rounded,
          color: AppColors.textSecondary,
        ),
      ),
    );
  }
}
