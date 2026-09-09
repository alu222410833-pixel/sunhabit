import 'package:flutter/material.dart';
import 'package:sunhabit/core/theme/app_colors.dart';

class EyeCareProgress extends StatelessWidget {
  final int remaining;
  final bool isWorkPhase;

  const EyeCareProgress({
    super.key,
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
