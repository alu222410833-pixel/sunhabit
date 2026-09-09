import 'package:flutter/material.dart';
import 'package:sunhabit/core/constants/app_constants.dart';
import 'package:sunhabit/core/theme/app_colors.dart';
import 'package:sunhabit/core/theme/app_decorations.dart';
import 'package:sunhabit/features/categories/data/category_model.dart';
import 'package:sunhabit/features/habits/data/habit_model.dart';
import 'package:sunhabit/features/habits/domain/express_habit_parser.dart';
import 'package:sunhabit/features/habits/domain/express_habit_templates.dart';
import 'package:sunhabit/features/habits/presentation/widgets/habit_card.dart';

class ExpressHabitDialog extends StatefulWidget {
  final List<Category> categories;

  const ExpressHabitDialog({super.key, required this.categories});

  @override
  State<ExpressHabitDialog> createState() => _ExpressHabitDialogState();
}

class _ExpressHabitDialogState extends State<ExpressHabitDialog> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();
  late final _parser = ExpressHabitParser(categories: widget.categories);
  ParsedExpressHabit _parsed = const ParsedExpressHabit();
  bool _showMoreFrequencies = false;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    _controller.removeListener(_onTextChanged);
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onTextChanged() {
    setState(() {
      _parsed = _parser.parse(_controller.text);
    });
  }

  void _insertTemplate(String command, {String? select}) {
    _controller.text = command;
    _onTextChanged();

    if (select != null) {
      final start = command.indexOf(select);
      if (start != -1) {
        _controller.selection = TextSelection(
          baseOffset: start,
          extentOffset: start + select.length,
        );
      } else {
        _controller.selection = TextSelection.collapsed(offset: command.length);
      }
    } else {
      _controller.selection = TextSelection.collapsed(offset: command.length);
    }

    _focusNode.requestFocus();
  }

  Habit? _buildHabit() {
    if (!_parsed.isValid) return null;

    final selectedCategory = widget.categories.firstWhere(
      (c) => c.id == _parsed.categoryId,
      orElse: () => widget.categories.first,
    );

    final isYesNo = _parsed.evaluationType == HabitEvaluationType.yesNo;
    final isAmount = _parsed.evaluationType == HabitEvaluationType.amount;
    final isChecklist = _parsed.evaluationType == HabitEvaluationType.checklist;
    final isTimer = _parsed.evaluationType == HabitEvaluationType.timer;

    return Habit(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      title: _parsed.title!,
      categoryId: _parsed.categoryId!,
      icon: selectedCategory.icon,
      iconColor: selectedCategory.iconColor,
      yesNo: isYesNo ? false : null,
      current: isAmount ? 0 : null,
      target: isAmount ? _parsed.target : null,
      unit: isAmount ? _parsed.unit : null,
      checklist: isChecklist && _parsed.checklist != null && _parsed.checklist!.isNotEmpty
          ? List.from(_parsed.checklist!)
          : null,
      completedChecklist: isChecklist ? [] : null,
      estimatedDuration: isTimer ? _parsed.estimatedDuration : null,
      frequency: _parsed.frequency ?? 'Todos los días',
      weekDays: _parsed.frequency == 'Días exactos de la semana'
          ? _parsed.weekDays
          : null,
      monthDays: _parsed.frequency == 'Días específicos del mes'
          ? _parsed.monthDays
          : null,
      timesPerPeriod: _parsed.frequency == 'Algunas veces por período'
          ? _parsed.timesPerPeriod
          : null,
      periodType: _parsed.frequency == 'Algunas veces por período'
          ? _parsed.periodType
          : null,
      repeatInterval: _parsed.frequency == 'Repetir'
          ? _parsed.repeatInterval
          : null,
      startDate: _parsed.startDate ?? DateTime.now(),
      reminders: _parsed.reminders ?? const [],
      points: isYesNo ? 10 : 15,
    );
  }

  void _createHabit() {
    final habit = _buildHabit();
    if (habit == null) return;
    Navigator.of(context).pop(habit);
  }

  void _openDetailedMode() {
    Navigator.of(context).pop(null);
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final previewHabit = _buildHabit();

    return Dialog(
      backgroundColor: AppColors.surfaceElevated,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppConstants.largeRadius),
        side: const BorderSide(color: AppColors.borderDark),
      ),
      insetPadding: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Creación Exprés',
                style: textTheme.titleLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 6),
              Text(
                'Separa cada parte con |',
                style: textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              _buildTextField(textTheme),
              const SizedBox(height: 14),
              _buildTemplateChips(textTheme),
              if (_showMoreFrequencies) ...[
                const SizedBox(height: 12),
                _buildFrequencyChips(textTheme),
              ],
              const SizedBox(height: 16),
              _buildPreview(textTheme, previewHabit),
              if (_parsed.errors.isNotEmpty) ...[
                const SizedBox(height: 10),
                _buildErrors(textTheme),
              ],
              const SizedBox(height: 18),
              _buildButtons(textTheme),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(TextTheme textTheme) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(AppConstants.cardRadius),
        border: Border.all(color: AppColors.borderDark),
      ),
      child: TextField(
        controller: _controller,
        focusNode: _focusNode,
        maxLines: 3,
        minLines: 2,
        style: textTheme.bodyMedium,
        decoration: InputDecoration(
          hintText:
              'Ej: Beber agua en Salud | Cantidad: 2 vasos | Todos los días | hoy | 8:00 AM',
          hintStyle: textTheme.bodyMedium?.copyWith(
            color: AppColors.textMuted,
          ),
          contentPadding: const EdgeInsets.all(14),
          border: InputBorder.none,
        ),
      ),
    );
  }

  Widget _buildTemplateChips(TextTheme textTheme) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        ...mainExpressTemplates.map((template) {
          return _TemplateChip(
            label: '${template.icon} ${template.label}',
            onTap: () => _insertTemplate(template.command, select: '2 vasos'),
          );
        }),
        _TemplateChip(
          label: _showMoreFrequencies ? 'Menos frecuencias' : 'Más frecuencias',
          onTap: () => setState(() => _showMoreFrequencies = !_showMoreFrequencies),
        ),
      ],
    );
  }

  Widget _buildFrequencyChips(TextTheme textTheme) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: frequencyExpressTemplates.map((template) {
        return _TemplateChip(
          label: template.label,
          onTap: () => _insertTemplate(template.command, select: 'Hábito'),
        );
      }).toList(),
    );
  }

  Widget _buildPreview(TextTheme textTheme, Habit? habit) {
    if (habit == null) {
      return Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surfaceDark,
          borderRadius: BorderRadius.circular(AppConstants.cardRadius),
          border: Border.all(color: AppColors.borderDark),
        ),
        child: Text(
          'Escribe tu comando para ver la vista previa...',
          style: textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
          textAlign: TextAlign.center,
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Vista previa', style: textTheme.titleSmall),
        const SizedBox(height: 8),
        HabitCard(habit: habit),
      ],
    );
  }

  Widget _buildErrors(TextTheme textTheme) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.danger.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppConstants.cardRadius),
        border: Border.all(color: AppColors.danger),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: _parsed.errors.map((error) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Text(
              '• $error',
              style: textTheme.bodySmall?.copyWith(color: AppColors.danger),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildButtons(TextTheme textTheme) {
    return Row(
      children: [
        Expanded(
          child: GestureDetector(
            onTap: _openDetailedMode,
            child: Container(
              height: AppConstants.controlHeight,
              decoration: BoxDecoration(
                color: AppColors.surfaceHighest,
                borderRadius: BorderRadius.circular(AppConstants.cardRadius),
                border: Border.all(color: AppColors.borderDark),
              ),
              alignment: Alignment.center,
              child: Text(
                'Modo detallado',
                style: textTheme.titleMedium?.copyWith(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: GestureDetector(
            onTap: _parsed.isValid ? _createHabit : null,
            child: Opacity(
              opacity: _parsed.isValid ? 1 : 0.5,
              child: Container(
                height: AppConstants.controlHeight,
                decoration: AppDecorations.neonButton,
                alignment: Alignment.center,
                child: Text(
                  'Crear',
                  style: textTheme.titleMedium?.copyWith(
                    color: const Color(0xFF152000),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _TemplateChip extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _TemplateChip({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.surfaceHighest,
          borderRadius: BorderRadius.circular(AppConstants.cardRadius),
          border: Border.all(color: AppColors.borderDark),
        ),
        child: Text(
          label,
          style: textTheme.labelMedium?.copyWith(color: AppColors.textSecondary),
        ),
      ),
    );
  }
}
