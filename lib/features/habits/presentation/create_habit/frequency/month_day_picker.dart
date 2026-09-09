import 'package:flutter/material.dart';
import 'package:sunhabit/core/theme/app_colors.dart';

class MonthDayPicker extends StatelessWidget {
  final List<int> monthDays;
  final ValueChanged<List<int>> onChanged;

  const MonthDayPicker({
    super.key,
    required this.monthDays,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: List.generate(31, (index) {
        final day = index + 1;
        final active = monthDays.contains(day);
        return GestureDetector(
          onTap: () {
            final updated = List<int>.from(monthDays);
            if (active) {
              updated.remove(day);
            } else {
              updated.add(day);
              updated.sort();
            }
            onChanged(updated);
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            width: 40,
            height: 40,
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
              '$day',
              style: TextStyle(
                color: active
                    ? const Color(0xFF152000)
                    : AppColors.textSecondary,
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
            ),
          ),
        );
      }),
    );
  }
}
