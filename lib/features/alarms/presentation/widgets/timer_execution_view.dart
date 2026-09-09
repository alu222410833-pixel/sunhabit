import 'package:flutter/material.dart';
import 'package:sunhabit/core/constants/app_constants.dart';
import 'package:sunhabit/core/services/habit_execution_service.dart';
import 'package:sunhabit/core/theme/app_colors.dart';
import 'package:sunhabit/features/habits/data/habit_model.dart';

class TimerExecutionView extends StatelessWidget {
  final Habit habit;
  final VoidCallback onStop;
  final VoidCallback onSnooze;

  const TimerExecutionView({
    super.key,
    required this.habit,
    required this.onStop,
    required this.onSnooze,
  });

  String _formatDuration(int totalSeconds) {
    final minutes = totalSeconds ~/ 60;
    final seconds = totalSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final total = habit.estimatedDuration?.inSeconds ?? 0;

    return ListenableBuilder(
      listenable: HabitExecutionService(),
      builder: (context, _) {
        final service = HabitExecutionService();
        final session = service.currentSession;
        final isCurrentActive = service.isHabitActive(habit.id);

        final elapsedSeconds = isCurrentActive ? (session?.elapsedSeconds ?? 0) : 0;
        final isPaused = isCurrentActive && (session?.isPaused ?? false);
        final hasStarted = isCurrentActive;
        final eyeCareEnabled = service.eyeCareEnabled;
        final eyeCareWorkPhase = service.eyeCareWorkPhase;
        final eyeCareRemaining = service.eyeCareRemaining;

        final remainingSeconds = total > 0 ? (total - elapsedSeconds).clamp(0, total) : elapsedSeconds;
        final progress = total > 0 ? (elapsedSeconds / total).clamp(0.0, 1.0) : 0.0;

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                total > 0
                    ? 'Objetivo: ${_formatDuration(total)} min'
                    : 'Modo cronómetro libre',
                style: textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 32),
              // Circular progress timer ring
              Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 200,
                    height: 200,
                    child: CircularProgressIndicator(
                      value: hasStarted ? progress : 0.0,
                      strokeWidth: 10,
                      backgroundColor: AppColors.surfaceHighest,
                      valueColor: const AlwaysStoppedAnimation<Color>(
                        AppColors.neonGreen,
                      ),
                    ),
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _formatDuration(total > 0 ? remainingSeconds : elapsedSeconds),
                        style: textTheme.displayMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.5,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        total > 0
                            ? '${_formatDuration(elapsedSeconds)} transcurrido'
                            : 'Tiempo libre',
                        style: textTheme.bodySmall?.copyWith(
                          color: AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 36),
              if (!hasStarted) ...[
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => service.startTimer(habit),
                        icon: const Icon(Icons.play_arrow_rounded, size: 24),
                        label: const Text(
                          'Iniciar',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.1,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.neonGreen,
                          foregroundColor: const Color(0xFF152000),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(AppConstants.cardRadius),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: total >= AppConstants.eyeCareWorkSeconds
                            ? () => service.startTimerWithEyeCare(habit)
                            : null,
                        icon: const Icon(Icons.visibility_outlined, size: 24),
                        label: const Text(
                          'Cuidado visual',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.1,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.water,
                          foregroundColor: const Color(0xFF152000),
                          disabledBackgroundColor: AppColors.surfaceHighest,
                          disabledForegroundColor: AppColors.textMuted,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(AppConstants.cardRadius),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextButton.icon(
                  onPressed: onSnooze,
                  icon: const Icon(Icons.snooze_rounded, size: 18),
                  label: const Text('Posponer 10 min'),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.textSecondary,
                  ),
                ),
              ] else ...[
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: service.toggleTimer,
                        icon: Icon(
                          isPaused
                              ? Icons.play_arrow_rounded
                              : Icons.pause_rounded,
                        ),
                        label: Text(isPaused ? 'Reanudar' : 'Pausar'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.textPrimary,
                          side: const BorderSide(color: AppColors.borderDark),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(AppConstants.cardRadius),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: onStop,
                        icon: const Icon(Icons.stop_rounded),
                        label: const Text('Finalizar'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.neonGreen,
                          foregroundColor: const Color(0xFF152000),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(AppConstants.cardRadius),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                if (eyeCareEnabled) ...[
                  const SizedBox(height: 16),
                  _EyeCareProgress(
                    remaining: eyeCareRemaining,
                    isWorkPhase: eyeCareWorkPhase,
                  ),
                ],
              ],
            ],
          ),
        );
      },
    );
  }
}

class _EyeCareProgress extends StatelessWidget {
  final int remaining;
  final bool isWorkPhase;

  const _EyeCareProgress({
    required this.remaining,
    required this.isWorkPhase,
  });

  String _format(int totalSeconds) {
    final minutes = totalSeconds ~/ 60;
    final seconds = totalSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:'
        '${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: isWorkPhase
            ? AppColors.neonGreen.withValues(alpha: 0.08)
            : AppColors.water.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isWorkPhase
              ? AppColors.neonGreen.withValues(alpha: 0.25)
              : AppColors.water.withValues(alpha: 0.35),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            isWorkPhase
                ? Icons.visibility_outlined
                : Icons.remove_red_eye_outlined,
            color: isWorkPhase ? AppColors.neonGreen : AppColors.water,
            size: 22,
          ),
          const SizedBox(width: 10),
          Text(
            isWorkPhase ? 'Pantalla' : 'Descanso visual',
            style: textTheme.bodyMedium?.copyWith(
              color: isWorkPhase ? AppColors.neonGreen : AppColors.water,
            ),
          ),
          const SizedBox(width: 12),
          Text(
            _format(remaining),
            style: textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: isWorkPhase ? AppColors.neonGreen : AppColors.water,
            ),
          ),
        ],
      ),
    );
  }
}
