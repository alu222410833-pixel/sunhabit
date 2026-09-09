import 'package:flutter/material.dart';
import 'package:sunhabit/core/theme/app_colors.dart';
import 'package:sunhabit/core/theme/app_decorations.dart';
import 'package:sunhabit/features/habits/data/habit_model.dart';
import 'package:sunhabit/features/habits/data/habits_repository.dart';
import 'package:sunhabit/features/habits/presentation/habit_completion_bottom_sheet/amount_section.dart';
import 'package:sunhabit/features/habits/presentation/habit_completion_bottom_sheet/checklist_section.dart';
import 'package:sunhabit/features/habits/presentation/habit_completion_bottom_sheet/timer_section.dart';
import 'package:sunhabit/features/habits/presentation/habit_completion_bottom_sheet/yes_no_section.dart';
import 'package:sunhabit/features/habits/presentation/widgets/habit_visuals.dart';

/// Bottom sheet flotante para completar un hábito según su tipo de evaluación.
///
/// Soporta Sí/No, Cantidad, Checklist y Cronómetro. Se mantiene abierto
/// hasta que el usuario pulse la X, para que pueda realizar varios cambios
/// o revisar su progreso sin que el sheet se cierre solo.
///
/// Cuando [readOnly] es true (p. ej. al visualizar un día que no es hoy),
/// se muestra el estado del hábito proporcionado por [habitOverride] y se
/// deshabilitan todas las acciones de edición.
class HabitCompletionBottomSheet extends StatefulWidget {
  final String habitId;
  final bool readOnly;
  final Habit? habitOverride;

  const HabitCompletionBottomSheet({
    super.key,
    required this.habitId,
    this.readOnly = false,
    this.habitOverride,
  });

  @override
  State<HabitCompletionBottomSheet> createState() =>
      _HabitCompletionBottomSheetState();
}

class _HabitCompletionBottomSheetState
    extends State<HabitCompletionBottomSheet> {
  final _repository = HabitsRepository();

  @override
  Widget build(BuildContext context) {
    // En modo solo lectura se usa el hábito proyectado (estado del día
    // seleccionado) y no se reacciona a cambios del repositorio.
    if (widget.readOnly) {
      final habit = widget.habitOverride;
      if (habit == null) {
        return const SizedBox.shrink();
      }
      return _buildSheet(context, habit);
    }

    return ListenableBuilder(
      listenable: _repository,
      builder: (context, _) {
        final habit = _repository.getHabitById(widget.habitId);
        if (habit == null) {
          return const SizedBox.shrink();
        }
        return _buildSheet(context, habit);
      },
    );
  }

  Widget _buildSheet(BuildContext context, Habit habit) {
    return Container(
      decoration: AppDecorations.pageBackground,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(habit),
                const SizedBox(height: 24),
                _buildBody(habit),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Encabezado con icono, título y botón para cerrar el bottom sheet.
  Widget _buildHeader(Habit habit) {
    final iconColor = habit.iconColor ?? AppColors.neonGreen;
    final imagePath = habit.effectiveImagePath;

    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: AppDecorations.iconOnlyGlow(iconColor),
          alignment: Alignment.center,
          child: imagePath != null
              ? HabitImageAvatar(imagePath: imagePath, size: 40)
              : Icon(habit.effectiveIcon, color: iconColor, size: 27),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                habit.title,
                style: Theme.of(context).textTheme.titleLarge,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              if (widget.readOnly)
                Text(
                  'Solo visualización',
                  style: Theme.of(context).textTheme.bodySmall,
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

  /// Selecciona el panel de acción según el tipo de evaluación del hábito.
  Widget _buildBody(Habit habit) {
    switch (habit.evaluationType) {
      case HabitEvaluationType.yesNo:
        return YesNoSection(habit: habit, readOnly: widget.readOnly);
      case HabitEvaluationType.amount:
        return AmountSection(habit: habit, readOnly: widget.readOnly);
      case HabitEvaluationType.checklist:
        return ChecklistSection(habit: habit, readOnly: widget.readOnly);
      case HabitEvaluationType.timer:
        return TimerSection(habit: habit, readOnly: widget.readOnly);
    }
  }
}
