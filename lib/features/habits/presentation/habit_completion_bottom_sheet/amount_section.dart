import 'package:flutter/material.dart';
import 'package:sunhabit/core/theme/app_colors.dart';
import 'package:sunhabit/features/habits/data/habit_model.dart';
import 'package:sunhabit/features/habits/data/habits_repository.dart';
import 'package:sunhabit/features/habits/presentation/habit_completion_bottom_sheet/action_button.dart';
import 'package:sunhabit/features/habits/presentation/habit_completion_bottom_sheet/counter_button.dart';

/// Panel para hábitos con cantidad medible (current/target).
class AmountSection extends StatefulWidget {
  final Habit habit;
  final bool readOnly;

  const AmountSection({super.key, required this.habit, this.readOnly = false});

  @override
  State<AmountSection> createState() => AmountSectionState();
}

class AmountSectionState extends State<AmountSection> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: '${widget.habit.current ?? 0}');
  }

  @override
  void didUpdateWidget(covariant AmountSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    _controller.text = '${widget.habit.current ?? 0}';
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// Guarda el valor exacto escrito en el campo numérico, quita el foco
  /// del teclado y cierra el bottom sheet.
  void _saveFromInput() {
    FocusManager.instance.primaryFocus?.unfocus();
    final value = int.tryParse(_controller.text) ?? 0;
    HabitsRepository().setHabitAmount(widget.habit.id, value);
    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final current = widget.habit.current ?? 0;
    final target = widget.habit.target ?? 0;

    return Column(
      children: [
        Text(
          '$current / $target ${widget.habit.unit ?? ''}',
          style: theme.textTheme.headlineSmall,
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CounterButton(
              icon: Icons.remove_rounded,
              onTap: widget.readOnly
                  ? null
                  : () => HabitsRepository().incrementHabitAmount(
                        widget.habit.id,
                        -1,
                      ),
            ),
            const SizedBox(width: 12),
            SizedBox(
              width: 120,
              child: TextField(
                controller: _controller,
                enabled: !widget.readOnly,
                keyboardType: TextInputType.number,
                textAlign: TextAlign.center,
                style: theme.textTheme.titleLarge,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: AppColors.surfaceDark,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
                onSubmitted: (_) => _saveFromInput(),
                onEditingComplete: () {
                  // Si el usuario pulsa la tecla de acción del teclado, también
                  // guarda y cierra el sheet.
                  _saveFromInput();
                },
              ),
            ),
            const SizedBox(width: 12),
            CounterButton(
              icon: Icons.add_rounded,
              onTap: widget.readOnly
                  ? null
                  : () => HabitsRepository().incrementHabitAmount(
                        widget.habit.id,
                        1,
                      ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        ActionButton(
          label: 'Guardar',
          icon: Icons.save_rounded,
          // Se usa un callback envolvente para quitar el foco antes de guardar,
          // evitando que el teclado intercepte el tap.
          onTap: widget.readOnly
              ? null
              : () {
                  FocusManager.instance.primaryFocus?.unfocus();
                  _saveFromInput();
                },
        ),
      ],
    );
  }
}
