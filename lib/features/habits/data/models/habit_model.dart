// ignore_for_file: non_const_argument_for_const_parameter

import 'package:flutter/material.dart';
import 'package:sunhabit/features/habits/data/models/habit_evaluation_type.dart';
import 'package:sunhabit/features/habits/data/models/reminder_model.dart';

export 'package:sunhabit/features/habits/data/models/habit_evaluation_type.dart';
export 'package:sunhabit/features/habits/data/models/reminder_model.dart';

/// Modelo de datos que representa un hábito en la aplicación.
///
/// Un hábito puede ser de diferentes tipos:
/// - Sí/No (campo [yesNo])
/// - Con cantidad medible (campos [current], [target], [unit])
/// - Con duración estimada (campo [estimatedDuration])
/// - Lista de ítems (campo [checklist])
class Habit {
  final String id; // Identificador único del hábito
  final String title; // Nombre visible del hábito
  final String categoryId; // Id de la categoría a la que pertenece
  final String? description; // Descripción opcional del hábito

  final Duration? estimatedDuration; // Tiempo estimado para completarlo
  final String? iconAsset; // Ruta de un icono como asset
  final String? imagePath; // Ruta de una imagen asociada
  final IconData? icon; // Icono de Flutter
  final Color? iconColor; // Color del icono

  final int? current; // Progreso actual (hábitos medibles)
  final int? target; // Meta a alcanzar (hábitos medibles)
  final String? unit; // Unidad de medida (min, vasos, pasos, etc.)
  final bool? yesNo; // Indica si es un hábito de tipo sí/no

  final List<String>? checklist; // Ítems para hábitos tipo checklist
  final List<String>? completedChecklist; // Ítems completados del checklist

  final String? frequency; // Frecuencia del hábito (ej. "todos los días")
  final List<bool>? weekDays; // Días seleccionados de la semana [L, M, M, J, V, S, D]
  final List<int>? monthDays; // Días seleccionados del mes [1..31]
  final List<DateTime>? yearDays; // Fechas específicas del año seleccionadas
  final int? timesPerPeriod; // Veces por período (ej. 1)
  final String? periodType; // Tipo de período: semana, mes, año
  final int? repeatInterval; // Repetir cada X días
  final DateTime? startDate; // Fecha de inicio
  final DateTime? endDate; // Fecha de finalización opcional
  final List<Reminder> reminders; // Recordatorios con hora y tipo

  bool isCompleted; // Estado de completado del día
  int points; // Puntos otorgados al completar el hábito

  Habit({
    required this.id,
    required this.title,
    required this.categoryId,
    this.description,
    this.estimatedDuration,
    this.iconAsset,
    this.imagePath,
    this.icon,
    this.iconColor,
    this.current,
    this.target,
    this.unit,
    this.yesNo,
    this.checklist,
    this.completedChecklist,
    this.frequency,
    this.weekDays,
    this.monthDays,
    this.yearDays,
    this.timesPerPeriod,
    this.periodType,
    this.repeatInterval,
    this.startDate,
    this.endDate,
    this.reminders = const [],
    this.isCompleted = false,
    this.points = 0,
  });

  /// Tipo de evaluación inferido o configurado para este hábito.
  HabitEvaluationType get evaluationType {
    if (checklist != null && checklist!.isNotEmpty) {
      return HabitEvaluationType.checklist;
    }
    if (estimatedDuration != null) {
      return HabitEvaluationType.timer;
    }
    if (target != null || unit != null) {
      return HabitEvaluationType.amount;
    }
    return HabitEvaluationType.yesNo;
  }

  /// Devuelve los minutos desde medianoche (0..1439) del recordatorio más temprano
  /// que aplique para [date], o null si no tiene recordatorios para ese día.
  int? earliestReminderMinutesForDate(DateTime date) {
    if (reminders.isEmpty) return null;
    final weekdayIndex = date.weekday - 1;
    int? earliest;
    for (final reminder in reminders) {
      if (reminder.weekDays != null && reminder.weekDays!.isNotEmpty) {
        if (weekdayIndex < 0 ||
            weekdayIndex >= reminder.weekDays!.length ||
            !reminder.weekDays![weekdayIndex]) {
          continue;
        }
      }
      final totalMinutes = reminder.hour * 60 + reminder.minute;
      if (earliest == null || totalMinutes < earliest) {
        earliest = totalMinutes;
      }
    }
    return earliest;
  }

  /// Devuelve la hora formateada (ej. "14:11") del recordatorio más temprano
  /// para [date], o null si no tiene recordatorios para ese día.
  String? reminderTimeTextForDate(DateTime date) {
    final minutes = earliestReminderMinutesForDate(date);
    if (minutes == null) return null;
    return _formatTime(minutes);
  }

  /// Devuelve los minutos desde medianoche (0..1439) del recordatorio más temprano para hoy,
  /// o null si no tiene recordatorios configurados.
  int? get earliestReminderMinutes =>
      earliestReminderMinutesForDate(DateTime.now());

  /// Devuelve un texto legible con el progreso del hábito.
  /// - Sí/No → "Sí" o "No"
  /// - Medible → "current / target unit"
  /// - Duración → "HH:MM:SS" (o "Completado" si está finalizado)
  /// - Checklist → "X / Y tareas"
  /// - Sin datos → null
  String? get progressText {
    if (checklist != null && checklist!.isNotEmpty) {
      final done = completedChecklist?.length ?? 0;
      return '$done / ${checklist!.length} tareas';
    }
    if (yesNo != null) return yesNo! ? 'Sí' : 'No';
    if (current != null && target != null && unit != null) {
      return '$current / $target $unit';
    }
    if (estimatedDuration != null) {
      if (isCompleted) return 'Completado';
      return _formatDuration(estimatedDuration!);
    }
    return null;
  }

  static String _formatTime(int totalMinutes) {
    final h = (totalMinutes ~/ 60).toString().padLeft(2, '0');
    final m = (totalMinutes % 60).toString().padLeft(2, '0');
    return '$h:$m';
  }

  static String _formatDuration(Duration d) {
    final h = d.inHours.toString().padLeft(2, '0');
    final m = (d.inMinutes % 60).toString().padLeft(2, '0');
    final s = (d.inSeconds % 60).toString().padLeft(2, '0');
    return '$h:$m:$s';
  }

  Habit copyWith({
    String? id,
    String? title,
    String? categoryId,
    String? description,
    Duration? estimatedDuration,
    String? iconAsset,
    String? imagePath,
    IconData? icon,
    Color? iconColor,
    int? current,
    int? target,
    String? unit,
    bool? yesNo,
    List<String>? checklist,
    List<String>? completedChecklist,
    String? frequency,
    List<bool>? weekDays,
    List<int>? monthDays,
    List<DateTime>? yearDays,
    int? timesPerPeriod,
    String? periodType,
    int? repeatInterval,
    DateTime? startDate,
    DateTime? endDate,
    List<Reminder>? reminders,
    bool? isCompleted,
    int? points,
  }) {
    return Habit(
      id: id ?? this.id,
      title: title ?? this.title,
      categoryId: categoryId ?? this.categoryId,
      description: description ?? this.description,
      estimatedDuration: estimatedDuration ?? this.estimatedDuration,
      iconAsset: iconAsset ?? this.iconAsset,
      imagePath: imagePath ?? this.imagePath,
      icon: icon ?? this.icon,
      iconColor: iconColor ?? this.iconColor,
      current: current ?? this.current,
      target: target ?? this.target,
      unit: unit ?? this.unit,
      yesNo: yesNo ?? this.yesNo,
      checklist: checklist ?? this.checklist,
      completedChecklist: completedChecklist ?? this.completedChecklist,
      frequency: frequency ?? this.frequency,
      weekDays: weekDays ?? this.weekDays,
      monthDays: monthDays ?? this.monthDays,
      yearDays: yearDays ?? this.yearDays,
      timesPerPeriod: timesPerPeriod ?? this.timesPerPeriod,
      periodType: periodType ?? this.periodType,
      repeatInterval: repeatInterval ?? this.repeatInterval,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      reminders: reminders ?? this.reminders,
      isCompleted: isCompleted ?? this.isCompleted,
      points: points ?? this.points,
    );
  }

  /// Devuelve true si el hábito debe mostrarse en la fecha dada
  /// según su configuración de frecuencia.
  bool isScheduledFor(DateTime date) {
    final target = DateTime(date.year, date.month, date.day);
    final start = startDate != null
        ? DateTime(startDate!.year, startDate!.month, startDate!.day)
        : null;
    final end = endDate != null
        ? DateTime(endDate!.year, endDate!.month, endDate!.day)
        : null;

    if (start != null && target.isBefore(start)) return false;
    if (end != null && target.isAfter(end)) return false;

    switch (frequency) {
      case 'Todos los días':
      case null:
        return true;
      case 'Días exactos de la semana':
        if (weekDays == null || weekDays!.isEmpty) return false;
        final index = target.weekday - 1;
        if (index < 0 || index >= weekDays!.length) return false;
        return weekDays![index];
      case 'Días específicos del mes':
        return monthDays?.contains(target.day) ?? false;
      case 'Días específicos del año':
        if (yearDays == null || yearDays!.isEmpty) return false;
        return yearDays!.any(
          (yd) => yd.month == target.month && yd.day == target.day,
        );
      case 'Algunas veces por período':
      case 'Repetir':
        final interval = repeatInterval ?? 1;
        final base = start ?? target;
        final diff = target.difference(base).inDays;
        return diff >= 0 && diff % interval == 0;
      default:
        return true;
    }
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'categoryId': categoryId,
        'description': description,
        'estimatedDuration': estimatedDuration?.inSeconds,
        'iconAsset': iconAsset,
        'imagePath': imagePath,
        'icon': icon != null
            ? {
                'codePoint': icon!.codePoint,
                'fontFamily': icon!.fontFamily ?? 'MaterialIcons',
              }
            : null,
        'iconColor': iconColor?.toARGB32(),
        'current': current,
        'target': target,
        'unit': unit,
        'yesNo': yesNo,
        'checklist': checklist,
        'completedChecklist': completedChecklist,
        'frequency': frequency,
        'weekDays': weekDays,
        'monthDays': monthDays,
        'yearDays': yearDays?.map((d) => d.toIso8601String()).toList(),
        'timesPerPeriod': timesPerPeriod,
        'periodType': periodType,
        'repeatInterval': repeatInterval,
        'startDate': startDate?.toIso8601String(),
        'endDate': endDate?.toIso8601String(),
        'reminders': reminders.map((r) => r.toJson()).toList(),
        'isCompleted': isCompleted,
        'points': points,
      };

  factory Habit.fromJson(Map<String, dynamic> json) {
    final iconJson = json['icon'] as Map<String, dynamic>?;
    return Habit(
      id: json['id'] as String,
      title: json['title'] as String,
      categoryId: json['categoryId'] as String,
      description: json['description'] as String?,
      estimatedDuration: json['estimatedDuration'] != null
          ? Duration(seconds: json['estimatedDuration'] as int)
          : null,
      iconAsset: json['iconAsset'] as String?,
      imagePath: json['imagePath'] as String?,
      icon: iconJson != null
          ? IconData(
              iconJson['codePoint'] as int,
              fontFamily: iconJson['fontFamily'] as String? ?? 'MaterialIcons',
            )
          : null,
      iconColor:
          json['iconColor'] != null ? Color(json['iconColor'] as int) : null,
      current: json['current'] as int?,
      target: json['target'] as int?,
      unit: json['unit'] as String?,
      yesNo: json['yesNo'] as bool?,
      checklist: (json['checklist'] as List<dynamic>?)?.cast<String>(),
      completedChecklist:
          (json['completedChecklist'] as List<dynamic>?)?.cast<String>(),
      frequency: json['frequency'] as String?,
      weekDays: (json['weekDays'] as List<dynamic>?)?.cast<bool>(),
      monthDays: (json['monthDays'] as List<dynamic>?)?.cast<int>(),
      yearDays: (json['yearDays'] as List<dynamic>?)
          ?.map((e) => DateTime.parse(e as String))
          .toList(),
      timesPerPeriod: json['timesPerPeriod'] as int?,
      periodType: json['periodType'] as String?,
      repeatInterval: json['repeatInterval'] as int?,
      startDate: json['startDate'] != null
          ? DateTime.parse(json['startDate'] as String)
          : null,
      endDate: json['endDate'] != null
          ? DateTime.parse(json['endDate'] as String)
          : null,
      reminders: (json['reminders'] as List<dynamic>?)
              ?.map((e) => Reminder.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      isCompleted: json['isCompleted'] as bool? ?? false,
      points: json['points'] as int? ?? 0,
    );
  }
}
