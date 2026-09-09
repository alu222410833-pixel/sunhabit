import 'dart:io';

import 'package:flutter/material.dart';
import 'package:sunhabit/core/services/reminder_service.dart';
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

  Future<void> _deleteCategory(Category category) async {
    final affectedHabits =
        _habits.where((h) => h.categoryId == category.id).toList();
    final isLast = _categories.length <= 1;

    final confirmed = await _showDeleteConfirmation(
      category: category,
      affectedHabits: affectedHabits,
      isLastCategory: isLast,
    );
    if (confirmed == null || !confirmed || !mounted) return;

    final fallbackId = await _pickFallbackCategory(excludeId: category.id);
    if (fallbackId == null) return; // El usuario canceló la reasignación.

    final result = await widget.repository.deleteCategory(
      category.id,
      fallbackCategoryId: fallbackId,
    );

    if (!mounted) return;

    switch (result) {
      case CategoryDeletionResult.success:
        // Reprogramar los hábitos reasignados para que hereden el sonido de la
        // nueva categoría, si aplica.
        for (final habit in affectedHabits) {
          final reassigned = widget.repository.getHabitById(habit.id);
          if (reassigned != null) {
            await ReminderService.instance.cancelHabit(reassigned);
            await ReminderService.instance.scheduleHabit(reassigned);
          }
        }
        setState(() {});
      case CategoryDeletionResult.blockedLastCategory:
        _showSnack('No se puede eliminar la última categoría restante.');
      case CategoryDeletionResult.notFound:
        _showSnack('La categoría ya no existe.');
    }
  }

  /// Diálogo de confirmación de borrado. Devuelve `true` si el usuario
  /// confirma, `false` si cancela explícitamente, o `null` si la operación
  /// no puede continuar (última categoría).
  Future<bool?> _showDeleteConfirmation({
    required Category category,
    required List<Habit> affectedHabits,
    required bool isLastCategory,
  }) {
    if (isLastCategory) {
      _showSnack('No se puede eliminar la última categoría restante.');
      return Future.value(null);
    }

    final hasHabits = affectedHabits.isNotEmpty;
    final message = hasHabits
        ? 'La categoría "${category.name}" tiene ${affectedHabits.length} '
            '${affectedHabits.length == 1 ? 'hábito asociado' : 'hábitos asociados'}. '
            'Se reasignarán a otra categoría. ¿Continuar?'
        : '¿Seguro que quieres eliminar la categoría "${category.name}"? '
            'Esta acción no se puede deshacer.';

    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar categoría'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Eliminar',
              style: TextStyle(color: Colors.redAccent),
            ),
          ),
        ],
      ),
    );
  }

  /// Permite al usuario elegir a qué categoría reasignar los hábitos.
  /// Si solo hay una candidata, se selecciona automáticamente.
  Future<String?> _pickFallbackCategory({required String excludeId}) {
    final candidates =
        _categories.where((c) => c.id != excludeId).toList();
    if (candidates.isEmpty) return Future.value(null);
    if (candidates.length == 1) {
      return Future.value(candidates.first.id);
    }

    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reasignar hábitos'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView(
            shrinkWrap: true,
            children: [
              const Text(
                'Selecciona la categoría a la que se moverán los hábitos:',
              ),
              const SizedBox(height: 8),
              ...candidates.map(
                (c) => ListTile(
                  leading: Icon(
                    c.icon ?? Icons.category_outlined,
                    color: c.iconColor ?? c.color,
                  ),
                  title: Text(c.name),
                  onTap: () => Navigator.pop(context, c.id),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, null),
            child: const Text('Cancelar'),
          ),
        ],
      ),
    );
  }

  void _showSnack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.surfaceHighest,
        duration: const Duration(seconds: 3),
      ),
    );
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
                    onDelete: () => _deleteCategory(category),
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
  final VoidCallback? onDelete;

  const _CategoryListTile({
    required this.category,
    required this.habitCount,
    this.onTap,
    this.onDelete,
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
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (onDelete != null)
              IconButton(
                icon: const Icon(
                  Icons.delete_outline_rounded,
                  color: AppColors.danger,
                  size: 22,
                ),
                tooltip: 'Eliminar categoría',
                onPressed: onDelete,
              ),
            const Icon(
              Icons.chevron_right_rounded,
              color: AppColors.textSecondary,
            ),
          ],
        ),
      ),
    );
  }
}
