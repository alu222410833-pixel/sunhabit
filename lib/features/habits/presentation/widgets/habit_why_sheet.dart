import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:sunhabit/core/constants/app_constants.dart';
import 'package:sunhabit/core/services/image_picker_service.dart';
import 'package:sunhabit/core/theme/app_colors.dart';
import 'package:sunhabit/core/theme/app_decorations.dart';
import 'package:sunhabit/features/habits/data/habit_model.dart';
import 'package:sunhabit/features/habits/data/habits_repository.dart';

/// Bottom sheet «Mi porqué»: muestra y edita la motivación personal de un
/// hábito (imagen, frase y meta personal).
///
/// Se puede apilar sobre [HabitCompletionBottomSheet]; al cerrarlo con la X
/// o con «Volver al hábito» se regresa al registro sin perder el contexto.
class HabitWhySheet extends StatelessWidget {
  final String habitId;

  const HabitWhySheet({super.key, required this.habitId});

  static Future<void> show(BuildContext context, String habitId) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => HabitWhySheet(habitId: habitId),
    );
  }

  @override
  Widget build(BuildContext context) {
    final repository = HabitsRepository();
    return ListenableBuilder(
      listenable: repository,
      builder: (context, _) {
        final habit = repository.getHabitById(habitId);
        if (habit == null) return const SizedBox.shrink();
        return _buildSheet(context, habit);
      },
    );
  }

  Widget _buildSheet(BuildContext context, Habit habit) {
    final iconColor = habit.iconColor ?? AppColors.neonGreen;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color.lerp(const Color(0xFF171B17), iconColor, 0.12)!,
            const Color(0xFF0A0C0A),
            const Color(0xFF0C120B),
          ],
          stops: const [0.0, 0.55, 1.0],
        ),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        // Borde uniforme: el acento neón superior se dibuja aparte con
        // un Positioned para evitar la excepción de paint con borderRadius.
        border: Border.all(color: AppColors.borderDark),
        boxShadow: [
          BoxShadow(
            color: iconColor.withValues(alpha: 0.16),
            blurRadius: 26,
            offset: const Offset(0, -6),
          ),
        ],
      ),
      child: Stack(
        children: [
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Center(
                      child: Container(
                        width: 42,
                        height: 4.5,
                        decoration: BoxDecoration(
                          color: iconColor.withValues(alpha: 0.85),
                          borderRadius: BorderRadius.circular(3),
                          boxShadow: [
                            BoxShadow(
                              color: iconColor.withValues(alpha: 0.4),
                              blurRadius: 8,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildHeader(context, habit),
                    const SizedBox(height: 16),
                    _buildHero(habit, textTheme),
                    if (habit.whyGoal != null && habit.whyGoal!.isNotEmpty) ...[
                      const SizedBox(height: 14),
                      _buildGoalCard(habit, textTheme),
                    ],
                    const SizedBox(height: 18),
                    _buildActionButtons(context, habit, textTheme),
                    const SizedBox(height: 14),
                    Text(
                      'Pequeños hábitos, grandes cambios.',
                      textAlign: TextAlign.center,
                      style: textTheme.bodySmall?.copyWith(
                        color: AppColors.textMuted,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                    const SizedBox(height: 14),
                    GestureDetector(
                      onTap: () => Navigator.of(context).pop(),
                      child: Container(
                        height: AppConstants.controlHeight,
                        decoration: BoxDecoration(
                          color: AppColors.surfaceHighest,
                          borderRadius:
                              BorderRadius.circular(AppConstants.cardRadius),
                          border: Border.all(color: AppColors.borderDark),
                        ),
                        alignment: Alignment.center,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.arrow_back_rounded,
                              size: 18,
                              color: AppColors.textPrimary,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Volver al hábito',
                              style: textTheme.titleMedium?.copyWith(
                                color: AppColors.textPrimary,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          // Acento neón del borde superior
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: 1.4,
            child: Container(
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.5),
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(24),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, Habit habit) {
    final textTheme = Theme.of(context).textTheme;
    return Row(
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.star.withValues(alpha: 0.14),
            border: Border.all(
              color: AppColors.star.withValues(alpha: 0.6),
              width: 1.4,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.star.withValues(alpha: 0.25),
                blurRadius: 12,
              ),
            ],
          ),
          alignment: Alignment.center,
          child: const Icon(Icons.star_rounded,
              color: AppColors.star, size: 24),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Tu porqué', style: textTheme.titleLarge),
              Text(
                habit.title,
                style: textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondary,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ],
    );
  }

  /// Imagen + frase. Si solo hay frase, se muestra como tarjeta de cita.
  /// Si no hay nada, se muestra un estado vacío que invita a configurarlo.
  Widget _buildHero(Habit habit, TextTheme textTheme) {
    final imagePath = habit.whyImagePath;
    final hasImage = imagePath != null &&
        imagePath.isNotEmpty &&
        File(imagePath).existsSync();
    final hasPhrase =
        habit.whyPhrase != null && habit.whyPhrase!.isNotEmpty;

    if (hasImage) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(AppConstants.largeRadius),
        child: AspectRatio(
          aspectRatio: 16 / 9,
          child: Stack(
            fit: StackFit.expand,
            children: [
              Image.file(
                File(imagePath),
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => Container(
                  color: AppColors.surfaceHighest,
                  alignment: Alignment.center,
                  child: const Icon(Icons.broken_image_outlined,
                      color: AppColors.textMuted, size: 36),
                ),
              ),
              if (hasPhrase)
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: Container(
                    padding: const EdgeInsets.fromLTRB(14, 26, 14, 12),
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Colors.transparent, Colors.black87],
                      ),
                    ),
                    child: Text(
                      '“${habit.whyPhrase}”',
                      style: textTheme.titleSmall?.copyWith(
                        color: Colors.white,
                        fontStyle: FontStyle.italic,
                        height: 1.3,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      );
    }

    if (hasPhrase) {
      return Container(
        padding: const EdgeInsets.all(18),
        decoration: AppDecorations.card,
        child: Column(
          children: [
            const Icon(Icons.format_quote_rounded,
                color: AppColors.star, size: 28),
            const SizedBox(height: 8),
            Text(
              '“${habit.whyPhrase}”',
              textAlign: TextAlign.center,
              style: textTheme.titleMedium?.copyWith(
                fontStyle: FontStyle.italic,
                height: 1.35,
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 18),
      decoration: AppDecorations.card,
      child: Column(
        children: [
          Icon(Icons.star_outline_rounded,
              color: AppColors.star.withValues(alpha: 0.7), size: 34),
          const SizedBox(height: 10),
          Text(
            'Aún no has definido tu porqué',
            style: textTheme.titleSmall,
          ),
          const SizedBox(height: 6),
          Text(
            'Añade una imagen, una frase o tu meta personal para recordar qué te motiva.',
            textAlign: TextAlign.center,
            style: textTheme.bodySmall?.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGoalCard(Habit habit, TextTheme textTheme) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: AppDecorations.card,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.neonGreen.withValues(alpha: 0.12),
              border: Border.all(
                color: AppColors.neonGreen.withValues(alpha: 0.5),
              ),
            ),
            alignment: Alignment.center,
            child: const Icon(Icons.track_changes_rounded,
                color: AppColors.neonGreen, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Mi meta personal', style: textTheme.titleSmall),
                const SizedBox(height: 4),
                Text(
                  habit.whyGoal!,
                  style: textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(
      BuildContext context, Habit habit, TextTheme textTheme) {
    final hasImage =
        habit.whyImagePath != null && habit.whyImagePath!.isNotEmpty;
    final hasPhrase =
        habit.whyPhrase != null && habit.whyPhrase!.isNotEmpty;
    final hasGoal = habit.whyGoal != null && habit.whyGoal!.isNotEmpty;

    return Row(
      children: [
        Expanded(
          child: _WhyActionButton(
            icon: Icons.image_outlined,
            label: 'Imagen',
            active: hasImage,
            onTap: () => _pickWhyImage(context),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _WhyActionButton(
            icon: Icons.format_quote_rounded,
            label: 'Frase',
            active: hasPhrase,
            onTap: () => _editWhyText(
              context,
              title: 'Tu frase',
              hint: 'Escribe una frase que te motive',
              initial: habit.whyPhrase,
              onSaved: (value) => _saveWhy(whyPhrase: value),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _WhyActionButton(
            icon: Icons.track_changes_rounded,
            label: 'Meta',
            active: hasGoal,
            onTap: () => _editWhyText(
              context,
              title: 'Mi meta personal',
              hint: '¿Qué quieres conseguir con este hábito?',
              initial: habit.whyGoal,
              onSaved: (value) => _saveWhy(whyGoal: value),
            ),
          ),
        ),
      ],
    );
  }

  // ---- Edición ----

  Future<void> _saveWhy({
    Object? whyPhrase = _keep,
    Object? whyGoal = _keep,
    Object? whyImagePath = _keep,
  }) async {
    final repository = HabitsRepository();
    final habit = repository.getHabitById(habitId);
    if (habit == null) return;
    await repository.updateHabit(
      habit.copyWith(
        whyPhrase: whyPhrase == _keep ? habit.whyPhrase : whyPhrase,
        whyGoal: whyGoal == _keep ? habit.whyGoal : whyGoal,
        whyImagePath:
            whyImagePath == _keep ? habit.whyImagePath : whyImagePath,
      ),
    );
  }

  static const Object _keep = Object();

  Future<void> _pickWhyImage(BuildContext context) async {
    final habit = HabitsRepository().getHabitById(habitId);
    if (habit == null || !context.mounted) return;
    final hasImage =
        habit.whyImagePath != null && habit.whyImagePath!.isNotEmpty;

    final choice = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: AppColors.surfaceElevated,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.photo_library_outlined,
                    color: AppColors.neonGreen),
                title: const Text('Elegir de la galería'),
                onTap: () => Navigator.pop(sheetContext, 'gallery'),
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt_outlined,
                    color: AppColors.neonGreen),
                title: const Text('Tomar foto'),
                onTap: () => Navigator.pop(sheetContext, 'camera'),
              ),
              if (hasImage)
                ListTile(
                  leading: const Icon(Icons.delete_outline_rounded,
                      color: AppColors.danger),
                  title: const Text('Quitar imagen'),
                  onTap: () => Navigator.pop(sheetContext, 'remove'),
                ),
            ],
          ),
        ),
      ),
    );

    if (choice == null) return;
    if (choice == 'remove') {
      await _saveWhy(whyImagePath: null);
      return;
    }

    final path = await ImagePickerService().pickImage(
      source: choice == 'camera' ? ImageSource.camera : ImageSource.gallery,
      aspectRatioX: 16,
      aspectRatioY: 9,
      cropPreset: CropAspectRatioPreset.ratio16x9,
    );
    if (path != null && path.isNotEmpty) {
      await _saveWhy(whyImagePath: path);
    }
  }

  Future<void> _editWhyText(
    BuildContext context, {
    required String title,
    required String hint,
    required String? initial,
    required Future<void> Function(String?) onSaved,
  }) async {
    final result = await showDialog<String>(
      context: context,
      builder: (_) => _WhyTextDialog(
        title: title,
        hint: hint,
        initial: initial ?? '',
      ),
    );
    if (result == null) return;
    final trimmed = result.trim();
    await onSaved(trimmed.isEmpty ? null : trimmed);
  }
}

class _WhyActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback onTap;

  const _WhyActionButton({
    required this.icon,
    required this.label,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final color = active ? AppColors.neonGreen : AppColors.textSecondary;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: active
              ? AppColors.neonGreen.withValues(alpha: 0.12)
              : AppColors.surfaceHighest,
          borderRadius: BorderRadius.circular(AppConstants.cardRadius),
          border: Border.all(
            color: active ? AppColors.neonGreen : AppColors.borderDark,
            width: active ? 1.4 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 6),
            Text(
              label,
              style: textTheme.bodySmall?.copyWith(
                color: color,
                fontWeight: active ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Diálogo de texto para editar la frase o la meta del «porqué».
class _WhyTextDialog extends StatefulWidget {
  final String title;
  final String hint;
  final String initial;

  const _WhyTextDialog({
    required this.title,
    required this.hint,
    required this.initial,
  });

  @override
  State<_WhyTextDialog> createState() => _WhyTextDialogState();
}

class _WhyTextDialogState extends State<_WhyTextDialog> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initial);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Dialog(
      backgroundColor: AppColors.surfaceElevated,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppConstants.largeRadius),
        side: const BorderSide(color: AppColors.borderDark),
      ),
      insetPadding: const EdgeInsets.all(20),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              widget.title,
              style: textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _controller,
              autofocus: true,
              minLines: 2,
              maxLines: 4,
              maxLength: 160,
              style: textTheme.bodyMedium,
              decoration: InputDecoration(
                hintText: widget.hint,
                hintStyle: textTheme.bodyMedium?.copyWith(
                  color: AppColors.textMuted,
                ),
                filled: true,
                fillColor: AppColors.surfaceHighest,
                border: OutlineInputBorder(
                  borderRadius:
                      BorderRadius.circular(AppConstants.cardRadius),
                  borderSide: const BorderSide(color: AppColors.borderDark),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius:
                      BorderRadius.circular(AppConstants.cardRadius),
                  borderSide: const BorderSide(color: AppColors.borderDark),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius:
                      BorderRadius.circular(AppConstants.cardRadius),
                  borderSide:
                      const BorderSide(color: AppColors.neonGreen),
                ),
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: Container(
                      height: AppConstants.controlHeight,
                      decoration: BoxDecoration(
                        color: AppColors.surfaceHighest,
                        borderRadius: BorderRadius.circular(
                            AppConstants.cardRadius),
                        border:
                            Border.all(color: AppColors.borderDark),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        'Cancelar',
                        style: textTheme.titleMedium?.copyWith(
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: GestureDetector(
                    onTap: () =>
                        Navigator.of(context).pop(_controller.text),
                    child: Container(
                      height: AppConstants.controlHeight,
                      decoration: AppDecorations.neonButton,
                      alignment: Alignment.center,
                      child: Text(
                        'Guardar',
                        style: textTheme.titleMedium?.copyWith(
                          color: const Color(0xFF152000),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
