import 'package:flutter/material.dart';
import 'package:sunhabit/core/constants/app_constants.dart';
import 'package:sunhabit/core/services/habit_execution_service.dart';
import 'package:sunhabit/core/theme/app_colors.dart';
import 'package:sunhabit/features/habits/data/habit_model.dart';
import 'package:sunhabit/features/habits/data/habits_repository.dart';
import 'package:sunhabit/features/habits/presentation/habit_completion_bottom_sheet/action_button.dart';
import 'package:sunhabit/features/habits/presentation/habit_completion_bottom_sheet/eye_care_progress.dart';

/// Panel para hábitos con duración estimada.
///
/// Ofrece un cronómetro con inicio/pausa. Al pulsar “Completar",
/// detiene el tiempo y guarda los segundos transcurridos en el log.
class TimerSection extends StatefulWidget {
  final Habit habit;
  final bool readOnly;

  const TimerSection({super.key, required this.habit, this.readOnly = false});

  @override
  State<TimerSection> createState() => TimerSectionState();
}

class TimerSectionState extends State<TimerSection> {
  final _svc = HabitExecutionService();

  /// Segundos transcurridos justo antes de que la sesión se detenga.
  /// Se usa para mostrar el tiempo alcanzado cuando el hábito se completa.
  int? _lastElapsedSeconds;

  /// Indica que la sesión acaba de terminar antes de que el repositorio
  /// notifique que el hábito está completado, evitando mostrar "Iniciar"
  /// un frame.
  bool _justFinished = false;

  /// Último estado conocido de actividad para detectar transiciones.
  bool _wasActive = false;

  bool get _isCurrentActive => _svc.isHabitActive(widget.habit.id);
  bool get _isPaused => _isCurrentActive && _svc.currentSession!.isPaused;

  int get _elapsedSeconds {
    if (!_isCurrentActive) return 0;
    return _svc.currentSession!.elapsedSeconds;
  }

  void _start() {
    _svc.startTimer(widget.habit);
  }

  void _startWithEyeCare() {
    _svc.startTimerWithEyeCare(widget.habit);
  }

  void _toggle() {
    _svc.toggleTimer();
  }

  void _stop() {
    final seconds = _elapsedSeconds;
    _svc.stopTimer();
    HabitsRepository().completeHabitWithDuration(widget.habit.id, seconds);
    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  String get _elapsed {
    final s = _elapsedSeconds;
    final h = (s ~/ 3600).toString().padLeft(2, '0');
    final m = ((s % 3600) ~/ 60).toString().padLeft(2, '0');
    final sec = (s % 60).toString().padLeft(2, '0');
    return '$h:$m:$sec';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (widget.readOnly) {
      return Column(
        children: [
          Text(
            widget.habit.estimatedDuration != null
                ? _formatDuration(widget.habit.estimatedDuration!)
                : '00:00:00',
            style: theme.textTheme.displayLarge,
          ),
          const SizedBox(height: 8),
          if (widget.habit.estimatedDuration != null)
            Text(
              'Meta: ${_formatDuration(widget.habit.estimatedDuration!)}',
              style: theme.textTheme.bodyMedium,
            ),
          const SizedBox(height: 24),
          if (widget.habit.isCompleted)
            ActionButton(
              label: 'Completado',
              icon: Icons.check_rounded,
              onTap: null,
            ),
        ],
      );
    }

    final canStartEyeCare =
        (widget.habit.estimatedDuration?.inSeconds ?? 0) >=
            AppConstants.eyeCareWorkSeconds;

    return ListenableBuilder(
      listenable: _svc,
      builder: (context, _) {
        final isActive = _isCurrentActive;
        if (isActive) _lastElapsedSeconds = _elapsedSeconds;
        if (_wasActive && !isActive) _justFinished = true;
        if (isActive) _justFinished = false;
        _wasActive = isActive;

        final hasStarted = isActive;
        final isPaused = _isPaused;
        final isCompleted = widget.habit.isCompleted || _justFinished;

        final completedSeconds = _lastElapsedSeconds ??
            widget.habit.estimatedDuration?.inSeconds ??
            0;
        final displayTime = isCompleted && !hasStarted
            ? _formatDuration(Duration(seconds: completedSeconds))
            : _elapsed;

        return Column(
          children: [
            Text(displayTime, style: theme.textTheme.displayLarge),
            const SizedBox(height: 8),
            if (widget.habit.estimatedDuration != null)
              Text(
                'Meta: ${_formatDuration(widget.habit.estimatedDuration!)}',
                style: theme.textTheme.bodyMedium,
              ),
            const SizedBox(height: 24),
            if (isCompleted && !hasStarted)
              const ActionButton(
                label: 'Completado',
                icon: Icons.check_rounded,
                onTap: null,
              )
            else if (!hasStarted) ...[
              ActionButton(
                label: 'Iniciar',
                icon: Icons.play_arrow_rounded,
                onTap: _start,
              ),
              const SizedBox(height: 12),
              ActionButton(
                label: 'Iniciar con cuidado visual',
                icon: Icons.visibility_outlined,
                color: AppColors.water,
                onTap: canStartEyeCare ? _startWithEyeCare : null,
              ),
            ] else ...[
              ActionButton(
                label: isPaused ? 'Reanudar' : 'Pausar',
                icon: isPaused ? Icons.play_arrow_rounded : Icons.pause_rounded,
                onTap: _toggle,
              ),
              const SizedBox(height: 12),
              ActionButton(
                label: 'Finalizar',
                icon: Icons.stop_rounded,
                onTap: _stop,
              ),
              if (_svc.eyeCareEnabled) ...[
                const SizedBox(height: 16),
                EyeCareProgress(
                  remaining: _svc.eyeCareRemaining,
                  isWorkPhase: _svc.eyeCareWorkPhase,
                ),
              ],
            ],
          ],
        );
      },
    );
  }

  String _formatDuration(Duration d) {
    final h = d.inHours.toString().padLeft(2, '0');
    final m = (d.inMinutes % 60).toString().padLeft(2, '0');
    final s = (d.inSeconds % 60).toString().padLeft(2, '0');
    return '$h:$m:$s';
  }
}
