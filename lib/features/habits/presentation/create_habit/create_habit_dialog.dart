import 'package:flutter/material.dart';
import 'package:sunhabit/core/constants/app_constants.dart';

import 'package:sunhabit/core/theme/app_colors.dart';
import 'package:sunhabit/core/theme/app_decorations.dart';
import 'package:sunhabit/features/categories/data/category_model.dart';
import 'package:sunhabit/features/habits/data/habit_model.dart';
import 'package:sunhabit/features/habits/presentation/create_habit/create_habit_category_step.dart';
import 'package:sunhabit/features/habits/presentation/create_habit/create_habit_evaluation_config_step.dart';
import 'package:sunhabit/features/habits/presentation/create_habit/create_habit_evaluation_type_step.dart';
import 'package:sunhabit/features/habits/presentation/create_habit/create_habit_frequency_step.dart';
import 'package:sunhabit/features/habits/presentation/create_habit/create_habit_schedule_step.dart';
import 'package:sunhabit/features/habits/presentation/create_habit/create_habit_step_indicator.dart';

class CreateHabitDialog extends StatefulWidget {
  final List<Category> categories;
  final Habit? initialHabit;

  // ignore: prefer_const_constructors_in_immutables
  CreateHabitDialog({super.key, required this.categories, this.initialHabit});

  @override
  State<CreateHabitDialog> createState() => _CreateHabitDialogState();
}

class _CreateHabitDialogState extends State<CreateHabitDialog> {
  final _pageController = PageController();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _targetController = TextEditingController();
  final _timerHoursController = TextEditingController(text: '0');
  final _timerMinutesController = TextEditingController(text: '10');
  final _timerSecondsController = TextEditingController(text: '0');
  final _checklistController = TextEditingController();
  int _currentStep = 0;

  late String _categoryId = widget.categories.first.id;
  HabitEvaluationType _evaluationType = HabitEvaluationType.yesNo;

  String _condition = 'Al menos';
  final List<String> _conditions = ['Al menos', 'Menos de', 'Exactamente', 'Libre'];

  int _target = 1;
  String _unit = 'Unidades';
  final List<String> _units = ['Unidades', 'min', 'L', 'pag.', 'vasos', 'pasos', 'repeticiones'];

  String _timerCondition = 'Al menos';
  int _timerHours = 0;
  int _timerMinutes = 10;
  int _timerSeconds = 0;

  final List<String> _checklistItems = [];

  String _frequency = 'Todos los días';
  final List<bool> _weekDays = List.generate(7, (_) => false);
  final List<int> _monthDays = [];
  final List<DateTime> _yearDays = [];
  int _timesPerPeriod = 1;
  String _periodType = 'semana';
  int _repeatInterval = 1;
  final List<String> _frequencies = [
    'Todos los días',
    'Días exactos de la semana',
    'Días específicos del mes',
    'Días específicos del año',
    'Algunas veces por período',
    'Repetir',
  ];

  DateTime _startDate = DateTime.now();
  DateTime? _endDate;
  List<Reminder> _reminders = const [];

  @override
  void dispose() {
    _pageController.dispose();
    _titleController.dispose();
    _descriptionController.dispose();
    _targetController.dispose();
    _timerHoursController.dispose();
    _timerMinutesController.dispose();
    _timerSecondsController.dispose();
    _checklistController.dispose();
    super.dispose();
  }

  void _nextStep() {
    if (_currentStep == 2 && _titleController.text.trim().isEmpty) {
      _showValidationMessage('Escribe un nombre para el hábito.');
      return;
    }
    if (_currentStep < 4) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 260),
        curve: Curves.easeInOut,
      );
      setState(() => _currentStep++);
    } else {
      _createHabit();
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 260),
        curve: Curves.easeInOut,
      );
      setState(() => _currentStep--);
    }
  }

  @override
  void initState() {
    super.initState();
    final initial = widget.initialHabit;
    if (initial != null) _prefill(initial);
  }

  HabitEvaluationType _evaluationTypeFor(Habit h) {
    if (h.checklist != null && h.checklist!.isNotEmpty) {
      return HabitEvaluationType.checklist;
    }
    if (h.estimatedDuration != null) return HabitEvaluationType.timer;
    if (h.target != null || h.unit != null) return HabitEvaluationType.amount;
    return HabitEvaluationType.yesNo;
  }

  void _prefill(Habit h) {
    _categoryId = h.categoryId;
    _evaluationType = _evaluationTypeFor(h);
    _titleController.text = h.title;
    _descriptionController.text = h.description ?? '';
    _target = h.target ?? 1;
    _targetController.text = _target.toString();
    _unit = h.unit ?? 'Unidades';
    _timerHours = h.estimatedDuration?.inHours ?? 0;
    _timerMinutes = (h.estimatedDuration?.inMinutes ?? 10) % 60;
    _timerSeconds = (h.estimatedDuration?.inSeconds ?? 0) % 60;
    _timerHoursController.text = _timerHours.toString();
    _timerMinutesController.text = _timerMinutes.toString();
    _timerSecondsController.text = _timerSeconds.toString();
    _checklistItems
      ..clear()
      ..addAll(h.checklist ?? []);
    _frequency = h.frequency ?? 'Todos los días';
    _weekDays
      ..clear()
      ..addAll(h.weekDays ?? List.filled(7, false));
    _monthDays
      ..clear()
      ..addAll(h.monthDays ?? []);
    _yearDays
      ..clear()
      ..addAll(h.yearDays ?? []);
    _timesPerPeriod = h.timesPerPeriod ?? 1;
    _periodType = h.periodType ?? 'semana';
    _repeatInterval = h.repeatInterval ?? 1;
    _startDate = h.startDate ?? DateTime.now();
    _endDate = h.endDate;
    _reminders = List.from(h.reminders);
  }

  void _onChecklistReordered(int oldIndex, int newIndex) {
    setState(() {
      final item = _checklistItems.removeAt(oldIndex);
      _checklistItems.insert(newIndex, item);
    });
  }

  void _showValidationMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.surfaceHighest,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _createHabit() {
    final title = _titleController.text.trim();
    if (title.isEmpty) {
      _showValidationMessage('Escribe un nombre para el hábito.');
      return;
    }

    final description = _descriptionController.text.trim();
    final selectedCategory =
        widget.categories.firstWhere((c) => c.id == _categoryId);

    final isYesNo = _evaluationType == HabitEvaluationType.yesNo;
    final isAmount = _evaluationType == HabitEvaluationType.amount;
    final isChecklist = _evaluationType == HabitEvaluationType.checklist;
    final isTimer = _evaluationType == HabitEvaluationType.timer;

    final initial = widget.initialHabit;

    final habit = Habit(
      id: initial?.id ?? DateTime.now().microsecondsSinceEpoch.toString(),
      title: title,
      categoryId: _categoryId,
      description: description.isNotEmpty ? description : null,
      icon: selectedCategory.icon,
      iconColor: selectedCategory.iconColor,
      imagePath: initial?.imagePath,
      yesNo: isYesNo ? (initial?.yesNo ?? false) : null,
      current: isAmount ? (initial?.current ?? 0) : null,
      target: isAmount ? _target : null,
      unit: isAmount ? _unit : null,
      checklist: isChecklist && _checklistItems.isNotEmpty
          ? List.from(_checklistItems)
          : null,
      completedChecklist:
          isChecklist ? (initial?.completedChecklist ?? []) : null,
      estimatedDuration: isTimer
          ? Duration(
              hours: _timerHours,
              minutes: _timerMinutes,
              seconds: _timerSeconds,
            )
          : null,
      frequency: _frequency,
      weekDays: _weekDays.contains(true) ? _weekDays : null,
      monthDays: _monthDays.isNotEmpty ? _monthDays : null,
      yearDays: _yearDays.isNotEmpty ? _yearDays : null,
      timesPerPeriod: _frequency == 'Algunas veces por período'
          ? _timesPerPeriod
          : null,
      periodType: _frequency == 'Algunas veces por período'
          ? _periodType
          : null,
      repeatInterval: (_frequency == 'Algunas veces por período' ||
              _frequency == 'Repetir')
          ? _repeatInterval
          : null,
      startDate: _startDate,
      endDate: _endDate,
      reminders: _reminders,
      isCompleted: initial?.isCompleted ?? false,
      points: initial?.points ?? (isYesNo ? 10 : 15),
    );

    if (initial == null) {
      // El llamador (home_screen) ya programa el hábito después de añadirlo,
      // así que no lo programamos aquí para evitar duplicados.
    }
    Navigator.of(context).pop(habit);
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
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
              CreateHabitStepIndicator(
              currentStep: _currentStep,
              totalSteps: 5,
            ),
            const SizedBox(height: 18),
            Text(
              _stepTitle,
              style: textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 400,
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  CreateHabitCategoryStep(
                    categories: widget.categories,
                    selectedId: _categoryId,
                    onSelected: (id) => setState(() => _categoryId = id),
                  ),
                  CreateHabitEvaluationTypeStep(
                    selected: _evaluationType,
                    onSelected: (type) => setState(() => _evaluationType = type),
                  ),
                  CreateHabitEvaluationConfigStep(
                    type: _evaluationType,
                    titleController: _titleController,
                    descriptionController: _descriptionController,
                    targetController: _targetController,
                    timerHoursController: _timerHoursController,
                    timerMinutesController: _timerMinutesController,
                    timerSecondsController: _timerSecondsController,
                    checklistController: _checklistController,
                    condition: _condition,
                    conditions: _conditions,
                    target: _target,
                    unit: _unit,
                    units: _units,
                    timerCondition: _timerCondition,
                    timerHours: _timerHours,
                    timerMinutes: _timerMinutes,
                    timerSeconds: _timerSeconds,
                    checklistItems: _checklistItems,
                    onConditionChanged: (value) => setState(() => _condition = value),
                    onTargetChanged: (value) => setState(() => _target = value),
                    onUnitChanged: (value) => setState(() => _unit = value),
                    onTimerConditionChanged: (value) => setState(() => _timerCondition = value),
                    onTimerHoursChanged: (value) => setState(() => _timerHours = value),
                    onTimerMinutesChanged: (value) => setState(() => _timerMinutes = value),
                    onTimerSecondsChanged: (value) => setState(() => _timerSeconds = value),
                    onChecklistAdded: () {
                      final text = _checklistController.text.trim();
                      if (text.isNotEmpty) {
                        setState(() {
                          _checklistItems.add(text);
                          _checklistController.clear();
                        });
                      }
                    },
                    onChecklistRemoved: (index) {
                      setState(() => _checklistItems.removeAt(index));
                    },
                    onChecklistReordered: _onChecklistReordered,
                  ),
                  CreateHabitFrequencyStep(
                    selected: _frequency,
                    frequencies: _frequencies,
                    weekDays: _weekDays,
                    monthDays: _monthDays,
                    yearDays: _yearDays,
                    timesPerPeriod: _timesPerPeriod,
                    periodType: _periodType,
                    repeatInterval: _repeatInterval,
                    onSelected: (value) => setState(() => _frequency = value),
                    onWeekDaysChanged: (value) => setState(() {
                      _weekDays.clear();
                      _weekDays.addAll(value);
                    }),
                    onMonthDaysChanged: (value) => setState(() {
                      _monthDays.clear();
                      _monthDays.addAll(value);
                    }),
                    onYearDaysChanged: (value) => setState(() {
                      _yearDays.clear();
                      _yearDays.addAll(value);
                    }),
                    onTimesPerPeriodChanged: (value) => setState(() => _timesPerPeriod = value),
                    onPeriodTypeChanged: (value) => setState(() => _periodType = value),
                    onRepeatIntervalChanged: (value) => setState(() => _repeatInterval = value),
                  ),
                  CreateHabitScheduleStep(
                    startDate: _startDate,
                    endDate: _endDate,
                    reminders: _reminders,
                    category: widget.categories.firstWhere(
                      (c) => c.id == _categoryId,
                      orElse: () => widget.categories.first,
                    ),
                    frequency: _frequency,
                    onStartDateChanged: (date) => setState(() => _startDate = date),
                    onEndDateChanged: (date) => setState(() => _endDate = date),
                    onRemindersChanged: (value) => setState(() => _reminders = value),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                if (_currentStep > 0)
                  Expanded(
                    child: GestureDetector(
                      onTap: _previousStep,
                      child: Container(
                        height: AppConstants.controlHeight,
                        decoration: BoxDecoration(
                          color: AppColors.surfaceHighest,
                          borderRadius: BorderRadius.circular(AppConstants.cardRadius),
                          border: Border.all(color: AppColors.borderDark),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          'Atrás',
                          style: textTheme.titleMedium?.copyWith(
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ),
                if (_currentStep > 0) const SizedBox(width: 12),
                Expanded(
                  flex: _currentStep > 0 ? 1 : 2,
                  child: GestureDetector(
                    onTap: _nextStep,
                    child: Container(
                      height: AppConstants.controlHeight,
                      decoration: AppDecorations.neonButton,
                      alignment: Alignment.center,
                      child: Text(
                        _currentStep == 4 ? 'Guardar' : 'Siguiente',
                        style: textTheme.titleMedium?.copyWith(
                          color: const Color(0xFF152000),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
        ),
      ),
    );
  }

  String get _stepTitle {
    switch (_currentStep) {
      case 0:
        return 'Selecciona la categoría';
      case 1:
        return 'Tipo de evaluación';
      case 2:
        return 'Configura el hábito';
      case 3:
        return 'Frecuencia';
      case 4:
        return '¿Cuándo empieza?';
      default:
        return '';
    }
  }
}
