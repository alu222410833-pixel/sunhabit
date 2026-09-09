part of '../habit_detail_screen.dart';

class _HabitEmptyState extends StatelessWidget {
  final Color iconColor;

  const _HabitEmptyState({required this.iconColor});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Container(
      decoration: AppDecorations.card,
      padding: const EdgeInsets.all(18),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: iconColor.withValues(alpha: 0.1),
              border: Border.all(
                color: iconColor.withValues(alpha: 0.3),
              ),
            ),
            child: Icon(
              Icons.fact_check_outlined,
              color: iconColor,
              size: 28,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Aún no hay registros',
                  style: textTheme.titleSmall,
                ),
                const SizedBox(height: 4),
                Text(
                  'Completa este hábito para comenzar a ver tu historial y progreso.',
                  style: textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Icon(Icons.outlined_flag, color: iconColor.withValues(alpha: 0.4), size: 40),
        ],
      ),
    );
  }
}
