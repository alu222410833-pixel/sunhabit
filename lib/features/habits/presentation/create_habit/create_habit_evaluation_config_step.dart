import 'package:flutter/material.dart';
import 'package:sunhabit/features/habits/data/habit_model.dart';
import 'package:sunhabit/features/habits/presentation/create_habit/evaluation/amount_evaluation_body.dart';
import 'package:sunhabit/features/habits/presentation/create_habit/evaluation/checklist_evaluation_body.dart';
import 'package:sunhabit/features/habits/presentation/create_habit/evaluation/timer_evaluation_body.dart';
import 'package:sunhabit/features/habits/presentation/create_habit/evaluation/yes_no_evaluation_body.dart';

class CreateHabitEvaluationConfigStep extends StatelessWidget {
  final HabitEvaluationType type;
  final TextEditingController titleController;
  final TextEditingController descriptionController;
  final TextEditingController targetController;
  final TextEditingController timerHoursController;
  final TextEditingController timerMinutesController;
  final TextEditingController timerSecondsController;
  final TextEditingController checklistController;

  final String condition;
  final List<String> conditions;
  final int target;
  final String unit;
  final List<String> units;
  final String timerCondition;
  final int timerHours;
  final int timerMinutes;
  final int timerSeconds;
  final List<String> checklistItems;

  final ValueChanged<String> onConditionChanged;
  final ValueChanged<int> onTargetChanged;
  final ValueChanged<String> onUnitChanged;
  final ValueChanged<String> onTimerConditionChanged;
  final ValueChanged<int> onTimerHoursChanged;
  final ValueChanged<int> onTimerMinutesChanged;
  final ValueChanged<int> onTimerSecondsChanged;
  final VoidCallback onChecklistAdded;
  final ValueChanged<int> onChecklistRemoved;
  final void Function(int oldIndex, int newIndex) onChecklistReordered;

  const CreateHabitEvaluationConfigStep({
    super.key,
    required this.type,
    required this.titleController,
    required this.descriptionController,
    required this.targetController,
    required this.timerHoursController,
    required this.timerMinutesController,
    required this.timerSecondsController,
    required this.checklistController,
    required this.condition,
    required this.conditions,
    required this.target,
    required this.unit,
    required this.units,
    required this.timerCondition,
    required this.timerHours,
    required this.timerMinutes,
    required this.timerSeconds,
    required this.checklistItems,
    required this.onConditionChanged,
    required this.onTargetChanged,
    required this.onUnitChanged,
    required this.onTimerConditionChanged,
    required this.onTimerHoursChanged,
    required this.onTimerMinutesChanged,
    required this.onTimerSecondsChanged,
    required this.onChecklistAdded,
    required this.onChecklistRemoved,
    required this.onChecklistReordered,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: titleController,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(
              labelText: 'Nombre del hábito',
              prefixIcon: Icon(Icons.edit_outlined),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: descriptionController,
            textCapitalization: TextCapitalization.sentences,
            maxLines: 2,
            decoration: const InputDecoration(
              labelText: 'Descripción (opcional)',
              prefixIcon: Icon(Icons.notes_outlined),
            ),
          ),
          const SizedBox(height: 16),
          _buildBody(),
        ],
      ),
    );
  }

  Widget _buildBody() {
    switch (type) {
      case HabitEvaluationType.yesNo:
        return const YesNoEvaluationBody();
      case HabitEvaluationType.amount:
        return AmountEvaluationBody(
          condition: condition,
          conditions: conditions,
          targetController: targetController,
          target: target,
          unit: unit,
          units: units,
          onConditionChanged: onConditionChanged,
          onTargetChanged: onTargetChanged,
          onUnitChanged: onUnitChanged,
        );
      case HabitEvaluationType.checklist:
        return ChecklistEvaluationBody(
          checklistController: checklistController,
          checklistItems: checklistItems,
          onChecklistAdded: onChecklistAdded,
          onChecklistRemoved: onChecklistRemoved,
          onChecklistReordered: onChecklistReordered,
        );
      case HabitEvaluationType.timer:
        return TimerEvaluationBody(
          condition: timerCondition,
          conditions: conditions,
          hoursController: timerHoursController,
          minutesController: timerMinutesController,
          secondsController: timerSecondsController,
          hours: timerHours,
          minutes: timerMinutes,
          seconds: timerSeconds,
          onConditionChanged: onTimerConditionChanged,
          onHoursChanged: onTimerHoursChanged,
          onMinutesChanged: onTimerMinutesChanged,
          onSecondsChanged: onTimerSecondsChanged,
        );
    }
  }
}
