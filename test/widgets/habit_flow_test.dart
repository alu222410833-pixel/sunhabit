import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sunhabit/core/theme/app_theme.dart';
import 'package:sunhabit/features/habits/data/habit_model.dart';
import 'package:sunhabit/features/habits/data/habits_repository.dart';
import 'package:sunhabit/features/habits/presentation/edit_habit/widgets/edit_habit_text_field_tile.dart';
import 'package:sunhabit/features/habits/presentation/habit_detail_screen.dart';
import 'package:sunhabit/features/habits/presentation/habits_screen.dart';
import 'package:sunhabit/features/home/presentation/home_screen.dart';

/// Tests de integración (widget) que verifican el flujo completo de hábitos:
/// crear, completar, ver historial, editar y eliminar.
///
/// El [HabitsRepository] es un singleton respaldado por [SharedPreferences], por
/// lo que se inicializa una sola vez en [setUpAll]. Cada test utiliza hábitos
/// con identificadores y títulos únicos para no depender del orden de ejecución
/// ni del estado compartido.
void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
    await HabitsRepository().initialize();
  });

  /// Envuelve una pantalla en un [MaterialApp] mínimo para tests.
  Widget wrap(Widget child) => MaterialApp(theme: AppTheme.darkTheme, home: child);

  /// Avanza un paso del asistente de creación/edición pulsando "Siguiente".
  Future<void> nextStep(WidgetTester tester) async {
    await tester.tap(find.text('Siguiente'));
    await tester.pumpAndSettle();
  }

  /// Localiza el botón de completado (toggle) de la tarjeta cuyo título es
  /// [title]. El toggle es el `GestureDetector` con un `AnimatedContainer`
  /// como hijo que está en la misma fila (Row) que el título.
  Finder toggleFinderFor(String title) {
    final rowFinder = find
        .ancestor(of: find.text(title), matching: find.byType(Row))
        .first;
    return find.descendant(
      of: rowFinder,
      matching: find.byWidgetPredicate(
        (w) => w is GestureDetector && w.child is AnimatedContainer,
      ),
    );
  }

  group('HabitsScreen — renderizado', () {
    testWidgets('muestra los hábitos del repositorio y el progreso', (tester) async {
      await tester.pumpWidget(wrap(const HabitsScreen()));
      await tester.pumpAndSettle();

      // El primer hábito debe aparecer sin scroll.
      expect(find.text('Beber 2L de agua'), findsOneWidget);
      expect(find.text('MIS HÁBITOS'), findsOneWidget);
      expect(find.text('PROGRESO DE HOY'), findsOneWidget);

      // Los hábitos siguientes pueden estar fuera de pantalla (ListView lazy).
      await tester.scrollUntilVisible(
        find.text('Entrenamiento'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text('Entrenamiento'), findsOneWidget);
    });
  });

  group('HomeScreen — completar hábito', () {
    testWidgets('el círculo de check marca un hábito pendiente', (tester) async {
      const title = 'Hábito Home Toggle';
      final repo = HabitsRepository();
      repo.addHabit(
        Habit(id: 'home-toggle', title: title, categoryId: 'health'),
      );
      expect(repo.getHabitById('home-toggle')!.isCompleted, isFalse);

      await tester.pumpWidget(wrap(const HomeScreen()));
      await tester.pumpAndSettle();

      await tester.scrollUntilVisible(
        find.text(title),
        200,
        scrollable: find.byType(Scrollable).first,
      );

      final toggle = find.descendant(
        of: find
            .ancestor(of: find.text(title), matching: find.byType(Row))
            .first,
        matching: find.byWidgetPredicate(
          (w) => w is GestureDetector && w.child is AnimatedSwitcher,
        ),
      );
      await tester.tap(toggle);
      await tester.pumpAndSettle();

      expect(repo.getHabitById('home-toggle')!.isCompleted, isTrue);
    });
  });

  group('HabitsScreen — completar hábito', () {
    // La pantalla de hábitos ya no tiene toggle de completado en la tarjeta.
    // La acción de completar se realiza desde HomeScreen.
    testWidgets(
      'el toggle marca un hábito pendiente como completado',
      skip: true,
      (tester) async {
      const title = 'Hábito Test Toggle';
      final repo = HabitsRepository();
      repo.addHabit(
        Habit(id: 'toggle-test', title: title, categoryId: 'health'),
      );
      expect(repo.getHabitById('toggle-test')!.isCompleted, isFalse);

      await tester.pumpWidget(wrap(const HabitsScreen()));
      await tester.pumpAndSettle();

      // El hábito añadido está al final de la lista: hacer scroll hasta él.
      await tester.scrollUntilVisible(
        find.text(title),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      // Mover la tarjeta hacia la zona central para evitar que el FAB / la
      // barra inferior oscurezcan el toggle.
      await tester.drag(
        find.byType(Scrollable).first,
        const Offset(0, -180),
      );
      await tester.pumpAndSettle();

      // Antes de pulsar: el hábito no está completado.
      final toggle = toggleFinderFor(title);
      await tester.tap(toggle);
      await tester.pumpAndSettle();

      expect(repo.getHabitById('toggle-test')!.isCompleted, isTrue);
    });
  });

  group('HabitsScreen — crear hábito', () {
    testWidgets('el FAB abre el menú, el asistente crea un hábito nuevo', (tester) async {
      const newTitle = 'Hábito Creado Widget';
      final repo = HabitsRepository();
      final existed =
          repo.getHabits().any((h) => h.title == newTitle);
      expect(existed, isFalse);

      await tester.pumpWidget(wrap(const HabitsScreen()));
      await tester.pumpAndSettle();

      // Abrir el menú de creación desde el botón central del BottomAppBar.
      await tester.tap(find.byIcon(Icons.add_rounded));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Crear hábito'));
      await tester.pumpAndSettle();

      // El asistente debe estar visible (paso 0: categoría).
      expect(find.text('Selecciona la categoría'), findsOneWidget);

      // Paso 0 -> 1 (categoría por defecto seleccionada).
      await nextStep(tester);
      // Paso 1 -> 2 (tipo de evaluación: Sí/No por defecto).
      await nextStep(tester);
      // Paso 2: introducir el nombre del hábito.
      await tester.enterText(find.byType(TextField).at(0), newTitle);
      await nextStep(tester);
      // Paso 3 -> 4 (frecuencia por defecto).
      await nextStep(tester);
      // Paso 4: guardar.
      await tester.tap(find.text('Guardar'));
      await tester.pumpAndSettle();

      // El hábito debe haberse añadido al repositorio.
      final created = repo.getHabits().firstWhere(
        (h) => h.title == newTitle,
        orElse: () => Habit(id: '', title: '', categoryId: ''),
      );
      expect(created.id, isNotEmpty);
      expect(created.categoryId, 'health');

      // Y debe aparecer en la lista (puede requerir scroll).
      await tester.scrollUntilVisible(
        find.text(newTitle),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text(newTitle), findsOneWidget);
    });
  });

  group('HabitDetailScreen — historial', () {
    testWidgets('muestra el historial y el badge de completado', (tester) async {
      const id = 'history-test';
      const title = 'Hábito Historial';
      final repo = HabitsRepository();
      repo.addHabit(
        Habit(id: id, title: title, categoryId: 'health', points: 12),
      );
      // Completar genera un log para hoy.
      repo.completeHabit(id);
      expect(repo.getHabitLogs(id), isNotEmpty);

      await tester.pumpWidget(wrap(HabitDetailScreen(habitId: id)));
      await tester.pumpAndSettle();

      // El historial está en la pestaña "Estadísticas".
      await tester.tap(find.text('Estadísticas'));
      await tester.pumpAndSettle();

      expect(find.text(title), findsWidgets);
      expect(find.text('HISTORIAL'), findsOneWidget);
      expect(find.text('Completado'), findsWidgets);
      expect(find.text('HECHO HOY'), findsOneWidget);
      expect(find.text('12'), findsOneWidget);
    });

    testWidgets('muestra mensaje cuando no hay historial', (tester) async {
      const id = 'no-history-test';
      const title = 'Hábito Sin Historial';
      final repo = HabitsRepository();
      repo.addHabit(
        Habit(id: id, title: title, categoryId: 'health'),
      );
      expect(repo.getHabitLogs(id), isEmpty);

      await tester.pumpWidget(wrap(HabitDetailScreen(habitId: id)));
      await tester.pumpAndSettle();

      // El mensaje de historial vacío está en la pestaña "Estadísticas".
      await tester.tap(find.text('Estadísticas'));
      await tester.pumpAndSettle();

      expect(find.text('Aún no hay registros'), findsOneWidget);
      expect(find.text('Pendiente'), findsWidgets);
    });
  });

  group('HabitDetailScreen — editar', () {
    testWidgets('el asistente de edición actualiza el hábito', (tester) async {
      const id = 'edit-test';
      const originalTitle = 'Título Original Edición';
      const newTitle = 'Título Editado';
      final repo = HabitsRepository();
      repo.addHabit(
        Habit(id: id, title: originalTitle, categoryId: 'health'),
      );

      await tester.pumpWidget(wrap(HabitDetailScreen(habitId: id)));
      await tester.pumpAndSettle();

      // La edición ahora está en la pestaña "Editar" del TabBar.
      await tester.tap(find.byType(Tab).at(2));
      await tester.pumpAndSettle();

      // Verificar que el editor embebido se renderizó.
      expect(find.text('Nombre del hábito'), findsWidgets);

      // Cambiar el título en el campo de nombre.
      await tester.enterText(find.byType(TextField).at(0), newTitle);

      // Hacer scroll hasta el botón de guardar.
      await tester.fling(
        find.byType(EditHabitTextFieldTile).first,
        const Offset(0, -1000),
        2000,
      );
      await tester.pumpAndSettle();

      // Guardar cambios.
      await tester.tap(find.text('Guardar cambios'));
      await tester.pumpAndSettle();

      // El repositorio refleja el nuevo título.
      expect(repo.getHabitById(id)?.title, newTitle);
    });
  });

  group('HabitDetailScreen — eliminar', () {
    testWidgets('el diálogo de confirmación elimina el hábito y vuelve atrás', (tester) async {
      const id = 'delete-test';
      const title = 'Hábito Para Borrar';
      final repo = HabitsRepository();
      repo.addHabit(
        Habit(id: id, title: title, categoryId: 'health'),
      );
      expect(repo.getHabitById(id), isNotNull);

      await tester.pumpWidget(wrap(HabitDetailScreen(habitId: id)));
      await tester.pumpAndSettle();

      // Abrir eliminación desde el icono del AppBar.
      final deleteButton = find.descendant(
        of: find.byType(AppBar),
        matching: find.byIcon(Icons.delete_outline),
      );
      await tester.tap(deleteButton);
      await tester.pumpAndSettle();

      // Aparece el diálogo de confirmación.
      expect(find.text('Eliminar hábito'), findsOneWidget);
      expect(
        find.descendant(
          of: find.byType(AlertDialog),
          matching: find.text('Eliminar'),
        ),
        findsOneWidget,
      );

      // Confirmar la eliminación.
      await tester.tap(
        find.descendant(
          of: find.byType(AlertDialog),
          matching: find.text('Eliminar'),
        ),
      );
      await tester.pumpAndSettle();

      // El hábito ya no existe en el repositorio.
      expect(repo.getHabitById(id), isNull);
      expect(repo.getHabitLogs(id), isEmpty);
      // La pantalla de detalle se ha cerrado (Navigator.pop).
      expect(find.byType(HabitDetailScreen), findsNothing);
    });

    testWidgets('cancelar la eliminación mantiene el hábito', (tester) async {
      const id = 'delete-cancel-test';
      const title = 'Hábito No Borrado';
      final repo = HabitsRepository();
      repo.addHabit(
        Habit(id: id, title: title, categoryId: 'health'),
      );

      await tester.pumpWidget(wrap(HabitDetailScreen(habitId: id)));
      await tester.pumpAndSettle();

      final deleteButton = find.descendant(
        of: find.byType(AppBar),
        matching: find.byIcon(Icons.delete_outline),
      );
      await tester.tap(deleteButton);
      await tester.pumpAndSettle();

      await tester.tap(find.text('Cancelar'));
      await tester.pumpAndSettle();

      expect(repo.getHabitById(id), isNotNull);
      expect(find.byType(HabitDetailScreen), findsOneWidget);
    });
  });
}
