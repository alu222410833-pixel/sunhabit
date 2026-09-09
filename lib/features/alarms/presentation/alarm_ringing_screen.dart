import 'dart:convert';
import 'dart:io';

import 'package:alarm/alarm.dart';
import 'package:flutter/material.dart';
import 'package:sunhabit/core/navigation/app_router.dart';
import 'package:sunhabit/core/services/habit_execution_service.dart';
import 'package:sunhabit/features/categories/data/category_model.dart';
import 'package:sunhabit/core/services/notification_service.dart';
import 'package:sunhabit/core/theme/app_colors.dart';
import 'package:sunhabit/core/theme/app_decorations.dart';
import 'package:sunhabit/features/alarms/presentation/widgets/alarm_sound_banner.dart';
import 'package:sunhabit/features/alarms/presentation/widgets/amount_execution_view.dart';
import 'package:sunhabit/features/alarms/presentation/widgets/checklist_execution_view.dart';
import 'package:sunhabit/features/alarms/presentation/widgets/timer_execution_view.dart';
import 'package:sunhabit/features/alarms/presentation/widgets/yes_no_execution_view.dart';
import 'package:sunhabit/features/habits/data/habit_model.dart';
import 'package:sunhabit/features/habits/data/habits_repository.dart';

class AlarmRingingScreen extends StatefulWidget {
  final AlarmSettings? alarmSettings;

  const AlarmRingingScreen({super.key, this.alarmSettings});

  @override
  State<AlarmRingingScreen> createState() => _AlarmRingingScreenState();
}

class _AlarmRingingScreenState extends State<AlarmRingingScreen> {
  Habit? _habit;
  bool _isAlarmRinging = true;
  bool _isNavigating = false;

  @override
  void initState() {
    super.initState();
    _loadHabit();
    HabitsRepository().addListener(_onHabitCompleted);
  }

  @override
  void dispose() {
    HabitsRepository().removeListener(_onHabitCompleted);
    super.dispose();
  }

  void _loadHabit() {
    final payload = _parsePayload(widget.alarmSettings?.payload);
    final habitId = payload['habitId'] as String? ?? '';
    _habit = HabitsRepository().getHabitById(habitId);
  }

  Future<void> _onHabitCompleted() async {
    final habit = _habit;
    if (habit == null || _isNavigating) return;
    final updated = HabitsRepository().getHabitById(habit.id);
    if (updated?.isCompleted == true) {
      _isNavigating = true;
      await _silenceAlarm();
      if (mounted) {
        AppRouter.goHome(context);
      }
    }
  }

  Map<String, dynamic> _parsePayload(String? payload) {
    if (payload == null || payload.isEmpty) return {};
    try {
      return jsonDecode(payload) as Map<String, dynamic>;
    } catch (_) {
      return {};
    }
  }

  Future<void> _silenceAlarm() async {
    if (widget.alarmSettings != null) {
      await Alarm.stop(widget.alarmSettings!.id);
    }
    if (mounted) {
      setState(() => _isAlarmRinging = false);
    }
  }

  Future<void> _handleSnooze() async {
    await _silenceAlarm();
    if (_habit != null) {
      await NotificationService.snoozeHabit(_habit!.id, 10);
    }
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Recordatorio pospuesto 10 minutos'),
          duration: Duration(seconds: 2),
        ),
      );
      AppRouter.goHome(context);
    }
  }

  Future<void> _handleYesNoAnswer(bool answer) async {
    await _silenceAlarm();
    if (_habit != null) {
      HabitsRepository().setHabitYesNo(_habit!.id, answer);
    }
    if (mounted) {
      AppRouter.goHome(context);
    }
  }

  Future<void> _handleStopTimer() async {
    await _silenceAlarm();
    final session = HabitExecutionService().currentSession;
    final elapsedSeconds = session?.elapsedSeconds ?? 0;
    final habitId = _habit?.id;
    HabitExecutionService().stopTimer();
    if (habitId != null && elapsedSeconds > 0) {
      HabitsRepository().saveHabitDuration(habitId, elapsedSeconds);
    }
    if (mounted) {
      AppRouter.goHome(context);
    }
  }

  Future<void> _handleFinishGeneric() async {
    await _silenceAlarm();
    if (mounted) {
      AppRouter.goHome(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final habit = _habit;
    final category =
        habit != null ? HabitsRepository().getCategoryById(habit.categoryId) : null;

    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      body: Stack(
        fit: StackFit.expand,
        children: [
          _buildBackground(habit, category),
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withValues(alpha: 0.2),
                  Colors.black.withValues(alpha: 0.75),
                ],
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                _buildAppBar(),
                if (habit != null)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: AlarmSoundBanner(
                      isAlarmRinging: _isAlarmRinging,
                      onSilenceAlarm: _silenceAlarm,
                    ),
                  ),
                Expanded(
                  child: SingleChildScrollView(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Column(
                        children: [
                          const SizedBox(height: 12),
                          _buildIcon(habit, category),
                          const SizedBox(height: 28),
                          _buildTitle(habit),
                          const SizedBox(height: 8),
                          _buildSubtitle(habit),
                          const SizedBox(height: 16),
                          _buildCategoryChip(category),
                          const SizedBox(height: 24),
                          _buildStats(habit),
                          const SizedBox(height: 28),
                          _buildEvaluationBody(habit),
                          const SizedBox(height: 24),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          IconButton(
            onPressed: _handleFinishGeneric,
            icon: const Icon(Icons.close_rounded),
            color: AppColors.textPrimary,
          ),
        ],
      ),
    );
  }

  Widget _buildIcon(Habit? habit, Category? category) {
    final icon = habit?.icon ?? category?.icon ?? Icons.alarm;
    final color = habit?.iconColor ?? category?.iconColor ?? AppColors.neonGreen;

    return SizedBox(
      width: 180,
      height: 180,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: 180,
            height: 180,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: color.withValues(alpha: 0.35),
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: 0.18),
                  blurRadius: 50,
                  spreadRadius: 10,
                ),
                BoxShadow(
                  color: color.withValues(alpha: 0.08),
                  blurRadius: 80,
                  spreadRadius: 30,
                ),
              ],
            ),
          ),
          Container(
            width: 150,
            height: 150,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color.withValues(alpha: 0.12),
              border: Border.all(
                color: color.withValues(alpha: 0.45),
                width: 2,
              ),
            ),
            child: Icon(icon, color: color, size: 72),
          ),
        ],
      ),
    );
  }

  Widget _buildTitle(Habit? habit) {
    final text = habit != null ? '¡Es hora de ${habit.title}!' : 'Alarma';
    return Text(
      text,
      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
      textAlign: TextAlign.center,
    );
  }

  Widget _buildSubtitle(Habit? habit) {
    String text;
    if (habit == null) {
      text = 'Tu recordatorio te está esperando.';
    } else {
      text = 'No es solo hoy, es tu compromiso contigo.';
    }
    return Text(
      text,
      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            color: AppColors.textSecondary,
          ),
      textAlign: TextAlign.center,
    );
  }

  Widget _buildCategoryChip(Category? category) {
    final name = category?.name ?? 'Hábito';
    final color = category?.iconColor ?? AppColors.neonGreen;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Text(
        name,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
            ),
      ),
    );
  }

  Widget _buildStats(Habit? habit) {
    if (habit == null) return const SizedBox.shrink();

    final points = habit.points;
    final isChecklist = habit.checklist != null && habit.checklist!.isNotEmpty;
    final taskCount = habit.checklist?.length ?? 0;
    final estimated = habit.estimatedDuration;

    final secondIcon = isChecklist ? Icons.checklist_rounded : Icons.timer_outlined;
    final secondValue = isChecklist
        ? '$taskCount'
        : (estimated != null
            ? '${estimated.inMinutes.toString().padLeft(2, '0')}:${(estimated.inSeconds % 60).toString().padLeft(2, '0')}'
            : '--:--');
    final secondLabel =
        isChecklist ? (taskCount == 1 ? 'tarea' : 'tareas') : 'minutos';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: AppDecorations.card,
      child: Row(
        children: [
          Expanded(
            child: _buildStatItem(
              icon: Icons.star_rounded,
              value: '$points',
              label: 'puntos',
              color: AppColors.star,
            ),
          ),
          Container(width: 1, height: 36, color: AppColors.borderDark),
          Expanded(
            child: _buildStatItem(
              icon: secondIcon,
              value: secondValue,
              label: secondLabel,
              color: AppColors.neonGreen,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String value,
    required String label,
    required Color color,
  }) {
    final textTheme = Theme.of(context).textTheme;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 22),
        const SizedBox(height: 6),
        Text(
          value,
          style: textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
        ),
        Text(
          label,
          style: textTheme.bodySmall?.copyWith(
                color: AppColors.textSecondary,
              ),
        ),
      ],
    );
  }

  Widget _buildEvaluationBody(Habit? habit) {
    if (habit == null) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.alarm, size: 64, color: AppColors.neonGreen),
          const SizedBox(height: 16),
          Text(
            'Alarma',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 32),
          GestureDetector(
            onTap: _handleFinishGeneric,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 18),
              decoration: AppDecorations.neonButton,
              alignment: Alignment.center,
              child: const Text(
                'Detener',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF152000),
                ),
              ),
            ),
          ),
        ],
      );
    }

    switch (habit.evaluationType) {
      case HabitEvaluationType.timer:
        return TimerExecutionView(
          habit: habit,
          onStop: _handleStopTimer,
          onSnooze: _handleSnooze,
        );
      case HabitEvaluationType.yesNo:
        return YesNoExecutionView(
          habit: habit,
          onAnswer: _handleYesNoAnswer,
          onSnooze: _handleSnooze,
        );
      case HabitEvaluationType.checklist:
        return ChecklistExecutionView(
          habit: habit,
          onFinish: _handleFinishGeneric,
          onSnooze: _handleSnooze,
        );
      case HabitEvaluationType.amount:
        return AmountExecutionView(
          habit: habit,
          onFinish: _handleFinishGeneric,
          onSnooze: _handleSnooze,
        );
    }
  }

  Widget _buildBackground(Habit? habit, Category? category) {
    final imagePath = habit?.imagePath ?? category?.imagePath;

    if (imagePath != null && imagePath.isNotEmpty) {
      return Image.file(
        File(imagePath),
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) =>
            _iconBackground(habit, category?.icon, category?.iconColor),
      );
    }
    return _iconBackground(habit, category?.icon, category?.iconColor);
  }

  Widget _iconBackground(Habit? habit, IconData? categoryIcon, Color? categoryColor) {
    final icon = habit?.icon ?? categoryIcon;
    final color = habit?.iconColor ?? categoryColor ?? AppColors.neonGreen;

    return Container(
      color: AppColors.backgroundDark,
      alignment: Alignment.center,
      child: icon != null
          ? Icon(
              icon,
              color: color.withValues(alpha: 0.08),
              size: 300,
            )
          : const SizedBox.shrink(),
    );
  }
}
