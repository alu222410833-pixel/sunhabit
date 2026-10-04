/// Registro diario de un hábito.
///
/// Guarda el estado de un hábito en una fecha concreta para construir
/// un historial de cumplimiento.
class HabitLog {
  final String habitId;
  final DateTime date;
  final bool isCompleted;
  final int? currentValue;
  final List<String>? completedChecklist;

  const HabitLog({
    required this.habitId,
    required this.date,
    this.isCompleted = false,
    this.currentValue,
    this.completedChecklist,
  });

  HabitLog copyWith({
    String? habitId,
    DateTime? date,
    bool? isCompleted,
    int? currentValue,
    List<String>? completedChecklist,
  }) =>
      HabitLog(
        habitId: habitId ?? this.habitId,
        date: date ?? this.date,
        isCompleted: isCompleted ?? this.isCompleted,
        currentValue: currentValue ?? this.currentValue,
        completedChecklist: completedChecklist ?? this.completedChecklist,
      );

  Map<String, dynamic> toJson() => {
        'habitId': habitId,
        'date': date.toIso8601String(),
        'isCompleted': isCompleted,
        'currentValue': currentValue,
        'completedChecklist': completedChecklist,
      };

  factory HabitLog.fromJson(Map<String, dynamic> json) => HabitLog(
        habitId: json['habitId'] as String,
        date: DateTime.parse(json['date'] as String),
        isCompleted: json['isCompleted'] as bool? ?? false,
        currentValue: json['currentValue'] as int?,
        completedChecklist: (json['completedChecklist'] as List<dynamic>?)
            ?.map((e) => e as String)
            .toList(),
      );
}
