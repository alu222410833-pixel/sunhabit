import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sunhabit/features/categories/data/category_model.dart';
import 'package:sunhabit/features/habits/data/habit_log_model.dart';
import 'package:sunhabit/features/habits/data/habit_model.dart';
import 'package:sunhabit/features/habits/data/habits_repository.dart';
import 'package:sunhabit/features/habits/presentation/widgets/habit_visuals.dart';

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
    await HabitsRepository().initialize();
  });

  group('Habit.progressText', () {
    test('returns null when there is no progress data', () {
      final habit = Habit(id: '1', title: 'Test', categoryId: 'c1');
      expect(habit.progressText, isNull);
    });

    test('returns Sí/No for yes/no habits', () {
      final yes = Habit(id: '1', title: 'Test', categoryId: 'c1', yesNo: true);
      expect(yes.progressText, 'Sí');

      final no = Habit(id: '2', title: 'Test', categoryId: 'c1', yesNo: false);
      expect(no.progressText, 'No');
    });

    test('returns current / target unit for amount habits', () {
      final habit = Habit(
        id: '1',
        title: 'Test',
        categoryId: 'c1',
        current: 2,
        target: 5,
        unit: 'min',
      );
      expect(habit.progressText, '2 / 5 min');
    });

    test('returns HH:MM:SS for timer habits', () {
      final habit = Habit(
        id: '1',
        title: 'Test',
        categoryId: 'c1',
        estimatedDuration: const Duration(hours: 1, minutes: 5, seconds: 9),
      );
      expect(habit.progressText, '01:05:09');
    });

    test('returns completed / total tareas for checklist habits', () {
      final habit = Habit(
        id: '1',
        title: 'Test Checklist',
        categoryId: 'c1',
        checklist: ['Item 1', 'Item 2', 'Item 3'],
        completedChecklist: ['Item 1', 'Item 3'],
      );
      expect(habit.progressText, '2 / 3 tareas');
      expect(habit.evaluationType, HabitEvaluationType.checklist);
    });
  });

  group('Habit.evaluationType', () {
    test('correctly infers evaluation type', () {
      final timer = Habit(
        id: '1',
        title: 'Timer',
        categoryId: 'c1',
        estimatedDuration: const Duration(minutes: 15),
      );
      expect(timer.evaluationType, HabitEvaluationType.timer);

      final amount = Habit(
        id: '2',
        title: 'Amount',
        categoryId: 'c1',
        target: 2000,
        unit: 'ml',
      );
      expect(amount.evaluationType, HabitEvaluationType.amount);

      final yesNo = Habit(
        id: '3',
        title: 'YesNo',
        categoryId: 'c1',
        yesNo: false,
      );
      expect(yesNo.evaluationType, HabitEvaluationType.yesNo);
    });
  });

  group('Habit.isScheduledFor', () {
    test('returns true for Todos los días', () {
      final habit = Habit(
        id: '1',
        title: 'Test',
        categoryId: 'c1',
        frequency: 'Todos los días',
      );
      expect(habit.isScheduledFor(DateTime(2026, 8, 26)), true);
    });

    test('respects start and end dates', () {
      final habit = Habit(
        id: '1',
        title: 'Test',
        categoryId: 'c1',
        frequency: 'Todos los días',
        startDate: DateTime(2026, 8, 25),
        endDate: DateTime(2026, 8, 27),
      );
      expect(habit.isScheduledFor(DateTime(2026, 8, 24)), false);
      expect(habit.isScheduledFor(DateTime(2026, 8, 26)), true);
      expect(habit.isScheduledFor(DateTime(2026, 8, 28)), false);
    });

    test('returns true on selected week days', () {
      final habit = Habit(
        id: '1',
        title: 'Test',
        categoryId: 'c1',
        frequency: 'Días exactos de la semana',
        // Lunes y viernes (index 0 y 4)
        weekDays: [true, false, false, false, true, false, false],
      );
      // 2026-08-24 is Monday
      expect(habit.isScheduledFor(DateTime(2026, 8, 24)), true);
      // 2026-08-26 is Wednesday
      expect(habit.isScheduledFor(DateTime(2026, 8, 26)), false);
    });

    test('respects repeat interval', () {
      final start = DateTime(2026, 8, 24);
      final habit = Habit(
        id: '1',
        title: 'Test',
        categoryId: 'c1',
        frequency: 'Repetir',
        startDate: start,
        repeatInterval: 3,
      );
      expect(habit.isScheduledFor(start), true);
      expect(habit.isScheduledFor(start.add(const Duration(days: 3))), true);
      expect(habit.isScheduledFor(start.add(const Duration(days: 1))), false);
    });
  });

  group('Category & Sound Inheritance', () {
    test('resolves reminder specific sound when present', () {
      final habit = Habit(id: 'h1', title: 'H1', categoryId: 'health');
      const reminder = Reminder(
        hour: 8,
        minute: 0,
        type: 'Alarma',
        soundPath: '/custom/path.mp3',
      );
      final effective = HabitsRepository().getEffectiveSound(habit, reminder);
      expect(effective, '/custom/path.mp3');
    });

    test('falls back to category default sound when reminder has no sound', () {
      final cat = Category(
        id: 'cat_with_sound',
        name: 'Sound Cat',
        color: Colors.blue,
        defaultSoundPath: '/cat/sound.mp3',
      );
      HabitsRepository().addCategory(cat);

      final habit = Habit(id: 'h2', title: 'H2', categoryId: 'cat_with_sound');
      const reminder = Reminder(hour: 9, minute: 0, type: 'Alarma');
      final effective = HabitsRepository().getEffectiveSound(habit, reminder);
      expect(effective, '/cat/sound.mp3');
    });

    test('returns null when neither reminder nor category have sound', () {
      final habit = Habit(id: 'h3', title: 'H3', categoryId: 'health');
      const reminder = Reminder(hour: 10, minute: 0, type: 'Alarma');
      final effective = HabitsRepository().getEffectiveSound(habit, reminder);
      expect(effective, isNull);
    });
  });

  group('Habit, Category, Reminder and HabitLog serialization', () {
    test('Habit toJson/fromJson roundtrip preserves fields', () {
      final original = Habit(
        id: 'h1',
        title: 'Leer',
        categoryId: 'study',
        description: 'Prueba',
        current: 10,
        target: 20,
        unit: 'pag.',
        yesNo: true,
        checklist: ['A', 'B'],
        completedChecklist: ['A'],
        frequency: 'Todos los días',
        weekDays: [true, false, false, false, true, false, false],
        monthDays: [1, 15],
        yearDays: [DateTime(2026, 1, 1)],
        timesPerPeriod: 3,
        periodType: 'semana',
        repeatInterval: 2,
        startDate: DateTime(2026, 1, 1),
        endDate: DateTime(2026, 12, 31),
        reminders: const [
          Reminder(hour: 8, minute: 0, type: 'Notificación'),
        ],
        isCompleted: true,
        points: 25,
      );
      final json = original.toJson();
      final restored = Habit.fromJson(json);
      expect(restored.id, original.id);
      expect(restored.title, original.title);
      expect(restored.categoryId, original.categoryId);
      expect(restored.current, original.current);
      expect(restored.target, original.target);
      expect(restored.unit, original.unit);
      expect(restored.yesNo, original.yesNo);
      expect(restored.checklist, original.checklist);
      expect(restored.completedChecklist, original.completedChecklist);
      expect(restored.frequency, original.frequency);
      expect(restored.weekDays, original.weekDays);
      expect(restored.monthDays, original.monthDays);
      expect(restored.yearDays?.length, original.yearDays?.length);
      expect(restored.timesPerPeriod, original.timesPerPeriod);
      expect(restored.periodType, original.periodType);
      expect(restored.repeatInterval, original.repeatInterval);
      expect(restored.isCompleted, original.isCompleted);
      expect(restored.points, original.points);
      expect(restored.reminders.length, original.reminders.length);
    });

    test('Category toJson/fromJson roundtrip preserves fields', () {
      const original = Category(
        id: 'c1',
        name: 'Work',
        color: Colors.red,
        defaultSoundPath: '/sound.mp3',
        defaultAudioStartSeconds: 5,
        defaultAudioDurationSeconds: 25,
      );
      final json = original.toJson();
      final restored = Category.fromJson(json);
      expect(restored.id, original.id);
      expect(restored.name, original.name);
      expect(restored.defaultSoundPath, original.defaultSoundPath);
      expect(restored.defaultAudioStartSeconds, 5);
      expect(restored.defaultAudioDurationSeconds, 25);
    });

    test('Reminder toJson/fromJson roundtrip preserves fields', () {
      const original = Reminder(
        hour: 8,
        minute: 30,
        type: 'Alarma',
        soundPath: '/a.mp3',
        audioStartSeconds: 10,
        audioDurationSeconds: 40,
        weekDays: [true, false, true, false, true, false, false],
      );
      final json = original.toJson();
      final restored = Reminder.fromJson(json);
      expect(restored.hour, original.hour);
      expect(restored.minute, original.minute);
      expect(restored.type, original.type);
      expect(restored.soundPath, original.soundPath);
      expect(restored.audioStartSeconds, original.audioStartSeconds);
      expect(restored.audioDurationSeconds, original.audioDurationSeconds);
      expect(restored.weekDays, original.weekDays);
    });

    test('HabitLog toJson/fromJson roundtrip preserves fields', () {
      final original = HabitLog(
        habitId: 'h1',
        date: DateTime(2026, 8, 26, 0, 0, 0, 0, 0),
        isCompleted: true,
        currentValue: 5,
        completedChecklist: ['A', 'B'],
      );
      final json = original.toJson();
      final restored = HabitLog.fromJson(json);
      expect(restored.habitId, original.habitId);
      expect(restored.date, original.date);
      expect(restored.isCompleted, original.isCompleted);
      expect(restored.currentValue, original.currentValue);
      expect(restored.completedChecklist, original.completedChecklist);
    });
  });

  group('HabitVisuals', () {
    test('effectiveImagePath falls back to category image', () {
      final repo = HabitsRepository();
      repo.addCategory(
        const Category(
          id: 'img-cat',
          name: 'Imagen',
          color: Colors.blue,
          imagePath: '/category.png',
        ),
      );
      final habit = Habit(
        id: 'h-img',
        title: 'Hábito con imagen de categoría',
        categoryId: 'img-cat',
      );
      expect(habit.effectiveImagePath, '/category.png');
    });

    test('effectiveImagePath prefers own habit image over category image', () {
      final repo = HabitsRepository();
      repo.addCategory(
        const Category(
          id: 'img-cat2',
          name: 'Imagen',
          color: Colors.blue,
          imagePath: '/category.png',
        ),
      );
      final habit = Habit(
        id: 'h-img2',
        title: 'Hábito con imagen propia',
        categoryId: 'img-cat2',
        imagePath: '/habit.png',
      );
      expect(habit.effectiveImagePath, '/habit.png');
    });

    test('effectiveIcon falls back to category icon', () {
      final repo = HabitsRepository();
      repo.addCategory(
        const Category(
          id: 'icon-cat',
          name: 'Iconos',
          color: Colors.orange,
          icon: Icons.star,
        ),
      );
      final habit = Habit(
        id: 'h-icon',
        title: 'Hábito con icono de categoría',
        categoryId: 'icon-cat',
      );
      expect(habit.effectiveIcon, Icons.star);
    });

    test('effectiveIcon prefers own habit icon over category icon', () {
      final repo = HabitsRepository();
      repo.addCategory(
        const Category(
          id: 'icon-cat2',
          name: 'Iconos',
          color: Colors.orange,
          icon: Icons.star,
        ),
      );
      final habit = Habit(
        id: 'h-icon2',
        title: 'Hábito con icono propio',
        categoryId: 'icon-cat2',
        icon: Icons.favorite,
      );
      expect(habit.effectiveIcon, Icons.favorite);
    });
  });
}
