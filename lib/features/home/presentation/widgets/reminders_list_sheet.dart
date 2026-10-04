import 'package:flutter/material.dart';
import 'package:sunhabit/core/constants/app_constants.dart';
import 'package:sunhabit/core/services/reminder_service.dart';
import 'package:sunhabit/core/theme/app_colors.dart';
import 'package:sunhabit/features/habits/data/habit_model.dart';
import 'package:sunhabit/features/habits/data/habits_repository.dart';
import 'package:sunhabit/features/habits/presentation/widgets/habit_visuals.dart';

/// Muestra un bottom sheet con la lista de TODOS los recordatorios de todos
/// los hábitos, ordenados por hora. Permite ver y eliminar cada uno.
Future<void> showRemindersListSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => const _RemindersListSheet(),
  );
}

class _ReminderEntry {
  final Habit habit;
  final int reminderIndex;
  final Reminder reminder;

  const _ReminderEntry(this.habit, this.reminderIndex, this.reminder);

  int get minutes => reminder.hour * 60 + reminder.minute;
}

class _RemindersListSheet extends StatelessWidget {
  const _RemindersListSheet();

  List<_ReminderEntry> _collect(HabitsRepository repository) {
    final entries = <_ReminderEntry>[];
    for (final habit in repository.getHabits()) {
      for (int i = 0; i < habit.reminders.length; i++) {
        entries.add(_ReminderEntry(habit, i, habit.reminders[i]));
      }
    }
    entries.sort((a, b) => a.minutes.compareTo(b.minutes));
    return entries;
  }

  String _weekDaysText(Reminder reminder) {
    const labels = ['L', 'M', 'X', 'J', 'V', 'S', 'D'];
    final days = reminder.weekDays;
    if (days == null || days.isEmpty) return 'Todos los días';
    final selected = <String>[];
    for (var i = 0; i < days.length && i < 7; i++) {
      if (days[i]) selected.add(labels[i]);
    }
    return selected.isEmpty ? 'Todos los días' : selected.join(' ');
  }

  Future<void> _deleteReminder(
    BuildContext context,
    _ReminderEntry entry,
  ) async {
    final habit = entry.habit;
    final updatedReminders = List<Reminder>.from(habit.reminders)
      ..removeAt(entry.reminderIndex);
    final updated = habit.copyWith(reminders: updatedReminders);
    final repository = HabitsRepository();
    await repository.updateHabit(updated);
    await ReminderService.instance.scheduleHabit(updated);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppColors.surfaceHighest,
          duration: const Duration(seconds: 2),
          content: Text(
            'Recordatorio de "${habit.title}" ${entry.reminder.timeText} eliminado',
            style: const TextStyle(color: AppColors.textPrimary),
          ),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final maxHeight = MediaQuery.of(context).size.height * 0.75;

    return Container(
      constraints: BoxConstraints(maxHeight: maxHeight),
      decoration: const BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 10),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.neonGreen,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 14),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Recordatorios',
                      style: textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(
                      Icons.close_rounded,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 4),
            Flexible(
              child: ListenableBuilder(
                listenable: HabitsRepository(),
                builder: (context, _) {
                  final entries = _collect(HabitsRepository());
                  if (entries.isEmpty) {
                    return const Padding(
                      padding: EdgeInsets.all(40),
                      child: Text(
                        'No hay recordatorios configurados',
                        style: TextStyle(color: AppColors.textSecondary),
                      ),
                    );
                  }
                  return ListView.builder(
                    shrinkWrap: true,
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 20),
                    itemCount: entries.length,
                    itemBuilder: (context, index) {
                      final entry = entries[index];
                      return _ReminderTile(
                        entry: entry,
                        weekDaysText: _weekDaysText(entry.reminder),
                        onDelete: () => _deleteReminder(context, entry),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReminderTile extends StatelessWidget {
  final _ReminderEntry entry;
  final String weekDaysText;
  final VoidCallback onDelete;

  const _ReminderTile({
    required this.entry,
    required this.weekDaysText,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final habit = entry.habit;
    final reminder = entry.reminder;
    final imagePath = habit.effectiveImagePath;
    final iconColor = habit.iconColor ?? AppColors.neonGreen;
    final isAlarm = reminder.type == 'Alarma';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(AppConstants.cardRadius),
        border: Border.all(color: AppColors.borderDark),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 40,
            height: 40,
            child: imagePath != null
                ? HabitImageAvatar(imagePath: imagePath, size: 40)
                : CircleAvatar(
                    radius: 20,
                    backgroundColor: iconColor.withValues(alpha: 0.12),
                    child: Icon(
                      habit.effectiveIcon,
                      color: iconColor,
                      size: 20,
                    ),
                  ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  habit.title,
                  style: textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Icon(
                      isAlarm
                          ? Icons.alarm_rounded
                          : Icons.notifications_none_rounded,
                      size: 14,
                      color: isAlarm ? AppColors.neonGreen : AppColors.textSecondary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${reminder.timeText} · ${reminder.type}',
                      style: textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  weekDaysText,
                  style: textTheme.bodySmall?.copyWith(
                    color: AppColors.textMuted,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: onDelete,
            icon: const Icon(
              Icons.delete_outline_rounded,
              color: AppColors.danger,
              size: 22,
            ),
            tooltip: 'Eliminar recordatorio',
          ),
        ],
      ),
    );
  }
}
