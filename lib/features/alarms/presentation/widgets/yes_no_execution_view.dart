import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sunhabit/core/constants/app_constants.dart';
import 'package:sunhabit/core/theme/app_colors.dart';
import 'package:sunhabit/core/theme/app_decorations.dart';
import 'package:sunhabit/features/habits/data/habit_model.dart';

class YesNoExecutionView extends StatefulWidget {
  final Habit habit;
  final ValueChanged<bool> onAnswer;
  final VoidCallback onSnooze;

  const YesNoExecutionView({
    super.key,
    required this.habit,
    required this.onAnswer,
    required this.onSnooze,
  });

  @override
  State<YesNoExecutionView> createState() => _YesNoExecutionViewState();
}

class _YesNoExecutionViewState extends State<YesNoExecutionView> {
  double _sliderValue = 0.5; // 0.0 = NO, 1.0 = YES, 0.5 = neutral
  bool _answered = false;

  void _handleSliderChange(double value) {
    if (_answered) return;
    setState(() => _sliderValue = value);

    if (value >= 0.95) {
      _answered = true;
      HapticFeedback.mediumImpact();
      widget.onAnswer(true);
    } else if (value <= 0.05) {
      _answered = true;
      HapticFeedback.mediumImpact();
      widget.onAnswer(false);
    }
  }

  void _handleSliderEnd(double value) {
    if (_answered) return;
    if (value < 0.95 && value > 0.05) {
      // Snap back to center if not committed
      setState(() => _sliderValue = 0.5);
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: AppDecorations.card,
          child: Column(
            children: [
              const Icon(
                Icons.help_outline_rounded,
                color: AppColors.neonGreen,
                size: 40,
              ),
              const SizedBox(height: 12),
              Text(
                '¿Completaste este hábito?',
                style: textTheme.titleMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
          const SizedBox(height: 32),
          Text(
            'Desliza para responder',
            style: textTheme.bodySmall?.copyWith(
              color: AppColors.textMuted,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            height: 64,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            decoration: BoxDecoration(
              color: AppColors.surfaceHighest,
              borderRadius: BorderRadius.circular(32),
              border: Border.all(color: AppColors.borderDark),
            ),
            child: Row(
              children: [
                Padding(
                  padding: const EdgeInsets.only(left: 12),
                  child: Text(
                    '✕ NO',
                    style: textTheme.titleSmall?.copyWith(
                      color: _sliderValue < 0.4
                          ? Colors.redAccent
                          : AppColors.textMuted,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Expanded(
                  child: SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      trackHeight: 6,
                      activeTrackColor: _sliderValue > 0.5
                          ? AppColors.neonGreen
                          : Colors.redAccent,
                      inactiveTrackColor: AppColors.surfaceElevated,
                      thumbColor: _sliderValue > 0.5
                          ? AppColors.neonGreen
                          : (_sliderValue < 0.5 ? Colors.redAccent : Colors.white),
                      thumbShape: const RoundSliderThumbShape(
                        enabledThumbRadius: 18,
                        elevation: 4,
                      ),
                      overlayColor: AppColors.neonGreen.withValues(alpha: 0.2),
                    ),
                    child: Slider(
                      value: _sliderValue,
                      onChanged: _handleSliderChange,
                      onChangeEnd: _handleSliderEnd,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: Text(
                    'SÍ ✓',
                    style: textTheme.titleSmall?.copyWith(
                      color: _sliderValue > 0.6
                          ? AppColors.neonGreen
                          : AppColors.textMuted,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => widget.onAnswer(false),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.redAccent,
                    side: const BorderSide(color: Colors.redAccent),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(AppConstants.cardRadius),
                    ),
                  ),
                  child: const Text('NO'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () => widget.onAnswer(true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.neonGreen,
                    foregroundColor: const Color(0xFF152000),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(AppConstants.cardRadius),
                    ),
                  ),
                  child: const Text(
                    'SÍ',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextButton.icon(
            onPressed: widget.onSnooze,
            icon: const Icon(Icons.snooze_rounded, size: 18),
            label: const Text('Recordar más tarde'),
            style: TextButton.styleFrom(
              foregroundColor: AppColors.textSecondary,
            ),
          ),
        ],
      );
  }
}
