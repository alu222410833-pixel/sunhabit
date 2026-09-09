import 'package:flutter_test/flutter_test.dart';
import 'package:sunhabit/features/habits/data/habit_model.dart';
import 'package:sunhabit/features/habits/data/habits_repository.dart';

import '../../../helpers/fake_storage_service.dart';

void main() {
  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
  });

  group('HabitsRepository.deleteCategory (eliminación segura)', () {
    late HabitsRepository repo;

    setUp(() async {
      final storage = FakeStorageService();
      repo = HabitsRepository.test(storage);
      await repo.initialize();
    });

    test(
        'devuelve notFound cuando la categoría no existe',
        () async {
      final result = await repo.deleteCategory('inexistente');
      expect(result, CategoryDeletionResult.notFound);
    });

    test(
        'bloquea la eliminación de la última categoría restante',
        () async {
      // Elimina todas menos una.
      final categories = repo.getCategories();
      for (final c in categories.skip(1)) {
        await repo.deleteCategory(c.id);
      }
      expect(repo.getCategories().length, 1);

      final result = await repo.deleteCategory(repo.getCategories().first.id);
      expect(result, CategoryDeletionResult.blockedLastCategory);
      expect(repo.getCategories().length, 1);
    });

    test(
        'reasigna los hábitos huérfanos a la primera categoría restante',
        () async {
      // Crea un hábito en la categoría 'health'.
      final healthId = 'health';
      final habit = Habit(
        id: 'h1',
        title: 'Beber agua',
        categoryId: healthId,
      );
      await repo.addHabit(habit);

      // Elimina 'health' (existen 'study' y 'work' como fallback).
      final result = await repo.deleteCategory(healthId);

      expect(result, CategoryDeletionResult.success);
      expect(repo.getCategoryById(healthId), isNull);

      final reassigned = repo.getHabitById('h1');
      expect(reassigned, isNotNull);
      expect(reassigned!.categoryId, isNot(healthId));
      // Debe ser una categoría que sigue existiendo.
      expect(repo.getCategoryById(reassigned.categoryId), isNotNull);
    });

    test(
        'reasigna los hábitos a la categoría indicada por fallbackCategoryId',
        () async {
      final habit = Habit(
        id: 'h1',
        title: 'Leer',
        categoryId: 'health',
      );
      await repo.addHabit(habit);

      final result = await repo.deleteCategory(
        'health',
        fallbackCategoryId: 'work',
      );

      expect(result, CategoryDeletionResult.success);
      final reassigned = repo.getHabitById('h1');
      expect(reassigned!.categoryId, 'work');
    });

    test(
        'ignora un fallbackCategoryId inexistente y usa la primera restante',
        () async {
      final habit = Habit(
        id: 'h1',
        title: 'Leer',
        categoryId: 'health',
      );
      await repo.addHabit(habit);

      final result = await repo.deleteCategory(
        'health',
        fallbackCategoryId: 'no-existe',
      );

      expect(result, CategoryDeletionResult.success);
      final reassigned = repo.getHabitById('h1');
      expect(reassigned!.categoryId, isNot('health'));
      expect(reassigned.categoryId, isNot('no-existe'));
    });

    test(
        'elimina una categoría sin hábitos asociados sin problema',
        () async {
      final result = await repo.deleteCategory('work');
      expect(result, CategoryDeletionResult.success);
      expect(repo.getCategoryById('work'), isNull);
    });

    test(
        'persiste la reasignación: un nuevo repositorio sobre el mismo '
        'storage ve los hábitos reasignados', () async {
      final storage = FakeStorageService();
      repo = HabitsRepository.test(storage);
      await repo.initialize();

      final habit = Habit(
        id: 'h1',
        title: 'Meditar',
        categoryId: 'health',
      );
      await repo.addHabit(habit);
      await repo.deleteCategory('health', fallbackCategoryId: 'study');

      final repo2 = HabitsRepository.test(storage);
      await repo2.initialize();

      final loaded = repo2.getHabitById('h1');
      expect(loaded, isNotNull);
      expect(loaded!.categoryId, 'study');
      expect(repo2.getCategoryById('health'), isNull);
    });
  });
}
