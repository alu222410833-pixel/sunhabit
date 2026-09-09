import 'package:flutter/material.dart';
import 'package:sunhabit/core/constants/app_constants.dart';
import 'package:sunhabit/core/theme/app_colors.dart';

class FrequencyOption extends StatelessWidget {
  final String title;
  final bool isSelected;
  final VoidCallback onTap;
  final Widget? child;

  const FrequencyOption({
    super.key,
    required this.title,
    required this.isSelected,
    required this.onTap,
    this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          decoration: BoxDecoration(
            color: isSelected
                ? AppColors.neonGreen.withValues(alpha: 0.12)
                : AppColors.surfaceHighest,
            borderRadius: BorderRadius.circular(AppConstants.cardRadius),
            border: Border.all(
              color: isSelected ? AppColors.neonGreen : AppColors.borderDark,
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.all(14),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ),
                    if (isSelected)
                      const Icon(Icons.check_circle,
                          color: AppColors.neonGreen)
                    else
                      const Icon(Icons.radio_button_unchecked,
                          color: AppColors.textMuted),
                  ],
                ),
              ),
              AnimatedCrossFade(
                firstChild: const SizedBox.shrink(),
                secondChild: Padding(
                  padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
                  child: child ?? const SizedBox.shrink(),
                ),
                crossFadeState: isSelected
                    ? CrossFadeState.showSecond
                    : CrossFadeState.showFirst,
                duration: const Duration(milliseconds: 220),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
