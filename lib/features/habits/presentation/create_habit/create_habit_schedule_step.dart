import 'package:flutter/material.dart';
import 'package:sunhabit/core/services/audio_extractor_service.dart';
import 'package:sunhabit/core/theme/app_colors.dart';
import 'package:sunhabit/core/theme/app_decorations.dart';
import 'package:sunhabit/features/alarms/presentation/widgets/audio_trim_dialog.dart';
import 'package:sunhabit/features/alarms/presentation/widgets/sound_picker_tile.dart';
import 'package:sunhabit/features/alarms/presentation/widgets/sound_source_picker.dart';
import 'package:sunhabit/features/categories/data/category_model.dart';
import 'package:sunhabit/features/habits/data/habit_model.dart';

class CreateHabitScheduleStep extends StatelessWidget {
  final DateTime startDate;
  final DateTime? endDate;
  final List<Reminder> reminders;
  final Category? category;
  final String? frequency;
  final ValueChanged<DateTime> onStartDateChanged;
  final ValueChanged<DateTime?> onEndDateChanged;
  final ValueChanged<List<Reminder>> onRemindersChanged;

  const CreateHabitScheduleStep({
    super.key,
    required this.startDate,
    required this.endDate,
    required this.reminders,
    this.category,
    this.frequency,
    required this.onStartDateChanged,
    required this.onEndDateChanged,
    required this.onRemindersChanged,
  });

  Future<void> _pickDate(BuildContext context, DateTime initial,
      ValueChanged<DateTime> onPicked) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: AppColors.neonGreen,
              onPrimary: Color(0xFF152000),
              surface: AppColors.surfaceElevated,
              onSurface: AppColors.textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) onPicked(picked);
  }

  Future<TimeOfDay?> _pickTime(BuildContext context,
      {required TimeOfDay initial}) async {
    return showTimePicker(
      context: context,
      initialTime: initial,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: AppColors.neonGreen,
              onPrimary: Color(0xFF152000),
              surface: AppColors.surfaceElevated,
              onSurface: AppColors.textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );
  }

  void _addReminder(BuildContext context) async {
    final now = TimeOfDay.now();
    final picked = await _pickTime(context, initial: now);
    if (picked == null) return;
    onRemindersChanged([
      ...reminders,
      Reminder(hour: picked.hour, minute: picked.minute),
    ]);
  }

  void _editReminderTime(BuildContext context, int index) async {
    final reminder = reminders[index];
    final initial = TimeOfDay(hour: reminder.hour, minute: reminder.minute);
    final picked = await _pickTime(context, initial: initial);
    if (picked == null) return;
    _updateReminder(index, reminder.copyWith(hour: picked.hour, minute: picked.minute));
  }

  void _updateReminderType(int index, String type) {
    _updateReminder(index, reminders[index].copyWith(type: type));
  }

  void _updateReminder(int index, Reminder updated) {
    final list = List<Reminder>.from(reminders);
    list[index] = updated;
    onRemindersChanged(list);
  }

  void _removeReminder(int index) {
    onRemindersChanged(List<Reminder>.from(reminders)..removeAt(index));
  }

  Future<void> _pickAlarmSound(BuildContext context, int index) async {
    final path = await SoundSourcePicker.pick(context);
    if (path == null || path.isEmpty) return;

    if (context.mounted) {
      final trimResult = await AudioTrimDialog.show(
        context,
        soundPath: path,
        initialStartSeconds: 0,
        initialDurationSeconds: 30,
      );

      String finalPath = path;
      if (trimResult != null &&
          (trimResult.startSeconds > 0 || trimResult.durationSeconds > 0)) {
        final trimmed = await AudioExtractorService().trimAudio(
          path,
          startSeconds: trimResult.startSeconds,
          durationSeconds: trimResult.durationSeconds,
        );
        if (trimmed != null && trimmed.isNotEmpty) {
          finalPath = trimmed;
        }
      }

      _updateReminder(
        index,
        reminders[index].copyWith(
          type: 'Alarma',
          soundPath: finalPath,
          audioStartSeconds: trimResult?.startSeconds ?? 0,
          audioDurationSeconds: trimResult?.durationSeconds ?? 30,
        ),
      );
    }
  }

  Future<void> _trimAlarmSound(BuildContext context, int index) async {
    final reminder = reminders[index];
    final path = reminder.soundPath ?? category?.defaultSoundPath;
    if (path == null || path.isEmpty) return;

    final trimResult = await AudioTrimDialog.show(
      context,
      soundPath: path,
      initialStartSeconds: reminder.audioStartSeconds ??
          category?.defaultAudioStartSeconds ??
          0,
      initialDurationSeconds: reminder.audioDurationSeconds ??
          category?.defaultAudioDurationSeconds ??
          30,
    );

    if (trimResult != null) {
      String finalPath = path;
      final trimmed = await AudioExtractorService().trimAudio(
        path,
        startSeconds: trimResult.startSeconds,
        durationSeconds: trimResult.durationSeconds,
      );
      if (trimmed != null && trimmed.isNotEmpty) {
        finalPath = trimmed;
      }

      _updateReminder(
        index,
        reminder.copyWith(
          type: 'Alarma',
          soundPath: finalPath,
          audioStartSeconds: trimResult.startSeconds,
          audioDurationSeconds: trimResult.durationSeconds,
        ),
      );
    }
  }

  void _removeAlarmSound(int index) {
    _updateReminder(
      index,
      reminders[index].copyWith(
        soundPath: null,
        audioStartSeconds: null,
        audioDurationSeconds: null,
      ),
    );
  }

  void _toggleReminderDay(int index, int dayIndex) {
    final reminder = reminders[index];
    final current = List<bool>.from(
      reminder.weekDays ?? List<bool>.filled(7, true),
    );
    if (current[dayIndex] && current.where((s) => s).length == 1) return;

    current[dayIndex] = !current[dayIndex];
    final allSelected = current.every((s) => s);
    _updateReminder(
      index,
      reminder.copyWith(weekDays: allSelected ? null : current),
    );
  }

  Widget _buildWeekDayPicker(BuildContext context, int index, Reminder reminder) {
    const labels = ['L', 'M', 'X', 'J', 'V', 'S', 'D'];
    final textTheme = Theme.of(context).textTheme;
    final weekDays = reminder.weekDays ?? List<bool>.filled(7, true);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Días',
          style: textTheme.bodySmall?.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 6),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(7, (i) {
            final selected = weekDays[i];
            return GestureDetector(
              onTap: () => _toggleReminderDay(index, i),
              child: Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: selected
                      ? AppColors.neonGreen
                      : AppColors.surfaceDark,
                  border: Border.all(
                    color: selected
                        ? AppColors.neonGreen
                        : AppColors.textMuted,
                  ),
                ),
                alignment: Alignment.center,
                child: Text(
                  labels[i],
                  style: textTheme.bodySmall?.copyWith(
                    color: selected
                        ? const Color(0xFF152000)
                        : AppColors.textMuted,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            );
          }),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final start = '${startDate.day}/${startDate.month}/${startDate.year}';
    final end = endDate != null
        ? '${endDate!.day}/${endDate!.month}/${endDate!.year}'
        : 'Sin fecha final';

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _DateTile(
            label: 'Inicio',
            value: start,
            onTap: () => _pickDate(context, startDate, onStartDateChanged),
          ),
          const SizedBox(height: 12),
          _DateTile(
            label: 'Final (opcional)',
            value: end,
            onTap: () => _pickDate(
              context,
              endDate ?? DateTime.now().add(const Duration(days: 30)),
              (date) => onEndDateChanged(date),
            ),
          ),
          const SizedBox(height: 22),
          Text('Recordatorios', style: textTheme.titleMedium),
          const SizedBox(height: 10),
          ...reminders.asMap().entries.map((entry) {
            final index = entry.key;
            final reminder = entry.value;
            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: AppDecorations.card,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      GestureDetector(
                        onTap: () => _editReminderTime(context, index),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.access_time,
                              color: AppColors.neonGreen,
                              size: 22,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              reminder.timeText,
                              style: textTheme.titleMedium,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _TypeDropdown(
                          value: reminder.type,
                          onChanged: (type) {
                            if (type != null) _updateReminderType(index, type);
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: () => _removeReminder(index),
                        child: const Icon(
                          Icons.close,
                          color: AppColors.textSecondary,
                          size: 20,
                        ),
                      ),
                    ],
                  ),
                  if (frequency == 'Días exactos de la semana') ...[
                    const SizedBox(height: 10),
                    _buildWeekDayPicker(context, index, reminder),
                  ],
                  if (reminder.type == 'Alarma') ...[
                    const SizedBox(height: 10),
                    Builder(builder: (context) {
                      final hasCustomSound = reminder.soundFileName.isNotEmpty;
                      final hasCategorySound =
                          category?.defaultSoundFileName.isNotEmpty ?? false;
                      final hasAnySound = hasCustomSound || hasCategorySound;
                      String displayLabel;
                      if (hasCustomSound) {
                        displayLabel = reminder.soundFileName;
                      } else if (hasCategorySound) {
                        displayLabel =
                            '${category!.defaultSoundFileName} (De la categoría)';
                      } else {
                        displayLabel = 'Predeterminado de la app';
                      }
                      return SoundPickerTile(
                        displayLabel: displayLabel,
                        fragmentText: reminder.audioFragmentText ??
                            category?.defaultAudioFragmentText,
                        hasSound: hasAnySound,
                        canRemove: hasCustomSound,
                        onPick: () => _pickAlarmSound(context, index),
                        onTrim: () => _trimAlarmSound(context, index),
                        onRemove: () => _removeAlarmSound(index),
                      );
                    }),
                  ],
                ],
              ),
            );
          }),
          const SizedBox(height: 6),
          GestureDetector(
            onTap: () => _addReminder(context),
            child: Container(
              decoration: AppDecorations.card,
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  const Icon(
                    Icons.add,
                    color: AppColors.neonGreen,
                    size: 22,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'Agregar recordatorio',
                    style: textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DateTile extends StatelessWidget {
  final String label;
  final String value;
  final VoidCallback onTap;

  const _DateTile({
    required this.label,
    required this.value,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: AppDecorations.card,
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.calendar_today_rounded,
              color: AppColors.neonGreen,
            ),
          ],
        ),
      ),
    );
  }
}

class _TypeDropdown extends StatelessWidget {
  final String value;
  final ValueChanged<String?> onChanged;

  const _TypeDropdown({
    required this.value,
    required this.onChanged,
  });

  static const List<String> _types = ['Notificación', 'Alarma'];

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(8),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          dropdownColor: AppColors.surfaceDark,
          style: textTheme.bodyMedium,
          iconEnabledColor: AppColors.textSecondary,
          isDense: true,
          items: _types
              .map(
                (t) => DropdownMenuItem(
                  value: t,
                  child: Text(t, style: textTheme.bodyMedium),
                ),
              )
              .toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }
}
