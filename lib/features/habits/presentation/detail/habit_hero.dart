part of '../habit_detail_screen.dart';

class _HabitHero extends StatelessWidget {
  final Habit habit;
  final Color iconColor;
  final String? category;
  final double progress;

  const _HabitHero({
    required this.habit,
    required this.iconColor,
    required this.category,
    required this.progress,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final imagePath = habit.effectiveImagePath;

    return Center(
      child: Column(
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 130,
                height: 130,
                child: CircularProgressIndicator(
                  value: progress,
                  strokeWidth: 6,
                  backgroundColor: iconColor.withValues(alpha: 0.12),
                  valueColor: AlwaysStoppedAnimation(iconColor),
                ),
              ),
              Container(
                width: 104,
                height: 104,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: iconColor.withValues(alpha: 0.08),
                  border: Border.all(
                    color: iconColor.withValues(alpha: 0.24),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: iconColor.withValues(alpha: 0.25),
                      blurRadius: 20,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: imagePath != null
                    ? HabitImageAvatar(imagePath: imagePath, size: 104)
                    : Icon(
                        habit.effectiveIcon,
                        color: iconColor,
                        size: 44,
                      ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            habit.title,
            style: textTheme.headlineSmall,
            textAlign: TextAlign.center,
          ),
          if (category != null)
            Text(
              category!,
              style: textTheme.bodyMedium
                  ?.copyWith(color: AppColors.textSecondary),
            ),
          const SizedBox(height: 10),
          _CompletionBadge(
            isCompleted: habit.isCompleted,
            iconColor: iconColor,
          ),
        ],
      ),
    );
  }
}

class _CompletionBadge extends StatelessWidget {
  final bool isCompleted;
  final Color iconColor;

  const _CompletionBadge({
    required this.isCompleted,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    final color = isCompleted ? iconColor : AppColors.gold;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isCompleted ? Icons.check_rounded : Icons.access_time_rounded,
            color: color,
            size: 16,
          ),
          const SizedBox(width: 6),
          Text(
            isCompleted ? 'Completado' : 'Pendiente',
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
