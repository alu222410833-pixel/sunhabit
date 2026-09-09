import 'package:flutter/material.dart';
import 'package:sunhabit/core/constants/app_constants.dart';
import 'package:sunhabit/core/theme/app_colors.dart';
import 'package:sunhabit/features/habits/data/habit_model.dart';

class CreateHabitEvaluationTypeStep extends StatelessWidget {
  final HabitEvaluationType selected;
  final ValueChanged<HabitEvaluationType> onSelected;

  const CreateHabitEvaluationTypeStep({
    super.key,
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final options = [
      _EvaluationOption(
        type: HabitEvaluationType.yesNo,
        icon: Icons.check_box_rounded,
        title: 'Sí o No',
        subtitle: 'Marca si lo completaste o no.',
      ),
      _EvaluationOption(
        type: HabitEvaluationType.amount,
        icon: Icons.assessment_rounded,
        title: 'Una cantidad',
        subtitle: 'Define un objetivo numérico.',
      ),
      _EvaluationOption(
        type: HabitEvaluationType.checklist,
        icon: Icons.checklist_rounded,
        title: 'Checklist',
        subtitle: 'Completa una lista de ítems.',
      ),
      _EvaluationOption(
        type: HabitEvaluationType.timer,
        icon: Icons.timer_outlined,
        title: 'Con cronómetro',
        subtitle: 'Mide el tiempo dedicado.',
      ),
    ];

    return ListView(
      shrinkWrap: true,
      children: options.map((option) {
        final active = option.type == selected;
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: GestureDetector(
            onTap: () => onSelected(option.type),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              decoration: BoxDecoration(
                color: active
                    ? AppColors.neonGreen.withValues(alpha: 0.12)
                    : AppColors.surfaceHighest,
                borderRadius: BorderRadius.circular(AppConstants.cardRadius),
                border: Border.all(
                  color: active ? AppColors.neonGreen : AppColors.borderDark,
                  width: active ? 2 : 1,
                ),
              ),
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  Icon(option.icon,
                      color: active ? AppColors.neonGreen : AppColors.textSecondary,
                      size: 28),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          option.title,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          option.subtitle,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: AppColors.textSecondary,
                              ),
                        ),
                      ],
                    ),
                  ),
                  if (active)
                    const Icon(Icons.check_circle, color: AppColors.neonGreen)
                  else
                    const Icon(Icons.radio_button_unchecked,
                        color: AppColors.textMuted),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _EvaluationOption {
  final HabitEvaluationType type;
  final IconData icon;
  final String title;
  final String subtitle;

  _EvaluationOption({
    required this.type,
    required this.icon,
    required this.title,
    required this.subtitle,
  });
}
