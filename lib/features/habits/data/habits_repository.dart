import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:sunhabit/core/services/storage_service.dart';
import 'package:sunhabit/core/theme/app_colors.dart';
import 'package:sunhabit/features/categories/data/category_model.dart';
import 'package:sunhabit/features/habits/data/habit_log_model.dart';
import 'package:sunhabit/features/habits/data/habit_model.dart';

class HabitsRepository extends ChangeNotifier {
  /// Instancia singleton usada por la app en producción.
  static HabitsRepository? _instance;

  /// Devuelve siempre la misma instancia para la app.
  factory HabitsRepository() =>
      _instance ??= HabitsRepository._internal(StorageService());

  /// Constructor para tests. Permite inyectar un [StorageService] concreto
  /// y crear instancias aisladas, sin afectar el singleton de producción.
  factory HabitsRepository.test(StorageService storage) =>
      HabitsRepository._internal(storage);

  /// Limpia la instancia singleton. Útil entre tests que usan [HabitsRepository()].
  static void resetInstance() => _instance = null;

  HabitsRepository._internal(this._storage) {
    _habits.clear();
    _logs.clear();
  }

  static const String habitsKey = 'habits';
  static const String categoriesKey = 'categories';
  static const String logsKey = 'habit_logs';

  final StorageService _storage;
  final List<Habit> _habits = [];
  final List<HabitLog> _logs = [];

  /// Día (año+mes+ día) de la última vez que se ejecutó el reset diario.
  /// Se usa para detectar cambios de día en caliente.
  DateTime? _lastResetDay;

  Future<void> initialize() async {
    await _storage.init();
    await _load();
    _resetDailyCompletion();
  }

  /// Recarga hábitos, categorías y logs desde el almacenamiento.
  ///
  /// Útil tras importar un backup o cuando otro proceso modifica los datos
  /// subyacentes.
  Future<void> reload() async {
    await _load();
    _resetDailyCompletion();
    notifyListeners();
  }

  /// Comprueba si el día ha cambiado desde el último reset y, si es así,
  /// resetea el estado de completado de todos los hábitos.
  ///
  /// Pensado para llamarse periódicamente (Timer) o al volver de background.
  void checkDayChange() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    if (_lastResetDay == null ||
        today.year != _lastResetDay!.year ||
        today.month != _lastResetDay!.month ||
        today.day != _lastResetDay!.day) {
      _resetDailyCompletion();
    }
  }

  List<Habit> getHabits() => List.unmodifiable(_habits);

  /// Devuelve los hábitos programados para [date] con su estado proyectado
  /// al día indicado.
  ///
  /// - Para **hoy**: usa el estado "vivo" actual del hábito (que ya está
  ///   sincronizado con el log del día por [_resetDailyCompletion] y
  ///   [_logHabit]).
  /// - Para **otros días**: aplica el `HabitLog` de esa fecha si existe
  ///   (`isCompleted`, `current` para amount, `completedChecklist` para
  ///   checklist, `yesNo` para sí/no). Si no hay log, devuelve el hábito con
  ///   estado "en blanco" (no completado).
  ///
  /// Esto permite visualizar el cumplimiento real de cualquier día desde el
  /// calendario, sin modificar el estado vivo que se usa para editar hoy.
  List<Habit> getHabitsForDate(DateTime date) {
    final target = DateTime(date.year, date.month, date.day);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final isToday = target == today;

    final result = <Habit>[];
    for (final habit in _habits) {
      if (!habit.isScheduledFor(target)) continue;

      if (isToday) {
        result.add(habit);
        continue;
      }

      // Busca el log del día objetivo.
      final log = _logs.cast<HabitLog?>().firstWhere(
            (l) =>
                l != null &&
                l.habitId == habit.id &&
                l.date.year == target.year &&
                l.date.month == target.month &&
                l.date.day == target.day,
            orElse: () => null,
          );

      if (log != null) {
        result.add(habit.copyWith(
          isCompleted: log.isCompleted,
          current: log.currentValue ?? habit.current,
          completedChecklist: log.completedChecklist ?? habit.completedChecklist,
          yesNo: habit.evaluationType == HabitEvaluationType.yesNo
              ? log.isCompleted
              : habit.yesNo,
        ));
      } else {
        // Sin log: estado en blanco para ese día.
        result.add(habit.copyWith(
          isCompleted: false,
          current: habit.evaluationType == HabitEvaluationType.amount
              ? 0
              : habit.current,
          completedChecklist:
              habit.evaluationType == HabitEvaluationType.checklist
                  ? <String>[]
                  : habit.completedChecklist,
          yesNo: habit.evaluationType == HabitEvaluationType.yesNo
              ? false
              : habit.yesNo,
        ));
      }
    }
    result.sort((a, b) {
      // 1. Hábitos no completados primero; hábitos completados abajo.
      if (a.isCompleted != b.isCompleted) {
        return a.isCompleted ? 1 : -1;
      }

      // 2. Ordenar por la hora del recordatorio más temprano (más temprano primero).
      final aTime = a.earliestReminderMinutes;
      final bTime = b.earliestReminderMinutes;

      if (aTime != null && bTime != null) {
        final cmp = aTime.compareTo(bTime);
        if (cmp != 0) return cmp;
      } else if (aTime != null && bTime == null) {
        return -1;
      } else if (aTime == null && bTime != null) {
        return 1;
      }

      // 3. Desempate por título alfabético.
      return a.title.toLowerCase().compareTo(b.title.toLowerCase());
    });

    return List.unmodifiable(result);
  }

  List<Category> getCategories() => List.unmodifiable(defaultCategories);

  List<HabitLog> getHabitLogs(String habitId) => List.unmodifiable(
        _logs
            .where((l) => l.habitId == habitId)
            .toList()
          ..sort((a, b) => a.date.compareTo(b.date)),
      );

  Future<void> _load() async {
    final habitsJson = await _storage.getString(habitsKey);
    final categoriesJson = await _storage.getString(categoriesKey);
    final logsJson = await _storage.getString(logsKey);

    if (categoriesJson != null) {
      try {
        final List<dynamic> decoded = jsonDecode(categoriesJson);
        defaultCategories
          ..clear()
          ..addAll(decoded
              .map((e) => Category.fromJson(e as Map<String, dynamic>)));
      } catch (e, st) {
        debugPrint('[HabitsRepository] Error loading categories: $e\n$st');
      }
    } else {
      _resetDefaultCategories();
    }

    if (habitsJson != null) {
      try {
        final List<dynamic> decoded = jsonDecode(habitsJson);
        _habits
        ..clear()
        ..addAll(
            decoded.map((e) => Habit.fromJson(e as Map<String, dynamic>)));
      } catch (e, st) {
        debugPrint('[HabitsRepository] Error loading habits: $e\n$st');
      }
    } else {
      _resetDefaultHabits();
    }

    if (logsJson != null) {
      try {
        final List<dynamic> decoded = jsonDecode(logsJson);
        _logs
          ..clear()
          ..addAll(
              decoded.map((e) => HabitLog.fromJson(e as Map<String, dynamic>)));
      } catch (e, st) {
        debugPrint('[HabitsRepository] Error loading logs: $e\n$st');
      }
    }
  }

  /// Resetea el estado de completado de los hábitos al cambiar de día.
  ///
  /// Si el último log de un hábito no corresponde a hoy, se reinician
  /// `isCompleted`, `current` (amount) y `completedChecklist` para que el
  /// progreso diario empiece de cero. El historial acumulado en `_logs`
  /// se conserva intacto.
  void _resetDailyCompletion() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    _lastResetDay = today;
    var changed = false;

    for (var i = 0; i < _habits.length; i++) {
      final habit = _habits[i];
      final logsForHabit = _logs
          .where((l) => l.habitId == habit.id)
          .toList()
        ..sort((a, b) => a.date.compareTo(b.date));

      final hasTodayLog = logsForHabit.any((l) =>
          l.date.year == today.year &&
          l.date.month == today.month &&
          l.date.day == today.day);

      if (hasTodayLog) {
        // Ya hay un registro de hoy: respetar el estado guardado en el log.
        final todayLog = logsForHabit.lastWhere((l) =>
            l.date.year == today.year &&
            l.date.month == today.month &&
            l.date.day == today.day);
        if (habit.isCompleted != todayLog.isCompleted) {
          _habits[i] = habit.copyWith(
            isCompleted: todayLog.isCompleted,
            current: todayLog.currentValue ?? habit.current,
            completedChecklist: todayLog.completedChecklist ??
                habit.completedChecklist,
          );
          changed = true;
        }
      } else {
        // No hay log de hoy: resetear el estado diario.
        if (habit.isCompleted ||
            habit.current != null ||
            habit.completedChecklist != null) {
          _habits[i] = habit.copyWith(
            isCompleted: false,
            current: habit.evaluationType == HabitEvaluationType.amount
                ? 0
                : habit.current,
            completedChecklist:
                habit.evaluationType == HabitEvaluationType.checklist
                    ? <String>[]
                    : habit.completedChecklist,
          );
          changed = true;
        }
      }
    }

    if (changed) _save();
  }

  void _resetDefaultCategories() {
    defaultCategories
      ..clear()
      ..addAll([
        const Category(
          id: 'health',
          name: 'Salud',
          color: AppColors.green,
          icon: Icons.favorite_outline_rounded,
          iconColor: AppColors.green,
        ),
        const Category(
          id: 'study',
          name: 'Estudio',
          color: AppColors.purple,
          icon: Icons.menu_book_rounded,
          iconColor: AppColors.purple,
        ),
        const Category(
          id: 'work',
          name: 'Trabajo',
          color: AppColors.gold,
          icon: Icons.work_outline_rounded,
          iconColor: AppColors.gold,
        ),
      ]);
  }

  void _resetDefaultHabits() {
    _habits
      ..clear()
      ..addAll([
        Habit(
          id: '1',
          title: 'Beber 2L de agua',
          categoryId: 'health',
          current: 2,
          target: 2,
          unit: 'L',
          icon: Icons.water_drop,
          iconColor: AppColors.water,
          points: 10,
          isCompleted: true,
        ),
        Habit(
          id: '2',
          title: 'Entrenamiento',
          categoryId: 'health',
          estimatedDuration: const Duration(minutes: 45),
          icon: Icons.fitness_center,
          iconColor: AppColors.green,
          points: 20,
          isCompleted: true,
        ),
        Habit(
          id: '3',
          title: 'Leer 20 páginas',
          categoryId: 'study',
          current: 20,
          target: 20,
          unit: 'pag.',
          icon: Icons.menu_book,
          iconColor: AppColors.gold,
          points: 15,
          isCompleted: true,
        ),
        Habit(
          id: '4',
          title: 'Meditación',
          categoryId: 'health',
          estimatedDuration: const Duration(minutes: 10),
          icon: Icons.self_improvement,
          iconColor: AppColors.green,
          points: 10,
          isCompleted: true,
        ),
        Habit(
          id: '5',
          title: 'Sin azúcar',
          categoryId: 'health',
          yesNo: false,
          icon: Icons.block,
          iconColor: Colors.redAccent,
          points: 5,
          isCompleted: false,
        ),
      ]);
  }

  Future<void> _save() async {
    final habits = _habits.map((h) => h.toJson()).toList();
    final categories = defaultCategories.map((c) => c.toJson()).toList();
    final logs = _logs.map((l) => l.toJson()).toList();

    notifyListeners();

    await _storage.setString(habitsKey, jsonEncode(habits));
    await _storage.setString(categoriesKey, jsonEncode(categories));
    await _storage.setString(logsKey, jsonEncode(logs));
  }

  void addHabit(Habit habit) {
    _habits.add(habit);
    _save();
  }

  void addCategory(Category category) {
    defaultCategories.add(category);
    _save();
  }

  void updateCategory(Category updated) {
    final index = defaultCategories.indexWhere((c) => c.id == updated.id);
    if (index != -1) {
      defaultCategories[index] = updated;
      _save();
    }
  }

  void updateHabit(Habit updated) {
    final index = _habits.indexWhere((h) => h.id == updated.id);
    if (index != -1) {
      _habits[index] = updated;
      _logHabit(updated.id);
      _save();
    }
  }

  void deleteHabit(String id) {
    _habits.removeWhere((h) => h.id == id);
    _logs.removeWhere((l) => l.habitId == id);
    _save();
  }

  Category? getCategoryById(String id) {
    try {
      return defaultCategories.firstWhere((c) => c.id == id);
    } catch (_) {
      return null;
    }
  }

  /// Resuelve el sonido efectivo para una alarma:
  /// 1. Sonido específico del recordatorio si fue configurado.
  /// 2. Sonido predeterminado de la categoría del hábito si existe.
  /// 3. null (sonido predeterminado del sistema).
  String? getEffectiveSound(Habit habit, Reminder reminder) {
    if (reminder.soundPath != null && reminder.soundPath!.isNotEmpty) {
      return reminder.soundPath;
    }
    final category = getCategoryById(habit.categoryId);
    if (category?.defaultSoundPath != null &&
        category!.defaultSoundPath!.isNotEmpty) {
      return category.defaultSoundPath;
    }
    return null;
  }

  Habit? getHabitById(String id) {
    try {
      return _habits.firstWhere((h) => h.id == id);
    } catch (_) {
      return null;
    }
  }

  void _logHabit(String id, {int? overrideCurrentValue}) {
    final habit = getHabitById(id);
    if (habit == null) return;

    final today = DateTime.now();
    final logDate = DateTime(today.year, today.month, today.day);
    final index = _logs.indexWhere(
      (l) =>
          l.habitId == id &&
          l.date.year == logDate.year &&
          l.date.month == logDate.month &&
          l.date.day == logDate.day,
    );

    final currentValue = overrideCurrentValue ?? switch (habit.evaluationType) {
      HabitEvaluationType.amount => habit.current,
      HabitEvaluationType.yesNo => habit.yesNo == true ? 1 : 0,
      _ => null,
    };

    final newLog = HabitLog(
      habitId: id,
      date: logDate,
      isCompleted: habit.isCompleted,
      currentValue: currentValue,
      completedChecklist: habit.completedChecklist != null
          ? List<String>.from(habit.completedChecklist!)
          : null,
    );

    if (index != -1) {
      _logs[index] = newLog;
    } else {
      _logs.add(newLog);
    }
  }

  void completeHabit(String id) {
    final habit = getHabitById(id);
    if (habit != null) {
      habit.isCompleted = true;
      if (habit.evaluationType == HabitEvaluationType.yesNo) {
        final index = _habits.indexWhere((h) => h.id == id);
        if (index != -1) {
          _habits[index] = habit.copyWith(yesNo: true, isCompleted: true);
        }
      }
    }
    _logHabit(id);
    _save();
  }

  /// Completa un hábito de tipo cronómetro y guarda la duración real
  /// transcurrida (en segundos) en el log del día.
  void completeHabitWithDuration(String id, int seconds) {
    final index = _habits.indexWhere((h) => h.id == id);
    if (index != -1) {
      _habits[index] = _habits[index].copyWith(isCompleted: true);
    }
    _logHabit(id, overrideCurrentValue: seconds);
    _save();
  }

  /// Guarda la duración transcurrida de un hábito tipo cronómetro sin marcarlo
  /// como completado. Útil cuando el usuario pulsa "Finalizar" manualmente.
  void saveHabitDuration(String id, int seconds) {
    _logHabit(id, overrideCurrentValue: seconds);
    _save();
  }

  void uncompleteHabit(String id) {
    final habit = getHabitById(id);
    if (habit != null) {
      habit.isCompleted = false;
      if (habit.evaluationType == HabitEvaluationType.yesNo) {
        final index = _habits.indexWhere((h) => h.id == id);
        if (index != -1) {
          _habits[index] = habit.copyWith(yesNo: false, isCompleted: false);
        }
      }
    }
    _logHabit(id);
    _save();
  }

  Future<void> setHabitYesNo(String id, bool value) async {
    final index = _habits.indexWhere((h) => h.id == id);
    if (index != -1) {
      final habit = _habits[index];
      _habits[index] = habit.copyWith(
        yesNo: value,
        isCompleted: value,
      );
    }
    _logHabit(id);
    await _save();
  }

  Future<void> incrementHabitAmount(String id, int delta) async {
    final index = _habits.indexWhere((h) => h.id == id);
    if (index != -1) {
      final habit = _habits[index];
      final currentVal = habit.current ?? 0;
      final newVal = (currentVal + delta).clamp(0, 999999);
      final isDone = habit.target != null ? newVal >= habit.target! : false;
      _habits[index] = habit.copyWith(
        current: newVal,
        isCompleted: isDone,
      );
    }
    _logHabit(id);
    await _save();
  }

  Future<void> setHabitAmount(String id, int amount) async {
    final index = _habits.indexWhere((h) => h.id == id);
    if (index != -1) {
      final habit = _habits[index];
      final current = amount.clamp(0, 999999);
      final isDone = habit.target != null ? current >= habit.target! : false;
      _habits[index] = habit.copyWith(
        current: current,
        isCompleted: isDone,
      );
    }
    _logHabit(id);
    await _save();
  }

  Future<void> toggleChecklistItem(String id, String item) async {
    final index = _habits.indexWhere((h) => h.id == id);
    if (index != -1) {
      final habit = _habits[index];
      final checklist = habit.checklist ?? [];
      final completed = List<String>.from(habit.completedChecklist ?? []);
      if (completed.contains(item)) {
        completed.remove(item);
      } else {
        completed.add(item);
      }
      final allDone = checklist.isNotEmpty &&
          checklist.every((i) => completed.contains(i));
      _habits[index] = habit.copyWith(
        completedChecklist: completed,
        isCompleted: allDone,
      );
    }
    _logHabit(id);
    await _save();
  }
}
