import 'package:flutter/material.dart';
import 'package:sunhabit/core/constants/app_constants.dart';
import 'package:sunhabit/core/theme/app_colors.dart';

class NumberInput extends StatelessWidget {
  final int value;
  final ValueChanged<int> onChanged;

  const NumberInput({
    super.key,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 90,
      height: 42,
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(AppConstants.cardRadius),
        border: Border.all(color: AppColors.borderDark),
      ),
      child: Row(
        children: [
          _StepButton(
            icon: Icons.remove,
            onTap: () => onChanged((value - 1).clamp(1, 99)),
          ),
          Expanded(
            child: Text(
              '$value',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
          _StepButton(
            icon: Icons.add,
            onTap: () => onChanged((value + 1).clamp(1, 99)),
          ),
        ],
      ),
    );
  }
}

class _StepButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _StepButton({
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: 28,
        height: double.infinity,
        child: Icon(icon, size: 18, color: AppColors.textSecondary),
      ),
    );
  }
}
