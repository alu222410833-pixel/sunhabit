import 'package:sunhabit/features/categories/data/category_model.dart';
import 'package:sunhabit/features/habits/data/habit_model.dart';

/// Resultado intermedio del parseo de un comando exprés.
///
/// No es un [Habit] todavía porque faltan datos derivados de la categoría
/// (icono, color) y los valores por defecto deben aplicarse en la UI.
class ParsedExpressHabit {
  final String? title;
  final String? categoryId;
  final HabitEvaluationType? evaluationType;
  final int? target;
  final String? unit;
  final String? condition;
  final Duration? estimatedDuration;
  final List<String>? checklist;
  final String? frequency;
  final List<bool>? weekDays;
  final List<int>? monthDays;
  final int? timesPerPeriod;
  final String? periodType;
  final int? repeatInterval;
  final DateTime? startDate;
  final List<Reminder>? reminders;
  final List<String> errors;

  const ParsedExpressHabit({
    this.title,
    this.categoryId,
    this.evaluationType,
    this.target,
    this.unit,
    this.condition,
    this.estimatedDuration,
    this.checklist,
    this.frequency,
    this.weekDays,
    this.monthDays,
    this.timesPerPeriod,
    this.periodType,
    this.repeatInterval,
    this.startDate,
    this.reminders,
    this.errors = const [],
  });

  bool get isValid =>
      errors.isEmpty &&
      title != null &&
      title!.isNotEmpty &&
      categoryId != null &&
      evaluationType != null;
}

/// Parsea comandos de texto del Sistema Exprés a un objeto intermedio.
///
/// Formato canónico:
/// `Título en Categoría | Métrica | Frecuencia | Fecha inicio | Hora recordatorio`
///
/// Ejemplos válidos:
///   `Beber agua en Salud | Cantidad: 2 vasos al menos | Todos los días | hoy | 8:00 AM`
///   `Leer en Estudio | Cantidad: 20 pag. exactamente | Lunes, Miércoles, Viernes | 28/08/2026 | 9:00 PM`
///   `Meditar en Salud | Timer: 10 min | Todos los días | mañana | 7:00 AM`
///   `Rutina mañana en Trabajo | Lista: Revisar correos, Planificar día, Café | Lunes a Viernes | hoy | 8:30 AM`
class ExpressHabitParser {
  final List<Category> categories;

  ExpressHabitParser({required this.categories});

  ParsedExpressHabit parse(String input) {
    final trimmed = input.trim();
    if (trimmed.isEmpty) {
      return const ParsedExpressHabit(errors: ['Comando vacío']);
    }

    final parts = trimmed.split('|').map((s) => s.trim()).toList();
    final errors = <String>[];

    final titleAndCategory = _parseTitleAndCategory(parts.isNotEmpty ? parts[0] : '');
    if (titleAndCategory.title == null || titleAndCategory.title!.isEmpty) {
      errors.add('Falta el título del hábito');
    }
    if (titleAndCategory.categoryId == null) {
      errors.add('No se reconoció la categoría');
    }

    final metric = _parseMetric(parts.length > 1 ? parts[1] : '');
    if (metric.evaluationType == null) {
      errors.add(
        'No se reconoció la métrica. Usa: Sí/No, Cantidad: X unidad, Timer: X min o Lista: a, b',
      );
    }

    final frequency = _parseFrequency(parts.length > 2 ? parts[2] : '');
    final startDate = _parseDate(parts.length > 3 ? parts[3] : '');
    final reminders = _parseTime(parts.length > 4 ? parts[4] : '');

    return ParsedExpressHabit(
      title: titleAndCategory.title,
      categoryId: titleAndCategory.categoryId,
      evaluationType: metric.evaluationType,
      target: metric.target,
      unit: metric.unit,
      condition: metric.condition,
      estimatedDuration: metric.estimatedDuration,
      checklist: metric.checklist,
      frequency: frequency.frequency,
      weekDays: frequency.weekDays,
      monthDays: frequency.monthDays,
      timesPerPeriod: frequency.timesPerPeriod,
      periodType: frequency.periodType,
      repeatInterval: frequency.repeatInterval,
      startDate: startDate,
      reminders: reminders,
      errors: errors,
    );
  }

  ({String? title, String? categoryId}) _parseTitleAndCategory(String segment) {
    if (segment.isEmpty) return (title: null, categoryId: null);

    // Formato "Título en Categoría" o "Título En Categoría".
    final lowerSegment = segment.toLowerCase();
    const separator = ' en ';
    final index = lowerSegment.lastIndexOf(separator);
    if (index != -1) {
      final titlePart = segment.substring(0, index).trim();
      final categoryPart = segment.substring(index + separator.length).trim();
      final categoryId = _findCategoryId(categoryPart);
      if (categoryId != null) {
        return (title: titlePart, categoryId: categoryId);
      }
      return (title: segment, categoryId: null);
    }

    // Si el segmento coincide exactamente con una categoría, lo usamos como título
    // y categoría (el usuario escribió solo la categoría, p. ej. "Salud").
    final categoryId = _findCategoryId(segment);
    if (categoryId != null) {
      return (title: segment, categoryId: categoryId);
    }

    // Sin categoría reconocida: usamos el texto como título y la primera categoría
    // como fallback para no bloquear la vista previa.
    return (
      title: segment,
      categoryId: categories.isNotEmpty ? categories.first.id : null,
    );
  }

  String? _findCategoryId(String name) {
    final lower = name.toLowerCase();
    for (final category in categories) {
      if (category.name.toLowerCase() == lower ||
          category.id.toLowerCase() == lower) {
        return category.id;
      }
    }
    return null;
  }

  ({HabitEvaluationType? evaluationType, int? target, String? unit, String? condition, Duration? estimatedDuration, List<String>? checklist}) _parseMetric(String segment) {
    if (segment.isEmpty) {
      return (
        evaluationType: HabitEvaluationType.yesNo,
        target: null,
        unit: null,
        condition: null,
        estimatedDuration: null,
        checklist: null,
      );
    }

    final lower = segment.toLowerCase();
    final value = segment.substring(segment.indexOf(':') + 1).trim();

    if (lower.startsWith('cantidad:') || lower.startsWith('cant:')) {
      return (
        evaluationType: HabitEvaluationType.amount,
        target: _parseAmountTarget(value),
        unit: _parseAmountUnit(value),
        condition: _parseCondition(value),
        estimatedDuration: null,
        checklist: null,
      );
    }

    if (lower.startsWith('timer:') ||
        lower.startsWith('tiempo:') ||
        lower.startsWith('duración:')) {
      return (
        evaluationType: HabitEvaluationType.timer,
        target: null,
        unit: null,
        condition: _parseCondition(value),
        estimatedDuration: _parseDuration(value),
        checklist: null,
      );
    }

    if (lower.startsWith('lista:') ||
        lower.startsWith('checklist:') ||
        lower.startsWith('tareas:')) {
      final separator = value.contains(';') ? ';' : ',';
      final items = value
          .split(separator)
          .map((s) => s.trim())
          .where((s) => s.isNotEmpty)
          .toList();
      return (
        evaluationType: HabitEvaluationType.checklist,
        target: null,
        unit: null,
        condition: null,
        estimatedDuration: null,
        checklist: items,
      );
    }

    if (lower == 'sí/no' ||
        lower == 'si/no' ||
        lower == 'síno' ||
        lower == 'sino' ||
        lower == 'sí' ||
        lower == 'si') {
      return (
        evaluationType: HabitEvaluationType.yesNo,
        target: null,
        unit: null,
        condition: null,
        estimatedDuration: null,
        checklist: null,
      );
    }

    // Por defecto, si no se reconoce, interpretamos Sí/No para no bloquear.
    return (
      evaluationType: HabitEvaluationType.yesNo,
      target: null,
      unit: null,
      condition: null,
      estimatedDuration: null,
      checklist: null,
    );
  }

  int? _parseAmountTarget(String value) {
    final match = RegExp(r'(\d+)').firstMatch(value);
    return match != null ? int.tryParse(match.group(1)!) : null;
  }

  String? _parseAmountUnit(String value) {
    final match = RegExp(r'\d+\s*([a-zA-Záéíóúñ_.\s]+?)(?:\s+(?:al menos|menos de|exactamente|libre))?$').firstMatch(value);
    if (match == null) return null;
    return match.group(1)?.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');
  }

  String? _parseCondition(String value) {
    final lower = value.toLowerCase();
    const conditions = ['al menos', 'menos de', 'exactamente', 'libre'];
    for (final condition in conditions) {
      if (lower.contains(condition)) return condition;
    }
    return null;
  }

  Duration? _parseDuration(String value) {
    int totalMinutes = 0;
    bool found = false;

    // Horas: "1 hora", "1 h", "2 horas"
    final hourMatch = RegExp(r'(\d+)\s*(?:h(?:ora)?s?|hora)\b').firstMatch(value);
    if (hourMatch != null) {
      totalMinutes += (int.tryParse(hourMatch.group(1)!) ?? 0) * 60;
      found = true;
    }

    // Minutos: "30 min", "45min", "30 minutos"
    final minMatch = RegExp(r'(\d+)\s*(?:min(?:uto)?s?|min)\b').firstMatch(value);
    if (minMatch != null) {
      totalMinutes += (int.tryParse(minMatch.group(1)!) ?? 0);
      found = true;
    }

    // Segundos: "30 seg", "30s"
    final secMatch = RegExp(r'(\d+)\s*(?:seg(?:undo)?s?|s)\b').firstMatch(value);
    if (secMatch != null) {
      totalMinutes += (int.tryParse(secMatch.group(1)!) ?? 0) ~/ 60;
      found = true;
    }

    if (!found) {
      // Último recurso: cualquier número suelto lo tratamos como minutos.
      final match = RegExp(r'(\d+)').firstMatch(value);
      if (match != null) {
        totalMinutes = int.tryParse(match.group(1)!) ?? 0;
        found = true;
      }
    }

    return found ? Duration(minutes: totalMinutes) : null;
  }

  ({String? frequency, List<bool>? weekDays, List<int>? monthDays, int? timesPerPeriod, String? periodType, int? repeatInterval}) _parseFrequency(String segment) {
    if (segment.isEmpty) {
      return (frequency: 'Todos los días', weekDays: null, monthDays: null, timesPerPeriod: null, periodType: null, repeatInterval: null);
    }

    final lower = segment.toLowerCase();

    if (lower == 'todos los días' || lower == 'diario' || lower == 'diaria') {
      return (frequency: 'Todos los días', weekDays: null, monthDays: null, timesPerPeriod: null, periodType: null, repeatInterval: null);
    }

    // Días específicos del mes.
    if (lower.startsWith('días mes:') ||
        lower.startsWith('dias mes:') ||
        lower.startsWith('mes:')) {
      final value = segment.substring(segment.indexOf(':') + 1).trim();
      final days = value
          .split(RegExp(r'[,\s]+'))
          .map(int.tryParse)
          .where((d) => d != null && d >= 1 && d <= 31)
          .cast<int>()
          .toList();
      if (days.isNotEmpty) {
        return (
          frequency: 'Días específicos del mes',
          weekDays: null,
          monthDays: days,
          timesPerPeriod: null,
          periodType: null,
          repeatInterval: null,
        );
      }
    }

    // Algunas veces por período.
    final periodMatch = RegExp(r'(\d+)\s*veces?\s*por\s*(semana|mes|año)').firstMatch(lower);
    if (periodMatch != null) {
      return (
        frequency: 'Algunas veces por período',
        weekDays: null,
        monthDays: null,
        timesPerPeriod: int.tryParse(periodMatch.group(1)!) ?? 1,
        periodType: _normalizePeriodType(periodMatch.group(2)!),
        repeatInterval: null,
      );
    }

    // Repetir cada X días.
    final repeatMatch = RegExp(r'cada\s*(\d+)\s*(?:días?|dias?)').firstMatch(lower);
    if (repeatMatch != null) {
      return (
        frequency: 'Repetir',
        weekDays: null,
        monthDays: null,
        timesPerPeriod: null,
        periodType: null,
        repeatInterval: int.tryParse(repeatMatch.group(1)!) ?? 1,
      );
    }

    // Días exactos de la semana (el caso más común).
    final weekDays = _parseWeekDays(segment);
    if (weekDays != null) {
      return (
        frequency: 'Días exactos de la semana',
        weekDays: weekDays,
        monthDays: null,
        timesPerPeriod: null,
        periodType: null,
        repeatInterval: null,
      );
    }

    return (frequency: 'Todos los días', weekDays: null, monthDays: null, timesPerPeriod: null, periodType: null, repeatInterval: null);
  }

  String _normalizePeriodType(String value) {
    switch (value.toLowerCase()) {
      case 'semana':
        return 'semana';
      case 'mes':
        return 'mes';
      case 'año':
        return 'año';
      default:
        return 'semana';
    }
  }

  List<bool>? _parseWeekDays(String segment) {
    final map = <String, int>{
      'lunes': 0,
      'martes': 1,
      'miércoles': 2,
      'miercoles': 2,
      'jueves': 3,
      'viernes': 4,
      'sábado': 5,
      'sabado': 5,
      'domingo': 6,
      'lun': 0,
      'mar': 1,
      'mié': 2,
      'mie': 2,
      'jue': 3,
      'vie': 4,
      'sáb': 5,
      'sab': 5,
      'dom': 6,
      'l': 0,
      'm': 1,
      'x': 2,
      'j': 3,
      'v': 4,
      's': 5,
      'd': 6,
    };

    final days = List<bool>.filled(7, false);
    bool found = false;

    final tokens = segment
        .toLowerCase()
        .replaceAll(RegExp(r'[\-a/]'), ' ')
        .split(RegExp(r'[,\s]+'))
        .where((s) => s.isNotEmpty)
        .toList();

    for (final token in tokens) {
      final dayIndex = map[token];
      if (dayIndex != null) {
        days[dayIndex] = true;
        found = true;
      }
    }

    return found ? days : null;
  }

  DateTime? _parseDate(String segment) {
    if (segment.trim().isEmpty) return DateTime.now();

    final lower = segment.toLowerCase().trim();
    final now = DateTime.now();

    if (lower == 'hoy') return now;
    if (lower == 'mañana' || lower == 'manana') {
      return now.add(const Duration(days: 1));
    }

    // Formatos: 20/08/2026, 20-08-2026, 20.08.2026, 20/08/26
    final match = RegExp(r'(\d{1,2})[/.\-](\d{1,2})[/.\-](\d{2,4})').firstMatch(segment);
    if (match != null) {
      final day = int.tryParse(match.group(1)!) ?? 0;
      final month = int.tryParse(match.group(2)!) ?? 0;
      int year = int.tryParse(match.group(3)!) ?? now.year;
      if (year < 100) year += year < 50 ? 2000 : 1900;

      if (day >= 1 && day <= 31 && month >= 1 && month <= 12) {
        return DateTime(year, month, day);
      }
    }

    return now;
  }

  List<Reminder>? _parseTime(String segment) {
    if (segment.trim().isEmpty) return const [];

    final lower = segment.toLowerCase().trim();
    final cleaned = lower.replaceAll('.', '').replaceAll(' hrs', ' h');

    int hour = 0;
    int minute = 0;

    // Formato 12h primero para evitar que el parser 24h se coma "8:00 pm".
    final h12Match = RegExp(r'(\d{1,2})(?::(\d{2}))?\s*(am|pm)').firstMatch(cleaned);
    if (h12Match != null) {
      hour = int.tryParse(h12Match.group(1)!) ?? 0;
      minute = int.tryParse(h12Match.group(2) ?? '0') ?? 0;
      final period = h12Match.group(3);
      if (period == 'pm' && hour != 12) hour += 12;
      if (period == 'am' && hour == 12) hour = 0;
      return [Reminder(hour: hour, minute: minute)];
    }

    // Formato 24h: "20:00", "20h", "20 h"
    final h24Match = RegExp(r'(\d{1,2}):(\d{2})\s*(?:h)?').firstMatch(cleaned);
    if (h24Match != null) {
      hour = int.tryParse(h24Match.group(1)!) ?? 0;
      minute = int.tryParse(h24Match.group(2)!) ?? 0;
      return [Reminder(hour: hour, minute: minute)];
    }

    // "8 h", "8h" sin minutos, asume minutos = 0.
    final simpleMatch = RegExp(r'(\d{1,2})\s*h').firstMatch(cleaned);
    if (simpleMatch != null) {
      hour = int.tryParse(simpleMatch.group(1)!) ?? 0;
      return [Reminder(hour: hour, minute: 0)];
    }

    return const [];
  }
}
