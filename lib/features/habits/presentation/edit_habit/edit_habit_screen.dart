import 'package:flutter/material.dart';
import 'package:sunhabit/core/services/reminder_service.dart';
import 'package:sunhabit/core/theme/app_colors.dart';
import 'package:sunhabit/core/theme/app_decorations.dart';
import 'package:sunhabit/features/categories/data/category_model.dart';
import 'package:sunhabit/features/habits/data/habit_model.dart';
import 'package:sunhabit/features/habits/data/habits_repository.dart';
import 'package:sunhabit/features/habits/presentation/edit_habit/pickers/category_picker.dart';
import 'package:sunhabit/features/habits/presentation/edit_habit/pickers/checklist_editor.dart';
import 'package:sunhabit/features/habits/presentation/edit_habit/pickers/evaluation_type_picker.dart';
import 'package:sunhabit/features/habits/presentation/edit_habit/pickers/frequency_editor.dart';
import 'package:sunhabit/features/habits/presentation/edit_habit/pickers/goal_editor.dart';
import 'package:sunhabit/features/habits/presentation/edit_habit/pickers/reminders_editor.dart';
import 'package:sunhabit/features/habits/presentation/edit_habit/widgets/edit_habit_text_field_tile.dart';
import 'package:sunhabit/features/habits/presentation/edit_habit/widgets/edit_habit_tile.dart';

class EditHabitScreen extends StatefulWidget {
  final Habit habit;
  final bool isEmbedded;

  const EditHabitScreen({
    super.key,
    required this.habit,
    this.isEmbedded = false,
  });

  @override
  State<EditHabitScreen> createState() => EditHabitScreenState();
}

class EditHabitScreenState extends State<EditHabitScreen> {
  final _repository = HabitsRepository();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _targetController = TextEditingController();
  final _timerHoursController = TextEditingController();
  final _timerMinutesController = TextEditingController();
  final _timerSecondsController = TextEditingController();

  late String _categoryId;
  late List<Reminder> _reminders;
  late String _frequency;
  late List<bool> _weekDays;
  late List<int> _monthDays;
  late List<DateTime> _yearDays;
  late int _timesPerPeriod;
  late String _periodType;
  late int _repeatInterval;
  late DateTime _startDate;
  late DateTime? _endDate;

  late HabitEvaluationType _evaluationType;
  late int _target;
  late String _unit;
  late List<String> _checklist;
  late int _timerHours;
  late int _timerMinutes;
  late int _timerSeconds;

  final _frequencies = const [
    'Todos los días',
    'Días exactos de la semana',
    'Días específicos del mes',
    'Días específicos del año',
    'Algunas veces por período',
    'Repetir',
  ];

  final _units = const [
    'Unidades',
    'min',
    'L',
    'pag.',
    'vasos',
    'pasos',
    'repeticiones',
  ];

  final _periodTypes = const ['semana', 'mes', 'año'];

  @override
  void initState() {
    super.initState();
    final h = widget.habit;
    _categoryId = h.categoryId;
    _reminders = List.from(h.reminders);
    _frequency = h.frequency ?? 'Todos los días';
    _weekDays = List.from(h.weekDays ?? List.filled(7, false));
    _monthDays = List.from(h.monthDays ?? []);
    _yearDays = List.from(h.yearDays ?? []);
    _timesPerPeriod = h.timesPerPeriod ?? 1;
    _periodType = h.periodType ?? 'semana';
    _repeatInterval = h.repeatInterval ?? 1;
    _startDate = h.startDate ?? DateTime.now();
    _endDate = h.endDate;

    _evaluationType = h.evaluationType;
    _target = h.target ?? 1;
    _unit = h.unit ?? 'Unidades';
    _checklist = List.from(h.checklist ?? []);

    final duration = h.estimatedDuration ?? const Duration(minutes: 10);
    _timerHours = duration.inHours;
    _timerMinutes = duration.inMinutes.remainder(60);
    _timerSeconds = duration.inSeconds.remainder(60);

    _titleController.text = h.title;
    _descriptionController.text = h.description ?? '';
    _targetController.text = _target.toString();
    _timerHoursController.text = _timerHours.toString();
    _timerMinutesController.text = _timerMinutes.toString();
    _timerSecondsController.text = _timerSeconds.toString();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _targetController.dispose();
    _timerHoursController.dispose();
    _timerMinutesController.dispose();
    _timerSecondsController.dispose();
    super.dispose();
  }

  Category? get _category => _repository.getCategoryById(_categoryId);

  Future<void> _save() async {
    final title = _titleController.text.trim();
    if (title.isEmpty) return;

    final description = _descriptionController.text.trim();
    final category = _category ?? _repository.getCategories().first;

    final isYesNo = _evaluationType == HabitEvaluationType.yesNo;
    final isAmount = _evaluationType == HabitEvaluationType.amount;
    final isChecklist = _evaluationType == HabitEvaluationType.checklist;
    final isTimer = _evaluationType == HabitEvaluationType.timer;

    final updated = Habit(
      id: widget.habit.id,
      title: title,
      categoryId: _categoryId,
      description: description.isNotEmpty ? description : null,
      iconAsset: widget.habit.iconAsset,
      imagePath: widget.habit.imagePath,
      icon: category.icon,
      iconColor: category.iconColor,
      current: isAmount ? (widget.habit.current ?? 0) : null,
      target: isAmount ? _target : null,
      unit: isAmount ? _unit : null,
      yesNo: isYesNo ? (widget.habit.yesNo ?? false) : null,
      checklist: isChecklist && _checklist.isNotEmpty ? List.from(_checklist) : null,
      completedChecklist: isChecklist ? (widget.habit.completedChecklist ?? []) : null,
      estimatedDuration: isTimer
          ? Duration(hours: _timerHours, minutes: _timerMinutes, seconds: _timerSeconds)
          : null,
      frequency: _frequency,
      weekDays: _frequency == 'Días exactos de la semana' && _weekDays.contains(true)
          ? _weekDays
          : null,
      monthDays: _frequency == 'Días específicos del mes' && _monthDays.isNotEmpty
          ? _monthDays
          : null,
      yearDays: _frequency == 'Días específicos del año' && _yearDays.isNotEmpty
          ? _yearDays
          : null,
      timesPerPeriod: _frequency == 'Algunas veces por período' ? _timesPerPeriod : null,
      periodType: _frequency == 'Algunas veces por período' ? _periodType : null,
      repeatInterval: (_frequency == 'Algunas veces por período' || _frequency == 'Repetir')
          ? _repeatInterval
          : null,
      startDate: _startDate,
      endDate: _endDate,
      reminders: _reminders,
      isCompleted: widget.habit.isCompleted,
      points: widget.habit.points,
    );

    _repository.updateHabit(updated);
    await ReminderService.instance.scheduleHabit(updated);
    if (widget.isEmbedded) return;
    if (mounted) Navigator.of(context).pop();
  }

  Future<DateTime?> _pickDate({required DateTime initial}) async {
    return showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.dark(
            primary: AppColors.neonGreen,
            onPrimary: Color(0xFF152000),
            surface: AppColors.surfaceElevated,
            onSurface: AppColors.textPrimary,
          ),
        ),
        child: child!,
      ),
    );
  }

  Future<void> _addMonthDay() async {
    final picked = await _pickDate(initial: _startDate);
    if (picked == null) return;
    if (_monthDays.contains(picked.day)) return;
    setState(() {
      _monthDays.add(picked.day);
    });
  }

  String get _frequencySummary {
    switch (_frequency) {
      case 'Todos los días':
        return 'Todos los días';
      case 'Días exactos de la semana':
        final days = const ['L', 'M', 'X', 'J', 'V', 'S', 'D'];
        final selected = <String>[];
        for (var i = 0; i < _weekDays.length; i++) {
          if (_weekDays[i]) selected.add(days[i]);
        }
        return selected.isEmpty ? 'Días exactos de la semana' : selected.join(', ');
      case 'Días específicos del mes':
        return _monthDays.isEmpty
            ? 'Días específicos del mes'
            : _monthDays.map((d) => d.toString()).join(', ');
      case 'Días específicos del año':
        return _yearDays.isEmpty
            ? 'Días específicos del año'
            : '${_yearDays.length} días';
      case 'Algunas veces por período':
        return '$_timesPerPeriod veces por $_periodType';
      case 'Repetir':
        return 'Cada $_repeatInterval días';
      default:
        return _frequency;
    }
  }

  String get _goalSummary {
    switch (_evaluationType) {
      case HabitEvaluationType.yesNo:
        return 'Marcar como completado';
      case HabitEvaluationType.amount:
        return 'Al menos $_target $_unit';
      case HabitEvaluationType.timer:
        final h = _timerHours.toString().padLeft(2, '0');
        final m = _timerMinutes.toString().padLeft(2, '0');
        final s = _timerSeconds.toString().padLeft(2, '0');
        return '$h:$m:$s';
      case HabitEvaluationType.checklist:
        return '${_checklist.length} objetivos';
    }
  }

  Future<void> _editFrequency() async {
    await showFrequencyEditor(
      context,
      frequency: _frequency,
      weekDays: _weekDays,
      monthDays: _monthDays,
      timesPerPeriod: _timesPerPeriod,
      periodType: _periodType,
      repeatInterval: _repeatInterval,
      frequencies: _frequencies,
      periodTypes: _periodTypes,
      onAddMonthDay: _addMonthDay,
      onFrequencyChanged: (f) => setState(() => _frequency = f),
      onWeekDayToggled: (index, selected) => setState(() => _weekDays[index] = selected),
      onMonthDayRemoved: (day) => setState(() => _monthDays.remove(day)),
      onTimesPerPeriodChanged: (n) => setState(() => _timesPerPeriod = n),
      onPeriodTypeChanged: (p) => setState(() => _periodType = p),
      onRepeatIntervalChanged: (n) => setState(() => _repeatInterval = n),
    );
  }

  Future<void> _editGoal() async {
    await showGoalEditor(
      context,
      evaluationType: _evaluationType,
      targetController: _targetController,
      units: _units,
      unit: _unit,
      timerHours: _timerHours,
      timerMinutes: _timerMinutes,
      timerSeconds: _timerSeconds,
      timerHoursController: _timerHoursController,
      timerMinutesController: _timerMinutesController,
      timerSecondsController: _timerSecondsController,
      onTargetChanged: (n) => setState(() => _target = n),
      onUnitChanged: (u) => setState(() => _unit = u),
      onTimerUpdated: _updateTimer,
    );
  }

  void _updateTimer() {
    setState(() {
      _timerHours = int.tryParse(_timerHoursController.text) ?? 0;
      _timerMinutes = int.tryParse(_timerMinutesController.text) ?? 0;
      _timerSeconds = int.tryParse(_timerSecondsController.text) ?? 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final category = _category;

    final content = DecoratedBox(
      decoration: AppDecorations.pageBackground,
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            EditHabitTextFieldTile(
              icon: Icons.edit,
              label: 'Nombre del hábito',
              hint: 'Nombre del hábito',
              controller: _titleController,
            ),
            const SizedBox(height: 12),
            EditHabitTile(
              icon: Icons.category,
              label: 'Categoría',
              onTap: () async {
                final picked = await showCategoryPicker(
                  context,
                  categories: _repository.getCategories(),
                  selectedCategoryId: _categoryId,
                );
                if (picked != null) setState(() => _categoryId = picked);
              },
              child: category == null
                  ? const Text('Seleccionar')
                  : Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(category.name, style: textTheme.bodyMedium),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: category.iconColor?.withValues(alpha: 0.2) ??
                                AppColors.neonGreen.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(category.icon ?? Icons.help_outline,
                              size: 16, color: category.iconColor),
                        ),
                      ],
                    ),
            ),
            const SizedBox(height: 12),
            EditHabitTextFieldTile(
              icon: Icons.info_outline,
              label: 'Descripción',
              hint: 'Añade una descripción',
              controller: _descriptionController,
            ),
            const SizedBox(height: 12),
            EditHabitTile(
              icon: Icons.notifications_none,
              label: 'Hora y recordatorios',
              value: _reminders.length.toString(),
              onTap: () => showRemindersEditor(
                context,
                reminders: _reminders,
                category: category,
                onRemindersChanged: (updated) =>
                    setState(() => _reminders = updated),
              ),
            ),
            const SizedBox(height: 12),
            EditHabitTile(
              icon: Icons.tune,
              label: 'Tipo de objetivo',
              onTap: () async {
                final picked = await showEvaluationTypePicker(
                  context,
                  current: _evaluationType,
                );
                if (picked != null) setState(() => _evaluationType = picked);
              },
              child: Text(evaluationLabel(_evaluationType), style: textTheme.bodyMedium),
            ),
            const SizedBox(height: 12),
            if (_evaluationType == HabitEvaluationType.amount) ...[
              EditHabitTile(
                icon: Icons.track_changes,
                label: 'Meta de cantidad',
                onTap: _editGoal,
                child: Text('$_target $_unit', style: textTheme.bodyMedium),
              ),
              const SizedBox(height: 12),
            ] else if (_evaluationType == HabitEvaluationType.timer) ...[
              EditHabitTile(
                icon: Icons.timer_outlined,
                label: 'Duración objetivo',
                onTap: _editGoal,
                child: Text(_goalSummary, style: textTheme.bodyMedium),
              ),
              const SizedBox(height: 12),
            ] else if (_evaluationType == HabitEvaluationType.checklist) ...[
              EditHabitTile(
                icon: Icons.checklist_rounded,
                label: 'Tareas del checklist',
                value: _checklist.length.toString(),
                onTap: () => showChecklistEditor(
                  context,
                  checklist: _checklist,
                  onUpdate: () => setState(() {}),
                ),
              ),
              const SizedBox(height: 12),
            ],
            EditHabitTile(
              icon: Icons.event_repeat,
              label: 'Frecuencia',
              onTap: _editFrequency,
              child: Text(_frequencySummary, style: textTheme.bodyMedium),
            ),
            const SizedBox(height: 12),
            EditHabitTile(
              icon: Icons.calendar_today,
              label: 'Fecha de inicio',
              onTap: () {
                _pickDate(initial: _startDate).then((date) {
                  if (date != null) setState(() => _startDate = date);
                });
              },
              child: Text(
                '${_startDate.day.toString().padLeft(2, '0')}/${_startDate.month.toString().padLeft(2, '0')}/${_startDate.year.toString().substring(2)}',
                style: textTheme.bodyMedium,
              ),
            ),
            const SizedBox(height: 12),
            EditHabitTile(
              icon: Icons.calendar_today,
              label: 'Fecha de fin',
              onTap: () {
                _pickDate(initial: _endDate ?? _startDate).then((date) {
                  if (date != null) setState(() => _endDate = date);
                });
              },
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _endDate == null
                        ? '-'
                        : '${_endDate!.day.toString().padLeft(2, '0')}/${_endDate!.month.toString().padLeft(2, '0')}/${_endDate!.year.toString().substring(2)}',
                    style: textTheme.bodyMedium,
                  ),
                  if (_endDate != null)
                    Padding(
                      padding: const EdgeInsets.only(left: 12),
                      child: GestureDetector(
                        onTap: () => setState(() => _endDate = null),
                        child: const Icon(Icons.delete_outline,
                            size: 18, color: AppColors.danger),
                      ),
                    ),
                ],
              ),
            ),
            if (widget.isEmbedded) ...[
              const SizedBox(height: 32),
              GestureDetector(
                onTap: _save,
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: AppDecorations.neonButton,
                  alignment: Alignment.center,
                  child: const Text(
                    'Guardar cambios',
                    style: TextStyle(
                      color: Color(0xFF152000),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
            const SizedBox(height: 32),
          ],
        ),
      ),
    );

    if (widget.isEmbedded) return content;

    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Editar'),
        actions: [
          TextButton(
            onPressed: _save,
            child: const Text(
              'Guardar',
              style: TextStyle(color: AppColors.neonGreen, fontWeight: FontWeight.w700),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: content,
    );
  }
}
