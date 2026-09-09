import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sunhabit/features/habits/presentation/create_habit/frequency/number_input.dart';

void main() {
  testWidgets('NumberInput displays the value and increments', (tester) async {
    int value = 1;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: StatefulBuilder(
            builder: (context, setState) {
              return NumberInput(
                value: value,
                onChanged: (v) => setState(() => value = v),
              );
            },
          ),
        ),
      ),
    );

    expect(find.text('1'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.add));
    await tester.pumpAndSettle();

    expect(find.text('2'), findsOneWidget);
    expect(value, 2);
  });

  testWidgets('NumberInput decrements and clamps to 1', (tester) async {
    int value = 1;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: StatefulBuilder(
            builder: (context, setState) {
              return NumberInput(
                value: value,
                onChanged: (v) => setState(() => value = v),
              );
            },
          ),
        ),
      ),
    );

    await tester.tap(find.byIcon(Icons.remove));
    await tester.pumpAndSettle();

    expect(find.text('1'), findsOneWidget);
    expect(value, 1);
  });
}
