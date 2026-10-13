import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sunhabit/features/habits/data/habit_model.dart';
import 'package:sunhabit/features/habits/data/habits_repository.dart';
import 'package:sunhabit/features/habits/presentation/habit_completion_bottom_sheet/habit_completion_bottom_sheet.dart';

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
    await HabitsRepository().initialize();
  });

  testWidgets('HabitCompletionBottomSheet renders its content', (tester) async {
    final repo = HabitsRepository();
    await repo.addHabit(
      Habit(
        id: 'sheet_test',
        title: 'Hábito Sheet Test',
        categoryId: 'health',
        current: 0,
        target: 3,
        unit: 'L',
      ),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => Center(
              child: ElevatedButton(
                onPressed: () => showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  builder: (_) =>
                      const HabitCompletionBottomSheet(habitId: 'sheet_test'),
                ),
                child: const Text('open'),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    // El contenido del sheet debe ser visible: título del hábito.
    expect(find.text('Hábito Sheet Test'), findsWidgets);
    // Y el cuerpo de cantidad debe existir.
    expect(find.text('¿Por qué lo haces?'), findsOneWidget);
  });
}
