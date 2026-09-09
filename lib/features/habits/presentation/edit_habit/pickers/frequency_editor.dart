import 'package:flutter/material.dart';
import 'package:sunhabit/core/theme/app_colors.dart';

Future<void> showFrequencyEditor(
  BuildContext context, {
  required String frequency,
  required List<bool> weekDays,
  required List<int> monthDays,
  required int timesPerPeriod,
  required String periodType,
  required int repeatInterval,
  required List<String> frequencies,
  required List<String> periodTypes,
  required Future<void> Function() onAddMonthDay,
  required void Function(String frequency) onFrequencyChanged,
  required void Function(int index, bool selected) onWeekDayToggled,
  required void Function(int day) onMonthDayRemoved,
  required void Function(int times) onTimesPerPeriodChanged,
  required void Function(String period) onPeriodTypeChanged,
  required void Function(int days) onRepeatIntervalChanged,
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
        var localFrequency = frequency;
        var localWeekDays = List<bool>.from(weekDays);
        var localMonthDays = List<int>.from(monthDays);
        var localTimesPerPeriod = timesPerPeriod;
        var localPeriodType = periodType;
        var localRepeatInterval = repeatInterval;

        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Frecuencia', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 12),
              ...frequencies.map((f) => ListTile(
                    title: Text(f),
                    trailing: localFrequency == f
                        ? const Icon(Icons.check, color: AppColors.neonGreen)
                        : null,
                    onTap: () {
                      setModalState(() => localFrequency = f);
                      onFrequencyChanged(f);
                    },
                  )),
              if (localFrequency == 'Días exactos de la semana') ...[
                const SizedBox(height: 12),
                const Text('Días de la semana'),
                const SizedBox(height: 8),
                ToggleButtons(
                  isSelected: localWeekDays,
                  onPressed: (index) {
                    final selected = !localWeekDays[index];
                    setModalState(() => localWeekDays[index] = selected);
                    onWeekDayToggled(index, selected);
                  },
                  borderRadius: BorderRadius.circular(8),
                  selectedColor: const Color(0xFF152000),
                  fillColor: AppColors.neonGreen,
                  color: AppColors.textSecondary,
                  children: const ['L', 'M', 'X', 'J', 'V', 'S', 'D']
                      .map((d) => Padding(
                            padding: EdgeInsets.symmetric(horizontal: 12),
                            child: Text(d),
                          ))
                      .toList(),
                ),
              ],
              if (localFrequency == 'Días específicos del mes') ...[
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  children: <Widget>[
                    ...localMonthDays.map((d) => Chip(
                          label: Text(d.toString()),
                          onDeleted: () {
                            setModalState(() {
                              localMonthDays.remove(d);
                            });
                            onMonthDayRemoved(d);
                          },
                        )),
                    ActionChip(
                      avatar: const Icon(Icons.add, color: AppColors.neonGreen),
                      label: const Text('Agregar'),
                      onPressed: () async {
                        await onAddMonthDay();
                        setModalState(() {
                          localMonthDays = List<int>.from(monthDays);
                        });
                      },
                    ),
                  ],
                ),
              ],
              if (localFrequency == 'Algunas veces por período') ...[
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: 'Veces'),
                        controller: TextEditingController(text: localTimesPerPeriod.toString())
                          ..selection = TextSelection.collapsed(offset: localTimesPerPeriod.toString().length),
                        onChanged: (v) {
                          final n = int.tryParse(v) ?? 1;
                          setModalState(() => localTimesPerPeriod = n);
                          onTimesPerPeriodChanged(n);
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: InputDecorator(
                        decoration: const InputDecoration(labelText: 'Período'),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: localPeriodType,
                            isDense: true,
                            dropdownColor: AppColors.surfaceDark,
                            items: periodTypes
                                .map((p) =>
                                    DropdownMenuItem(value: p, child: Text(p)))
                                .toList(),
                            onChanged: (v) {
                              if (v == null) return;
                              setModalState(() => localPeriodType = v);
                              onPeriodTypeChanged(v);
                            },
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
              if (localFrequency == 'Repetir') ...[
                const SizedBox(height: 12),
                TextField(
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Repetir cada (días)'),
                  controller: TextEditingController(text: localRepeatInterval.toString())
                    ..selection = TextSelection.collapsed(offset: localRepeatInterval.toString().length),
                  onChanged: (v) {
                    final n = int.tryParse(v) ?? 1;
                    setModalState(() => localRepeatInterval = n);
                    onRepeatIntervalChanged(n);
                  },
                ),
              ],
            ],
          ),
        );
      },
    ),
  );
}
