import 'package:flutter/material.dart';
import 'package:sunhabit/core/theme/app_colors.dart';

class WeekDayPicker extends StatelessWidget {
  final List<bool> weekDays;
  final ValueChanged<List<bool>> onChanged;

  const WeekDayPicker({
    super.key,
    required this.weekDays,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    const labels = ['L', 'M', 'M', 'J', 'V', 'S', 'D'];
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = ((constraints.maxWidth - 6 * 6) / 7).clamp(28.0, 38.0);
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(7, (index) {
            final active = weekDays[index];
            return GestureDetector(
              onTap: () {
                final updated = List<bool>.from(weekDays);
                updated[index] = !updated[index];
                onChanged(updated);
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                width: size,
                height: size,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: active ? AppColors.neonGreen : AppColors.surfaceHighest,
                  border: Border.all(
                    color: active ? AppColors.neonGreen : AppColors.borderDark,
                    width: active ? 2 : 1,
                  ),
                ),
                alignment: Alignment.center,
                child: Text(
                  labels[index],
                  style: TextStyle(
                    color: active
                        ? const Color(0xFF152000)
                        : AppColors.textSecondary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            );
          }),
        );
      },
    );
  }
}
