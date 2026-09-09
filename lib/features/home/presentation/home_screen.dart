import 'dart:async';

import 'package:flutter/material.dart';
import 'package:sunhabit/core/services/habit_execution_service.dart';
import 'package:sunhabit/core/services/reminder_service.dart';
import 'package:sunhabit/core/theme/app_colors.dart';
import 'package:sunhabit/core/theme/app_decorations.dart';
import 'package:sunhabit/features/habits/data/habit_model.dart';
import 'package:sunhabit/features/habits/data/habits_repository.dart';
import 'package:sunhabit/features/habits/presentation/create_habit/create_habit_dialog.dart';
import 'package:sunhabit/features/habits/presentation/create_habit/express_habit_dialog.dart';
import 'package:sunhabit/features/habits/presentation/habit_completion_bottom_sheet.dart';
import 'package:sunhabit/features/home/presentation/widgets/home_bottom_nav.dart';
import 'package:sunhabit/features/home/presentation/widgets/home_date_row.dart';
import 'package:sunhabit/features/home/presentation/widgets/home_habit_tile.dart';
import 'package:sunhabit/features/home/presentation/widgets/home_summary_card.dart';

/// Pantalla principal de la aplicación.
///
/// Muestra el resumen del día, la fecha actual, la lista de hábitos
/// programados para el día seleccionado, un botón para crear hábitos y la
/// barra de navegación.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  /// Día cuyos hábitos se están visualizando. Por defecto, hoy.
  DateTime _selectedDate = DateTime.now();

  @override
  Widget build(BuildContext context) {
    final repository = HabitsRepository();

    return ListenableBuilder(
      listenable: Listenable.merge([repository, HabitExecutionService()]),
      builder: (context, _) {
        final theme = Theme.of(context);

        // Normaliza la fecha seleccionada a medianoche para comparar solo día.
        final selected = DateTime(
          _selectedDate.year,
          _selectedDate.month,
          _selectedDate.day,
        );

        // Determina si el día seleccionado es hoy. Solo hoy es editable;
        // otros días se muestran en modo solo visualización (histórico).
        final now = DateTime.now();
        final isToday = selected.year == now.year &&
            selected.month == now.month &&
            selected.day == now.day;

        // Hábitos programados para el día seleccionado, con el estado
        // proyectado desde los logs de ese día (o estado vivo si es hoy).
        final habits = repository.getHabitsForDate(selected);

        // Calcula las estadísticas del día.
        final completed = habits.where((habit) => habit.isCompleted).length;
        final pending = habits.length - completed;
        final percent = habits.isEmpty ? 0.0 : completed / habits.length;

        return Scaffold(
          backgroundColor: Colors.transparent,
          body: DecoratedBox(
            decoration: AppDecorations.pageBackground,
            child: SafeArea(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    _buildHeader(theme.textTheme),
                    HomeSummaryCard(
                      total: habits.length,
                      completed: completed,
                      pending: pending,
                      percent: percent,
                      textTheme: theme.textTheme,
                    ),
                    HomeDateRow(
                      textTheme: theme.textTheme,
                      selectedDate: _selectedDate,
                      onDateSelected: (date) =>
                          setState(() => _selectedDate = date),
                    ),
                    if (habits.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          vertical: 32,
                          horizontal: 24,
                        ),
                        child: Text(
                          isToday
                              ? 'No hay hábitos programados para hoy.'
                              : 'No hay hábitos programados para este día.',
                          style: theme.textTheme.bodyMedium,
                          textAlign: TextAlign.center,
                        ),
                      )
                    else
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 18),
                        itemCount: habits.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 9),
                        itemBuilder: (context, index) {
                          final habit = habits[index];
                          // Sí/No: toggle directo del check sin abrir el
                          // bottom sheet (solo si es hoy, que es editable).
                          // Otros tipos: abren el sheet (editable hoy,
                          // solo lectura otros días).
                          final VoidCallback? onTap;
                          if (!isToday) {
                            onTap = () => _openHabitCompletion(
                                  context,
                                  habit.id,
                                  readOnly: true,
                                  habit: habit,
                                );
                          } else if (habit.evaluationType ==
                              HabitEvaluationType.yesNo) {
                            onTap = () => HabitsRepository()
                                .setHabitYesNo(habit.id, !habit.isCompleted);
                          } else {
                            onTap = () =>
                                _openHabitCompletion(context, habit.id);
                          }
                          return HomeHabitTile(habit: habit, onTap: onTap);
                        },
                      ),
                    if (isToday) _buildActiveTimerBanner(theme),

                  ],
                ),
              ),
            ),
          ),
          bottomNavigationBar: HomeBottomNavBar(
            textTheme: theme.textTheme,
            onAddTap: () => _openCreateHabit(context),
          ),
        );
      },
    );
  }

  /// Abre el diálogo rápido de creación de hábito.
  ///
  /// Si el usuario cierra el diálogo sin guardar, se abre el formulario
  /// completo. Cuando se guarda, se añade el hábito y se programa su
  /// recordatorio.
  Future<void> _openCreateHabit(BuildContext context) async {
    final categories = HabitsRepository().getCategories();
    final result = await showDialog<Habit?>(
      context: context,
      builder: (dialogContext) => ExpressHabitDialog(categories: categories),
    );

    if (result == null && context.mounted) {
      final detailedResult = await showDialog<Habit?>(
        context: context,
        builder: (dialogContext) => CreateHabitDialog(categories: categories),
      );
      if (detailedResult != null && context.mounted) {
        HabitsRepository().addHabit(detailedResult);
        unawaited(ReminderService.instance.scheduleHabit(detailedResult));
      }
      return;
    }

    if (result != null && context.mounted) {
      HabitsRepository().addHabit(result);
      unawaited(ReminderService.instance.scheduleHabit(result));
    }
  }

  /// Abre un bottom sheet flotante para completar el hábito.
  ///
  /// No se cierra al tocar fuera ni al arrastrar; solo con la X para que
  /// el usuario pueda marcar, editar cantidades o usar el cronómetro
  /// sin que se cierre accidentalmente.
  ///
  /// Cuando [readOnly] es true, se muestra el [habit] proporcionado en modo
  /// solo visualización (usado al consultar un día que no es hoy).
  void _openHabitCompletion(
    BuildContext context,
    String habitId, {
    bool readOnly = false,
    Habit? habit,
  }) {
    showModalBottomSheet(
      context: context,
      isDismissible: false,
      enableDrag: false,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => HabitCompletionBottomSheet(
        habitId: habitId,
        readOnly: readOnly,
        habitOverride: readOnly ? habit : null,
      ),
    );
  }

  /// Banner que muestra un temporizador de hábito activo, permitiendo al
  /// usuario volver al timer aunque haya cerrado el bottom sheet o la alarma.
  Widget _buildActiveTimerBanner(ThemeData theme) {
    final session = HabitExecutionService().currentSession;
    if (session == null) return const SizedBox.shrink();

    final habit = HabitsRepository().getHabitById(session.habitId);
    if (habit == null) return const SizedBox.shrink();

    final elapsed = session.elapsedSeconds;
    final h = (elapsed ~/ 3600).toString().padLeft(2, '0');
    final m = ((elapsed % 3600) ~/ 60).toString().padLeft(2, '0');
    final s = (elapsed % 60).toString().padLeft(2, '0');
    final timeText = '$h:$m:$s';

    final isPaused = session.isPaused;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _openHabitCompletion(context, session.habitId),
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.neonGreen.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppColors.neonGreen.withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  isPaused ? Icons.pause_circle_rounded : Icons.timer_rounded,
                  color: AppColors.neonGreen,
                  size: 28,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        isPaused
                            ? '${habit.title} (pausado)'
                            : habit.title,
                        style: theme.textTheme.titleSmall,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        timeText,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: AppColors.neonGreen,
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  color: AppColors.neonGreen,
                  size: 24,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Encabezado con el título de la app y el icono de notificaciones.
  Widget _buildHeader(TextTheme textTheme) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 10, 14, 8),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('SunHabit', style: textTheme.headlineSmall),
                const SizedBox(height: 3),
                Text(
                  'Construye hábitos, transforma tu vida.',
                  style: textTheme.bodyMedium,
                ),
              ],
            ),
          ),
          Stack(
            clipBehavior: Clip.none,
            children: [
              IconButton(
                onPressed: () {},
                icon: const Icon(Icons.notifications_none_rounded),
              ),
              const Positioned(
                right: 9,
                top: 8,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: AppColors.neonGreen,
                    shape: BoxShape.circle,
                  ),
                  child: SizedBox(width: 6, height: 6),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
