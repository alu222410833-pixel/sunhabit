import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sunhabit/features/categories/data/category_model.dart';
import 'package:sunhabit/features/habits/data/habit_model.dart';
import 'package:sunhabit/features/habits/domain/express_habit_parser.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const categories = <Category>[
    Category(
      id: 'health',
      name: 'Salud',
      color: Colors.green,
      icon: Icons.favorite,
      iconColor: Colors.green,
    ),
    Category(
      id: 'study',
      name: 'Estudio',
      color: Colors.purple,
      icon: Icons.book,
      iconColor: Colors.purple,
    ),
    Category(
      id: 'work',
      name: 'Trabajo',
      color: Colors.orange,
      icon: Icons.work,
      iconColor: Colors.orange,
    ),
  ];

  late ExpressHabitParser parser;

  setUp(() {
    parser = ExpressHabitParser(categories: categories);
  });

  group('Título y categoría', () {
    test('parsea título y categoría con "en"', () {
      final result = parser.parse('Beber agua en Salud | Sí/No');
      expect(result.title, 'Beber agua');
      expect(result.categoryId, 'health');
      expect(result.errors, isEmpty);
    });

    test('ignora mayúsculas/minúsculas en categoría', () {
      final result = parser.parse('Leer en estudio | Sí/No');
      expect(result.categoryId, 'study');
      expect(result.title, 'Leer');
    });

    test('usa el texto completo como título si no hay categoría reconocida', () {
      final result = parser.parse('Pasear al perro | Sí/No');
      expect(result.title, 'Pasear al perro');
      expect(result.categoryId, 'health');
    });
  });

  group('Métricas', () {
    test('Sí/No por defecto', () {
      final result = parser.parse('Meditar en Salud | Sí/No');
      expect(result.evaluationType, HabitEvaluationType.yesNo);
    });

    test('Cantidad con unidad y condición', () {
      final result = parser.parse('Beber agua en Salud | Cantidad: 2 vasos al menos');
      expect(result.evaluationType, HabitEvaluationType.amount);
      expect(result.target, 2);
      expect(result.unit, 'vasos');
      expect(result.condition, 'al menos');
    });

    test('Cantidad con exactamente', () {
      final result = parser.parse('Leer en Estudio | Cantidad: 20 pag. exactamente');
      expect(result.target, 20);
      expect(result.unit, 'pag.');
      expect(result.condition, 'exactamente');
    });

    test('Timer en minutos', () {
      final result = parser.parse('Meditar en Salud | Timer: 10 min');
      expect(result.evaluationType, HabitEvaluationType.timer);
      expect(result.estimatedDuration, const Duration(minutes: 10));
    });

    test('Timer en horas', () {
      final result = parser.parse('Estudiar en Estudio | Timer: 1 hora');
      expect(result.estimatedDuration, const Duration(minutes: 60));
    });

    test('Checklist', () {
      final result = parser.parse('Rutina en Trabajo | Lista: Revisar correos, Planificar día, Café');
      expect(result.evaluationType, HabitEvaluationType.checklist);
      expect(result.checklist, [
        'Revisar correos',
        'Planificar día',
        'Café',
      ]);
    });
  });

  group('Frecuencias', () {
    test('Todos los días por defecto', () {
      final result = parser.parse('Hábito en Salud | Sí/No');
      expect(result.frequency, 'Todos los días');
    });

    test('Días exactos de la semana', () {
      final result = parser.parse('Hábito en Salud | Sí/No | Lunes, Miércoles, Viernes');
      expect(result.frequency, 'Días exactos de la semana');
      expect(result.weekDays, [true, false, true, false, true, false, false]);
    });

    test('Días exactos con abreviaturas', () {
      final result = parser.parse('Hábito en Salud | Sí/No | L, X, V');
      expect(result.frequency, 'Días exactos de la semana');
      expect(result.weekDays, [true, false, true, false, true, false, false]);
    });

    test('Días específicos del mes', () {
      final result = parser.parse('Hábito en Salud | Sí/No | Días mes: 1, 15');
      expect(result.frequency, 'Días específicos del mes');
      expect(result.monthDays, [1, 15]);
    });

    test('Repetir cada X días', () {
      final result = parser.parse('Hábito en Salud | Sí/No | Cada 3 días');
      expect(result.frequency, 'Repetir');
      expect(result.repeatInterval, 3);
    });

    test('Veces por período', () {
      final result = parser.parse('Hábito en Salud | Sí/No | 3 veces por semana');
      expect(result.frequency, 'Algunas veces por período');
      expect(result.timesPerPeriod, 3);
      expect(result.periodType, 'semana');
    });
  });

  group('Fechas y horas', () {
    test('hoy', () {
      final result = parser.parse('Hábito en Salud | Sí/No | Todos los días | hoy | 8:00 AM');
      final now = DateTime.now();
      expect(result.startDate?.year, now.year);
      expect(result.startDate?.month, now.month);
      expect(result.startDate?.day, now.day);
    });

    test('mañana', () {
      final result = parser.parse('Hábito en Salud | Sí/No | Todos los días | mañana | 8:00 AM');
      final tomorrow = DateTime.now().add(const Duration(days: 1));
      expect(result.startDate?.year, tomorrow.year);
      expect(result.startDate?.month, tomorrow.month);
      expect(result.startDate?.day, tomorrow.day);
    });

    test('fecha numérica', () {
      final result = parser.parse('Hábito en Salud | Sí/No | Todos los días | 28/08/2026 | 8:00 PM');
      expect(result.startDate, DateTime(2026, 8, 28));
      expect(result.reminders?.length, 1);
      expect(result.reminders?.first.hour, 20);
      expect(result.reminders?.first.minute, 0);
    });

    test('hora formato 24h', () {
      final result = parser.parse('Hábito en Salud | Sí/No | Todos los días | hoy | 20:30');
      expect(result.reminders?.length, 1);
      expect(result.reminders?.first.hour, 20);
      expect(result.reminders?.first.minute, 30);
    });
  });

  group('Comando vacío', () {
    test('devuelve error si el comando está vacío', () {
      final result = parser.parse('');
      expect(result.errors, contains('Comando vacío'));
      expect(result.isValid, isFalse);
    });
  });
}
