/// Plantilla rápida para el Sistema Exprés.
class ExpressHabitTemplate {
  final String label;
  final String icon; // Emoji simple para identificación visual.
  final String command;

  const ExpressHabitTemplate({
    required this.label,
    required this.icon,
    required this.command,
  });
}

/// Fecha de hoy formateada como DD/MM/AAAA.
String _today() {
  final now = DateTime.now();
  return '${now.day.toString().padLeft(2, '0')}/${now.month.toString().padLeft(2, '0')}/${now.year}';
}

/// Plantillas principales, una por tipo de evaluación.
final List<ExpressHabitTemplate> mainExpressTemplates = [
  ExpressHabitTemplate(
    label: 'Sí/No',
    icon: '✓',
    command: 'Nuevo hábito en Salud | Sí/No | Todos los días | ${_today()} | 8:00 AM',
  ),
  ExpressHabitTemplate(
    label: 'Cantidad',
    icon: '123',
    command: 'Beber agua en Salud | Cantidad: 2 vasos al menos | Todos los días | ${_today()} | 8:00 AM',
  ),
  ExpressHabitTemplate(
    label: 'Timer',
    icon: '⏱',
    command: 'Meditar en Salud | Timer: 10 min | Todos los días | ${_today()} | 7:00 AM',
  ),
  ExpressHabitTemplate(
    label: 'Checklist',
    icon: '☰',
    command: 'Rutina mañana en Trabajo | Lista: Revisar correos, Planificar día, Café | Lunes a Viernes | ${_today()} | 8:30 AM',
  ),
];

/// Plantillas adicionales de frecuencia para copiar y modificar.
final List<ExpressHabitTemplate> frequencyExpressTemplates = [
  ExpressHabitTemplate(
    label: 'Días de semana',
    icon: '✓',
    command: 'Hábito en Salud | Sí/No | Lunes, Miércoles, Viernes | ${_today()} | 8:00 AM',
  ),
  ExpressHabitTemplate(
    label: 'Días del mes',
    icon: '✓',
    command: 'Hábito en Salud | Sí/No | Días mes: 1, 15 | ${_today()} | 8:00 AM',
  ),
  ExpressHabitTemplate(
    label: 'Cada X días',
    icon: '✓',
    command: 'Hábito en Salud | Sí/No | Cada 3 días | ${_today()} | 8:00 AM',
  ),
  ExpressHabitTemplate(
    label: 'Veces por período',
    icon: '✓',
    command: 'Hábito en Salud | Sí/No | 3 veces por semana | ${_today()} | 8:00 AM',
  ),
];
