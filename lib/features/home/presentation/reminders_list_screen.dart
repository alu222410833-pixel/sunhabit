import 'package:flutter/material.dart';
import 'package:sunhabit/core/services/reminder_service.dart';
import 'package:sunhabit/core/theme/app_colors.dart';
import 'package:sunhabit/core/theme/app_decorations.dart';
import 'package:sunhabit/features/habits/data/habit_model.dart';
import 'package:sunhabit/features/habits/data/habits_repository.dart';
import 'package:sunhabit/features/habits/presentation/widgets/habit_visuals.dart';

class _ReminderEntry {
  final Habit habit;
  final int reminderIndex;
  final Reminder reminder;

  const _ReminderEntry(this.habit, this.reminderIndex, this.reminder);

  int get minutes => reminder.hour * 60 + reminder.minute;
}

/// Pantalla con la lista de TODOS los recordatorios de todos los hábitos,
/// ordenados por hora. Permite ver y eliminar cada uno.
class RemindersListScreen extends StatelessWidget {
  const RemindersListScreen({super.key});

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

  Future<void> _deleteReminder(
    BuildContext context,
    _ReminderEntry entry,
  ) async {
    final habit = entry.habit;
    final updatedReminders = List<Reminder>.from(habit.reminders)
      ..removeAt(entry.reminderIndex);
    final updated = habit.copyWith(reminders: updatedReminders);
    final repository = HabitsRepository();
    // Cancelar con el hábito ANTERIOR: los IDs de alarma se derivan del
    // índice del recordatorio, así que cancelar con la lista acortada
    // dejaría huérfanas las programaciones del índice eliminado.
    await ReminderService.instance.cancelHabit(habit);
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

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: DecoratedBox(
        decoration: AppDecorations.pageBackground,
        child: SafeArea(
          child: ListenableBuilder(
            listenable: HabitsRepository(),
            builder: (context, _) {
              final entries = _collect(HabitsRepository());

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(context, textTheme, entries.length),
                  Expanded(
                    child: entries.isEmpty
                        ? _buildEmptyState(textTheme)
                        : ListView.builder(
                            padding: const EdgeInsets.fromLTRB(22, 8, 22, 24),
                            itemCount: entries.length,
                            itemBuilder: (context, index) {
                              final entry = entries[index];
                              return _ReminderTile(
                                entry: entry,
                                onDelete: () =>
                                    _deleteReminder(context, entry),
                              );
                            },
                          ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(
    BuildContext context,
    TextTheme textTheme,
    int count,
  ) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 18, 22, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
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
                  'Recordatorios',
                  style: textTheme.displaySmall,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '$count ${count == 1 ? 'recordatorio' : 'recordatorios'}',
            style: textTheme.bodyMedium?.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(TextTheme textTheme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: AppDecorations.iconGlow(AppColors.neonGreen),
              child: const Icon(
                Icons.notifications_off_outlined,
                color: AppColors.neonGreen,
                size: 56,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Sin recordatorios',
              style: textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Los recordatorios que configures en tus hábitos aparecerán aquí.',
              style: textTheme.bodyMedium?.copyWith(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _ReminderTile extends StatelessWidget {
  final _ReminderEntry entry;
  final VoidCallback onDelete;

  const _ReminderTile({
    required this.entry,
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
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: AppDecorations.card,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: 62,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  reminder.timeText,
                  style: textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: isAlarm
                        ? AppColors.neonGreen
                        : AppColors.textPrimary,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
                const SizedBox(height: 6),
                _TypeBadge(isAlarm: isAlarm),
              ],
            ),
          ),
          const SizedBox(width: 10),
          SizedBox(
            width: 42,
            height: 42,
            child: imagePath != null
                ? HabitImageAvatar(imagePath: imagePath, size: 42)
                : CircleAvatar(
                    radius: 21,
                    backgroundColor: iconColor.withValues(alpha: 0.12),
                    child: Icon(
                      habit.effectiveIcon,
                      color: iconColor,
                      size: 21,
                    ),
                  ),
          ),
          const SizedBox(width: 10),
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
                const SizedBox(height: 6),
                _WeekDayDots(weekDays: reminder.weekDays),
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

class _TypeBadge extends StatelessWidget {
  final bool isAlarm;

  const _TypeBadge({required this.isAlarm});

  @override
  Widget build(BuildContext context) {
    final color = isAlarm ? AppColors.neonGreen : AppColors.textMuted;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: isAlarm ? 0.12 : 0.08),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isAlarm ? Icons.alarm_rounded : Icons.notifications_none_rounded,
            size: 11,
            color: color,
          ),
          const SizedBox(width: 3),
          Text(
            isAlarm ? 'Alarma' : 'Aviso',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w600,
                ),
          ),
        ],
      ),
    );
  }
}

/// Siete puntos L→D que resaltan los días en que suena el recordatorio.
/// Si [weekDays] es `null`, todos aparecen activos ("todos los días").
class _WeekDayDots extends StatelessWidget {
  final List<bool>? weekDays;

  const _WeekDayDots({required this.weekDays});

  static const _labels = ['L', 'M', 'X', 'J', 'V', 'S', 'D'];

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(7, (i) {
        final active = weekDays == null ||
            weekDays!.isEmpty ||
            (i < weekDays!.length && weekDays![i]);
        return Padding(
          padding: const EdgeInsets.only(right: 4),
          child: Container(
            width: 17,
            height: 17,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: active
                  ? AppColors.neonGreen.withValues(alpha: 0.14)
                  : Colors.transparent,
              border: Border.all(
                color: active
                    ? AppColors.neonGreen.withValues(alpha: 0.6)
                    : AppColors.borderDark,
              ),
            ),
            child: Text(
              _labels[i],
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    fontSize: 8.5,
                    fontWeight: FontWeight.w700,
                    color: active
                        ? AppColors.neonGreen
                        : AppColors.textMuted,
                  ),
            ),
          ),
        );
      }),
    );
  }
}
