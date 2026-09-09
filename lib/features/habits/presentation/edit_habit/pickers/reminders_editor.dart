import 'package:flutter/material.dart';
import 'package:sunhabit/core/theme/app_colors.dart';
import 'package:sunhabit/core/theme/app_decorations.dart';
import 'package:sunhabit/features/habits/data/habit_model.dart';

Future<void> showRemindersEditor(
  BuildContext context, {
  required List<Reminder> reminders,
  required Future<void> Function() onAdd,
  required Future<void> Function(int) onEdit,
  required void Function(int) onToggle,
  required void Function(int) onRemove,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.surfaceElevated,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (context) => StatefulBuilder(
      builder: (context, setModalState) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Recordatorios', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 12),
              ...reminders.asMap().entries.map((entry) {
                final index = entry.key;
                final r = entry.value;
                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: AppDecorations.card,
                  child: Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () async {
                            await onEdit(index);
                            setModalState(() {});
                          },
                          child: Row(
                            children: [
                              const Icon(Icons.access_time,
                                  color: AppColors.neonGreen, size: 20),
                              const SizedBox(width: 8),
                              Text(r.timeText,
                                  style: Theme.of(context).textTheme.titleMedium),
                            ],
                          ),
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                          onToggle(index);
                          setModalState(() {});
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceDark,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(r.type,
                              style: Theme.of(context).textTheme.bodySmall),
                        ),
                      ),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: () {
                          onRemove(index);
                          setModalState(() {});
                        },
                        child: const Icon(Icons.close,
                            color: AppColors.textSecondary, size: 20),
                      ),
                    ],
                  ),
                );
              }),
              const SizedBox(height: 6),
              GestureDetector(
                onTap: () async {
                  await onAdd();
                  setModalState(() {});
                },
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: AppDecorations.card,
                  child: const Row(
                    children: [
                      Icon(Icons.add, color: AppColors.neonGreen),
                      SizedBox(width: 10),
                      Text('Agregar recordatorio'),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    ),
  );
}
