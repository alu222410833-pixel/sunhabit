import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sunhabit/core/theme/app_colors.dart';

class TimeInputFields extends StatelessWidget {
  final TextEditingController hoursController;
  final TextEditingController minutesController;
  final TextEditingController secondsController;
  final bool enabled;
  final VoidCallback onChanged;

  const TimeInputFields({
    super.key,
    required this.hoursController,
    required this.minutesController,
    required this.secondsController,
    required this.enabled,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: _TimeField(
            label: 'Horas',
            controller: hoursController,
            enabled: enabled,
            onChanged: onChanged,
          ),
        ),
        const _Separator(),
        Expanded(
          child: _TimeField(
            label: 'Minutos',
            controller: minutesController,
            enabled: enabled,
            onChanged: onChanged,
          ),
        ),
        const _Separator(),
        Expanded(
          child: _TimeField(
            label: 'Segundos',
            controller: secondsController,
            enabled: enabled,
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }
}

class _TimeField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final bool enabled;
  final VoidCallback onChanged;

  const _TimeField({
    required this.label,
    required this.controller,
    required this.enabled,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Column(
      children: [
        Text(label, style: textTheme.labelMedium),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          enabled: enabled,
          keyboardType: TextInputType.number,
          textInputAction: TextInputAction.next,
          textAlign: TextAlign.center,
          style: textTheme.titleLarge?.copyWith(
            color: AppColors.textPrimary,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(2),
          ],
          decoration: const InputDecoration(
            counterText: '',
            contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 13),
          ),
          maxLength: 2,
          onTap: () {
            controller.selection = TextSelection(
              baseOffset: 0,
              extentOffset: controller.text.length,
            );
          },
          onChanged: (_) => onChanged(),
        ),
      ],
    );
  }
}

class _Separator extends StatelessWidget {
  const _Separator();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(7, 0, 7, 13),
      child: Text(':', style: Theme.of(context).textTheme.titleLarge),
    );
  }
}
