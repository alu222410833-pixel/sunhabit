import 'package:flutter/material.dart';

/// Fila superior que muestra la fecha en español.
///
/// Incluye un botón para abrir un calendario (date picker) y elegir el día
/// cuyos hábitos se quieren visualizar.
class HomeDateRow extends StatelessWidget {
  final TextTheme textTheme;

  /// Fecha que se está mostrando (la seleccionada por el usuario o la actual).
  final DateTime selectedDate;

  /// Se invoca cuando el usuario elige una nueva fecha en el calendario.
  final ValueChanged<DateTime> onDateSelected;

  const HomeDateRow({
    super.key,
    required this.textTheme,
    required this.selectedDate,
    required this.onDateSelected,
  });

  /// Devuelve la fecha formateada, por ejemplo:
  /// "Domingo, 30 de agosto".
  String _formatDate(DateTime date) {
    const weekdays = [
      'Lunes',
      'Martes',
      'Miércoles',
      'Jueves',
      'Viernes',
      'Sábado',
      'Domingo',
    ];
    const months = [
      'enero',
      'febrero',
      'marzo',
      'abril',
      'mayo',
      'junio',
      'julio',
      'agosto',
      'septiembre',
      'octubre',
      'noviembre',
      'diciembre',
    ];
    return '${weekdays[date.weekday - 1]}, ${date.day} de ${months[date.month - 1]}';
  }

  Future<void> _openCalendar(BuildContext context) async {
    final today = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(today.year - 5),
      lastDate: DateTime(today.year + 1, today.month, today.day),
      locale: const Locale('es'),
    );
    if (picked != null) {
      onDateSelected(DateTime(picked.year, picked.month, picked.day));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18),
      child: SizedBox(
        height: 44,
        child: Row(
          children: [
            Expanded(child: Text(_formatDate(selectedDate), style: textTheme.titleMedium)),
            IconButton(
              visualDensity: VisualDensity.compact,
              onPressed: () => _openCalendar(context),
              icon: const Icon(Icons.calendar_today_outlined, size: 19),
            ),
          ],
        ),
      ),
    );
  }
}
