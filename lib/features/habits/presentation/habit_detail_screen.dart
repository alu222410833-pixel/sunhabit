import 'package:flutter/material.dart';
import 'package:sunhabit/core/services/reminder_service.dart';
import 'package:sunhabit/core/theme/app_colors.dart';
import 'package:sunhabit/core/theme/app_decorations.dart';
import 'package:sunhabit/features/habits/data/habit_log_model.dart';
import 'package:sunhabit/features/habits/presentation/widgets/habit_visuals.dart';
import 'package:sunhabit/features/habits/data/habit_model.dart';
import 'package:sunhabit/features/habits/data/habits_repository.dart';
import 'package:sunhabit/features/habits/domain/habit_streak_calculator.dart';
import 'package:sunhabit/features/habits/presentation/edit_habit_screen.dart';
import 'package:sunhabit/features/habits/presentation/habit_completion_bottom_sheet.dart';

part 'detail/habit_detail_body.dart';
part 'detail/habit_hero.dart';
part 'detail/habit_stats_card.dart';
part 'detail/habit_daily_progress_card.dart';
part 'detail/habit_streaks_card.dart';
part 'detail/habit_history_section.dart';
part 'detail/habit_empty_state.dart';
part 'detail/habit_actions.dart';
part 'detail/habit_calendar_sheet.dart';

class HabitDetailScreen extends StatefulWidget {
  final String habitId;

  const HabitDetailScreen({super.key, required this.habitId});

  @override
  State<HabitDetailScreen> createState() => _HabitDetailScreenState();
}

class _HabitDetailScreenState extends State<HabitDetailScreen> {
  final _repository = HabitsRepository();

  Habit? get _habit => _repository.getHabitById(widget.habitId);

  Future<void> _delete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar hábito'),
        content: const Text(
          '¿Seguro que quieres eliminar este hábito? Esta acción no se puede deshacer.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Eliminar',
              style: TextStyle(color: Colors.redAccent),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    final habit = _habit;
    if (habit != null) {
      await ReminderService.instance.cancelHabit(habit);
    }
    _repository.deleteHabit(widget.habitId);
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _repository,
      builder: (context, _) {
        final habit = _habit;

        if (habit == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Hábito')),
            body: const Center(child: Text('Hábito no encontrado')),
          );
        }

        final logs = _repository.getHabitLogs(widget.habitId);
        final iconColor = habit.iconColor ?? AppColors.neonGreen;

        return DefaultTabController(
          length: 3,
          child: Scaffold(
            backgroundColor: Colors.transparent,
            appBar: AppBar(
              title: Text(habit.title),
              bottom: const TabBar(
                tabs: [
                  Tab(text: 'Calendario'),
                  Tab(text: 'Estadísticas'),
                  Tab(text: 'Editar'),
                ],
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: AppColors.danger),
                  onPressed: _delete,
                ),
              ],
            ),
            body: DecoratedBox(
              decoration: AppDecorations.pageBackground,
              child: SafeArea(
                child: TabBarView(
                  children: [
                    _HabitCalendarSheet(
                      habit: habit,
                      logs: logs,
                      iconColor: iconColor,
                    ),
                    _HabitDetailBody(
                      habit: habit,
                      logs: logs,
                    ),
                    EditHabitScreen(
                      habit: habit,
                      isEmbedded: true,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
