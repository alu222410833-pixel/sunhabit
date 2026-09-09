import 'package:flutter/material.dart';
import 'package:sunhabit/core/services/audio_extractor_service.dart';
import 'package:sunhabit/core/theme/app_colors.dart';
import 'package:sunhabit/core/theme/app_decorations.dart';
import 'package:sunhabit/features/alarms/presentation/widgets/audio_trim_dialog.dart';
import 'package:sunhabit/features/alarms/presentation/widgets/sound_picker_tile.dart';
import 'package:sunhabit/features/alarms/presentation/widgets/sound_source_picker.dart';
import 'package:sunhabit/features/categories/data/category_model.dart';
import 'package:sunhabit/features/habits/data/habit_model.dart';

Future<void> showRemindersEditor(
  BuildContext context, {
  required List<Reminder> reminders,
  required Category? category,
  required void Function(List<Reminder> updated) onRemindersChanged,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.surfaceElevated,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (context) {
      // Copia mutable local de los recordatorios. De este modo los cambios
      // dentro del bottom sheet (eliminar, editar, añadir) se reflejan
      // inmediatamente en la UI sin depender de que el padre reconstruya.
      List<Reminder> localReminders = List<Reminder>.from(reminders);

      return StatefulBuilder(
        builder: (context, setModalState) {
          final textTheme = Theme.of(context).textTheme;

          void notifyParentAndRebuild() {
            onRemindersChanged(List<Reminder>.from(localReminders));
            setModalState(() {});
          }

          void updateReminder(int index, Reminder updated) {
            localReminders[index] = updated;
            notifyParentAndRebuild();
          }

          void removeReminder(int index) {
            localReminders.removeAt(index);
            notifyParentAndRebuild();
          }

          Future<void> addReminder() async {
            final picked = await showTimePicker(
              context: context,
              initialTime: TimeOfDay.now(),
              builder: (context, child) => Theme(
                data: Theme.of(context).copyWith(
                  colorScheme: const ColorScheme.dark(
                    primary: AppColors.neonGreen,
                    onPrimary: Color(0xFF152000),
                    surface: AppColors.surfaceElevated,
                    onSurface: AppColors.textPrimary,
                  ),
                ),
                child: child!,
              ),
            );
            if (picked == null) return;
            localReminders.add(Reminder(hour: picked.hour, minute: picked.minute));
            notifyParentAndRebuild();
          }

          Future<void> editTime(int index) async {
            final r = localReminders[index];
            final picked = await showTimePicker(
              context: context,
              initialTime: TimeOfDay(hour: r.hour, minute: r.minute),
              builder: (context, child) => Theme(
                data: Theme.of(context).copyWith(
                  colorScheme: const ColorScheme.dark(
                    primary: AppColors.neonGreen,
                    onPrimary: Color(0xFF152000),
                    surface: AppColors.surfaceElevated,
                    onSurface: AppColors.textPrimary,
                  ),
                ),
                child: child!,
              ),
            );
            if (picked == null) return;
            updateReminder(
              index,
              r.copyWith(hour: picked.hour, minute: picked.minute),
            );
          }

          Future<void> pickAlarmSound(int index) async {
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

              updateReminder(
                index,
                localReminders[index].copyWith(
                  type: 'Alarma',
                  soundPath: finalPath,
                  audioStartSeconds: trimResult?.startSeconds ?? 0,
                  audioDurationSeconds: trimResult?.durationSeconds ?? 30,
                ),
              );
            }
          }

          Future<void> trimAlarmSound(int index) async {
            final reminder = localReminders[index];
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

              updateReminder(
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

          void removeAlarmSound(int index) {
            updateReminder(
              index,
              localReminders[index].copyWith(
                soundPath: null,
                audioStartSeconds: null,
                audioDurationSeconds: null,
              ),
            );
          }

          void toggleReminderDay(int index, int dayIndex) {
            final reminder = localReminders[index];
            final current = List<bool>.from(
              reminder.weekDays ?? List<bool>.filled(7, true),
            );
            if (current[dayIndex] && current.where((s) => s).length == 1) return;

            current[dayIndex] = !current[dayIndex];
            final allSelected = current.every((s) => s);
            updateReminder(
              index,
              reminder.copyWith(weekDays: allSelected ? null : current),
            );
          }

          Widget buildWeekDayPicker(int index, Reminder reminder) {
            const labels = ['L', 'M', 'X', 'J', 'V', 'S', 'D'];
            final weekDays = reminder.weekDays ?? List<bool>.filled(7, true);

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Días activos',
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
                      onTap: () => toggleReminderDay(index, i),
                      child: Container(
                        width: 32,
                        height: 32,
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

          return Container(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.82,
            ),
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.textMuted,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text('Recordatorios', style: textTheme.titleLarge),
                const SizedBox(height: 12),
                Expanded(
                  child: ListView(
                    children: [
                      ...localReminders.asMap().entries.map((entry) {
                        final index = entry.key;
                        final reminder = entry.value;
                        final isAlarm = reminder.type == 'Alarma';

                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(12),
                          decoration: AppDecorations.card,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Row(
                                children: [
                                  GestureDetector(
                                    onTap: () => editTime(index),
                                    child: Row(
                                      children: [
                                        const Icon(
                                          Icons.access_time,
                                          color: AppColors.neonGreen,
                                          size: 20,
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          reminder.timeText,
                                          style: textTheme.titleMedium?.copyWith(
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const Spacer(),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8),
                                    decoration: BoxDecoration(
                                      color: AppColors.surfaceDark,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: DropdownButton<String>(
                                      value: reminder.type,
                                      underline: const SizedBox.shrink(),
                                      isDense: true,
                                      dropdownColor: AppColors.surfaceElevated,
                                      items: const [
                                        DropdownMenuItem(
                                          value: 'Notificación',
                                          child: Text('Notificación', style: TextStyle(fontSize: 13)),
                                        ),
                                        DropdownMenuItem(
                                          value: 'Alarma',
                                          child: Text('Alarma', style: TextStyle(fontSize: 13)),
                                        ),
                                      ],
                                      onChanged: (val) {
                                        if (val == null) return;
                                        updateReminder(
                                          index,
                                          reminder.copyWith(type: val),
                                        );
                                      },
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  GestureDetector(
                                    onTap: () => removeReminder(index),
                                    child: Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: AppColors.surfaceDark,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: const Icon(
                                        Icons.close,
                                        color: AppColors.textSecondary,
                                        size: 20,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              if (isAlarm) ...[
                                const SizedBox(height: 10),
                                SoundPickerTile(
                                  displayLabel: reminder.soundFileName.isNotEmpty
                                      ? reminder.soundFileName
                                      : (category?.defaultSoundFileName.isNotEmpty == true
                                          ? '${category!.defaultSoundFileName} (de categoría)'
                                          : 'Sonido del sistema'),
                                  fragmentText: reminder.audioFragmentText ??
                                      category?.defaultAudioFragmentText,
                                  hasSound: reminder.soundPath != null ||
                                      category?.defaultSoundPath != null,
                                  canRemove: reminder.soundPath != null,
                                  onPick: () => pickAlarmSound(index),
                                  onTrim: () => trimAlarmSound(index),
                                  onRemove: reminder.soundPath != null
                                      ? () => removeAlarmSound(index)
                                      : null,
                                ),
                              ],
                              const SizedBox(height: 10),
                              buildWeekDayPicker(index, reminder),
                            ],
                          ),
                        );
                      }),
                      GestureDetector(
                        onTap: addReminder,
                        child: Container(
                          padding: const EdgeInsets.all(14),
                          decoration: AppDecorations.card,
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.add, color: AppColors.neonGreen),
                              SizedBox(width: 8),
                              Text(
                                'Agregar recordatorio',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      );
    },
  );
}
